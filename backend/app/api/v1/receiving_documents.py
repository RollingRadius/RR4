"""
Receiving Documents API

LP/RR-ops upload a photo of a physical receiving sheet and tag it with the
date it's for. Looking a document up is by that date, not by trip — see
app/models/receiving_document.py for the data model.
"""

import uuid as uuid_module
from datetime import date
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db, SessionLocal
from app.dependencies import get_current_user
from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.receiving_document import ReceivingDocument

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
    uploader = db.query(User).filter(User.id == doc.uploaded_by).first() if doc.uploaded_by else None
    return {
        "id": str(doc.id),
        "file_url": doc.file_url,
        "doc_date": doc.doc_date.isoformat() if doc.doc_date else None,
        "uploaded_by": uploader.full_name if uploader else None,
        "created_at": doc.created_at.isoformat() if doc.created_at else None,
    }


@router.post("", status_code=201)
async def upload_receiving_document(
    file: UploadFile = File(...),
    doc_date: date = Form(..., description="Date this receiving sheet is for"),
    current_user: User = Depends(get_current_user),
):
    """Upload one receiving-sheet image tagged with the date it's for."""
    # Phase 1 — validate on a short-lived session, closed before file I/O
    db = SessionLocal()
    try:
        user_org = _verify_owner_org(current_user, db)
        org_id = user_org.organization_id
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

    # Phase 3 — fresh session, insert document
    db = SessionLocal()
    try:
        doc = ReceivingDocument(
            file_url=file_url,
            doc_date=doc_date,
            organization_id=org_id,
            uploaded_by=current_user.id,
        )
        db.add(doc)
        db.commit()
        db.refresh(doc)
        return {"success": True, "document": _doc_to_dict(doc, db)}
    finally:
        db.close()


@router.get("")
def list_receiving_documents(
    skip: int = 0,
    limit: int = 50,
    doc_date: Optional[date] = Query(None, description="Only docs tagged with this date"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Backs the standalone Receiving Docs browsing screen — newest first,
    scoped to the caller's org. When doc_date is given, only docs uploaded
    for that day are returned."""
    user_org = _verify_owner_org(current_user, db)

    query = db.query(ReceivingDocument).filter(
        ReceivingDocument.organization_id == user_org.organization_id
    )
    if doc_date:
        query = query.filter(ReceivingDocument.doc_date == doc_date)

    query = query.order_by(ReceivingDocument.created_at.desc())

    total = query.count()
    docs = query.offset(skip).limit(limit).all()
    return {
        "total": total,
        "documents": [_doc_to_dict(d, db) for d in docs],
    }
