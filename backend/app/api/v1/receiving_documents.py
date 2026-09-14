"""
Receiving Documents API

LP/RR-ops upload ONE image (a physical receiving sheet covering multiple
trips) and link it to every trip number it covers. Looking up any one of
those trips then surfaces the same shared document. See
app/models/receiving_document.py for the data model and its "one receiving
document per trip" constraint.
"""

import uuid as uuid_module
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.config import settings
from app.database import get_db, SessionLocal
from app.dependencies import get_current_user
from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.trip import Trip
from app.models.receiving_document import ReceivingDocument, ReceivingDocumentTrip

router = APIRouter(prefix="/receiving-documents", tags=["Receiving Documents"])

_ALLOWED_ROLES = ('logistic_partner', 'lp_rr_operations', 'super_admin')


def _verify_owner_org(current_user: User, db: Session) -> UserOrganization:
    """LP/RR-ops only, same pattern as organization_management.py's verify_owner."""
    user_org = db.query(UserOrganization).join(
        Role, UserOrganization.role_id == Role.id
    ).filter(
        UserOrganization.user_id == current_user.id,
        Role.role_key.in_(_ALLOWED_ROLES),
        UserOrganization.status == 'active'
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="LP / RR-ops only")
    return user_org


def _doc_to_dict(doc: ReceivingDocument, db: Session) -> dict:
    linked_trips = db.query(Trip).join(
        ReceivingDocumentTrip, Trip.id == ReceivingDocumentTrip.trip_id
    ).filter(ReceivingDocumentTrip.receiving_document_id == doc.id).all()
    uploader = db.query(User).filter(User.id == doc.uploaded_by).first() if doc.uploaded_by else None
    return {
        "id": str(doc.id),
        "file_url": doc.file_url,
        "uploaded_by": uploader.full_name if uploader else None,
        "created_at": doc.created_at.isoformat() if doc.created_at else None,
        # id included (not just trip_number) so the edit UI can call the
        # unlink endpoint, which needs a trip id, not its display number.
        "trips": [{"id": str(t.id), "trip_number": t.trip_number} for t in linked_trips],
    }


def _validate_linkable(ids: list[str], org_id, db: Session) -> list:
    """Shared by upload and the 'link more trips' edit endpoint: every id
    must be a real UUID, belong to the caller's org, and not already be
    linked to ANY receiving document (including the one being edited —
    callers that want to re-link an already-linked-to-THIS-doc trip should
    just leave it alone, not resubmit it). Returns the matching Trip rows.
    """
    if not ids:
        raise HTTPException(status_code=400, detail="At least one trip must be linked")

    try:
        trip_uuids = [uuid_module.UUID(i) for i in ids]
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid trip id in trip_ids")

    trips = db.query(Trip).filter(Trip.id.in_(trip_uuids)).all()
    found_ids = {str(t.id) for t in trips}
    missing = [i for i in ids if i not in found_ids]
    if missing:
        raise HTTPException(status_code=404, detail=f"Trip(s) not found: {', '.join(missing)}")

    foreign_org_trips = [t.trip_number for t in trips if str(t.organization_id) != str(org_id)]
    if foreign_org_trips:
        raise HTTPException(
            status_code=403,
            detail=f"Trip(s) not in your organization: {', '.join(foreign_org_trips)}"
        )

    already_linked = db.query(ReceivingDocumentTrip).filter(
        ReceivingDocumentTrip.trip_id.in_(trip_uuids)
    ).all()
    if already_linked:
        linked_trip_ids = {str(l.trip_id) for l in already_linked}
        linked_numbers = [t.trip_number for t in trips if str(t.id) in linked_trip_ids]
        raise HTTPException(
            status_code=400,
            detail=f"Trip(s) already have a receiving document linked: {', '.join(linked_numbers)}"
        )
    return trips


