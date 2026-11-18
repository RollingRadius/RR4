"""Store a trip's uploaded document in trip_documents (the bytes live in the database).

One row per (trip, doc_type, slot). A second upload of the same document replaces the row
in place: the old bytes are overwritten and one document_history entry records what was
replaced. The caller commits, so the row, the history entry and the trip's own column
change in one transaction.
"""

import uuid
from pathlib import Path

from sqlalchemy.orm import Session

from app.config import settings
from app.models.document import TripDocument
from app.services.upload_storage import StoredUpload, fill_document_row, remove_disk_copy, replacement_entry

# A trip keeps one loading slip, stored under one of these types and linked from these trip columns.
LOADING_SLIP_TYPES = ('loading_slip', 'rr_loading_slip')
LOADING_SLIP_COLUMNS = ('s2_loading_slip_url', 'rr_loading_slip_url')


def save_trip_document(db: Session, *, trip_id, doc_type: str, stage: int, url_path: str, file_name: str,
                       upload: StoredUpload, user, role_key: str, org_id, slot: int = 0,
                       uploaded_via: str = 'app', rr_file_id=None) -> TripDocument:
    trip_uuid = trip_id if isinstance(trip_id, uuid.UUID) else uuid.UUID(str(trip_id))
    row = db.query(TripDocument).filter(
        TripDocument.trip_id == trip_uuid,
        TripDocument.doc_type == doc_type,
        TripDocument.slot == slot,
    ).first()

    if row is None:
        row = TripDocument(id=uuid.uuid4(), trip_id=trip_uuid, doc_type=doc_type, slot=slot, stage=stage)
        db.add(row)
    else:
        db.add(replacement_entry(
            kind='trip', document_id=row.id, owner_ref=str(trip_uuid), doc_type=doc_type,
            old_sha256=row.sha256, old_size_bytes=row.size_bytes, old_uploaded_by=row.uploaded_by,
            old_uploader_username=row.uploader_username, old_uploaded_at=row.uploaded_at,
            replaced_by=user.id, replaced_by_username=user.username, replaced_by_role=role_key,
        ))

    fill_document_row(row, url_path=url_path, file_name=file_name, upload=upload, user=user, role_key=role_key,
                      org_id=org_id, uploaded_via=uploaded_via, rr_file_id=rr_file_id)
    return row


def save_loading_slip(db: Session, *, trip, doc_type: str, url_path: str, file_name: str, upload: StoredUpload,
                      user, role_key: str, org_id, uploaded_via: str = 'app', rr_file_id=None) -> TripDocument:
    """Store the trip's loading slip; the old one is not kept.

    Whoever uploads it (LP, RR-ops, FE or the transporter), both of the trip's slip links point at this
    newest slip, and every other stored slip of the trip is deleted.
    """
    row = save_trip_document(db, trip_id=trip.id, doc_type=doc_type, stage=2, url_path=url_path,
                             file_name=file_name, upload=upload, user=user, role_key=role_key, org_id=org_id,
                             uploaded_via=uploaded_via, rr_file_id=rr_file_id)
    for column in LOADING_SLIP_COLUMNS:
        setattr(trip, column, url_path)
    drop_unlinked_loading_slips(db, trip, user=user, role_key=role_key)
    return row


def drop_unlinked_loading_slips(db: Session, trip, *, user, role_key: str) -> None:
    """Delete every stored loading slip of the trip that none of its slip links points at, with a history entry."""
    linked = {getattr(trip, column) for column in LOADING_SLIP_COLUMNS}
    rows = db.query(TripDocument).filter(
        TripDocument.trip_id == trip.id, TripDocument.doc_type.in_(LOADING_SLIP_TYPES),
    ).all()
    for row in rows:
        if row.url_path in linked:
            continue
        db.add(replacement_entry(
            kind='trip', document_id=row.id, owner_ref=str(trip.id), doc_type=row.doc_type,
            old_sha256=row.sha256, old_size_bytes=row.size_bytes, old_uploaded_by=row.uploaded_by,
            old_uploader_username=row.uploader_username, old_uploaded_at=row.uploaded_at,
            replaced_by=user.id, replaced_by_username=user.username, replaced_by_role=role_key,
            reason='replaced_by_other_upload',
        ))
        db.delete(row)
        remove_disk_copy(Path(settings.UPLOAD_DIR) / "trips" / str(trip.id) / Path(row.url_path).name)


def save_trip_document_list(db: Session, *, trip_id, doc_type: str, stage: int, items: list,
                            user, role_key: str, org_id) -> list:
    """Replace a trip's whole list of documents of one type (for example Stage 3 material documents).

    `items` is [(url_path, file_name, StoredUpload), ...] in order; item i goes to slot i. Rows of an
    older, longer list beyond the new length are removed, each with a history entry.
    """
    trip_uuid = trip_id if isinstance(trip_id, uuid.UUID) else uuid.UUID(str(trip_id))
    rows = [
        save_trip_document(db, trip_id=trip_uuid, doc_type=doc_type, stage=stage, url_path=url,
                           file_name=name, upload=upload, user=user, role_key=role_key, org_id=org_id, slot=slot)
        for slot, (url, name, upload) in enumerate(items)
    ]
    stale = db.query(TripDocument).filter(
        TripDocument.trip_id == trip_uuid,
        TripDocument.doc_type == doc_type,
        TripDocument.slot >= len(items),
    ).all()
    for row in stale:
        db.add(replacement_entry(
            kind='trip', document_id=row.id, owner_ref=str(trip_uuid), doc_type=doc_type,
            old_sha256=row.sha256, old_size_bytes=row.size_bytes, old_uploaded_by=row.uploaded_by,
            old_uploader_username=row.uploader_username, old_uploaded_at=row.uploaded_at,
            replaced_by=user.id, replaced_by_username=user.username, replaced_by_role=role_key,
            reason='removed_from_list',
        ))
        db.delete(row)
    return rows