@router.post("", status_code=201)
async def upload_receiving_document(
    file: UploadFile = File(...),
    trip_ids: str = Form(..., description="Comma-separated trip UUIDs"),
    current_user: User = Depends(get_current_user),
):
    """Upload one receiving-sheet image and link it to every trip listed in
    trip_ids. Fails cleanly (400) if any listed trip already has a
    receiving document linked, or doesn't belong to the caller's org."""
    ids = [t.strip() for t in trip_ids.split(',') if t.strip()]

    # Phase 1 — validate on a short-lived session, closed before file I/O
    db = SessionLocal()
    try:
        user_org = _verify_owner_org(current_user, db)
        org_id = user_org.organization_id
        _validate_linkable(ids, org_id, db)
        trip_uuids = [uuid_module.UUID(i) for i in ids]
    finally:
        db.close()

    # Phase 2 — slow file I/O, no DB session held
    doc_dir = Path(settings.UPLOAD_DIR) / "receiving_documents"
    doc_dir.mkdir(parents=True, exist_ok=True)
    ext = (Path(file.filename).suffix or '.jpg') if file.filename else '.jpg'
    filename = f"{uuid_module.uuid4().hex}{ext}"
    content = await file.read()
    (doc_dir / filename).write_bytes(content)
    file_url = f"/uploads/receiving_documents/{filename}"

    # Phase 3 — fresh session, insert document + links
    db = SessionLocal()
    try:
        doc = ReceivingDocument(
            file_url=file_url,
            organization_id=org_id,
            uploaded_by=current_user.id,
        )
        db.add(doc)
        db.flush()

        for trip_uuid in trip_uuids:
            db.add(ReceivingDocumentTrip(receiving_document_id=doc.id, trip_id=trip_uuid))

        db.commit()
        db.refresh(doc)
        return {"success": True, "document": _doc_to_dict(doc, db)}
    except IntegrityError:
        db.rollback()
        # Race: another upload linked one of these trips between phase 1's
        # check and this commit — rare, but the unique constraint is the
        # real guarantee, this is just a clean error instead of a 500.
        raise HTTPException(
            status_code=409,
            detail="One of these trips was just linked to another receiving document. Please retry."
        )
    finally:
        db.close()


class LinkTripsRequest(BaseModel):
    trip_ids: list[str]


def _get_owned_document(document_id: str, user_org: UserOrganization, db: Session) -> ReceivingDocument:
    try:
        doc_uuid = uuid_module.UUID(document_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Receiving document not found")
    doc = db.query(ReceivingDocument).filter(ReceivingDocument.id == doc_uuid).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Receiving document not found")
    if str(doc.organization_id) != str(user_org.organization_id):
        raise HTTPException(status_code=403, detail="Access denied to document from different organization")
    return doc


@router.post("/{document_id}/trips")
def link_more_trips(
    document_id: str,
    body: LinkTripsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Edit: link additional trips to an already-uploaded document."""
    user_org = _verify_owner_org(current_user, db)
    doc = _get_owned_document(document_id, user_org, db)

    ids = [t.strip() for t in body.trip_ids if t.strip()]
    _validate_linkable(ids, user_org.organization_id, db)

    try:
        for i in ids:
            db.add(ReceivingDocumentTrip(receiving_document_id=doc.id, trip_id=uuid_module.UUID(i)))
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="One of these trips was just linked to another receiving document. Please retry."
        )

    db.refresh(doc)
    return {"success": True, "document": _doc_to_dict(doc, db)}


@router.delete("/{document_id}/trips/{trip_id}")
def unlink_trip(
    document_id: str,
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Edit: unlink one trip from a document — the document and its file
    are kept even if this empties out its last linked trip, so it can be
    re-linked to new trips later rather than being silently lost."""
    user_org = _verify_owner_org(current_user, db)
    doc = _get_owned_document(document_id, user_org, db)

    try:
        trip_uuid = uuid_module.UUID(trip_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="This trip isn't linked to this document")

    link = db.query(ReceivingDocumentTrip).filter(
        ReceivingDocumentTrip.receiving_document_id == doc.id,
        ReceivingDocumentTrip.trip_id == trip_uuid,
    ).first()
    if not link:
        raise HTTPException(status_code=404, detail="This trip isn't linked to this document")

    db.delete(link)
    db.commit()
    db.refresh(doc)
    return {"success": True, "document": _doc_to_dict(doc, db)}


@router.get("/by-trip/{trip_id}")
def get_receiving_document_for_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Backs the trip card's badge + 'View Receiving Document' action."""
    user_org = _verify_owner_org(current_user, db)

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if str(trip.organization_id) != str(user_org.organization_id):
        raise HTTPException(status_code=403, detail="Access denied to trip from different organization")

    link = db.query(ReceivingDocumentTrip).filter(ReceivingDocumentTrip.trip_id == trip_id).first()
    if not link:
        return {"linked": False}

    doc = db.query(ReceivingDocument).filter(ReceivingDocument.id == link.receiving_document_id).first()
    if not doc:
        return {"linked": False}

    return {"linked": True, **_doc_to_dict(doc, db)}


@router.get("")
def list_receiving_documents(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Backs the standalone Receiving Docs browsing screen — newest first,
    scoped to the caller's org."""
    user_org = _verify_owner_org(current_user, db)

    query = db.query(ReceivingDocument).filter(
        ReceivingDocument.organization_id == user_org.organization_id
    ).order_by(ReceivingDocument.created_at.desc())

    total = query.count()
    docs = query.offset(skip).limit(limit).all()
    return {
        "total": total,
        "documents": [_doc_to_dict(d, db) for d in docs],
    }
