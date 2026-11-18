"""Stage 1 documents: each one is stored ONCE, on its owner, in the database.

A driver's licence and Aadhaar go to driver_documents, a vehicle's RC, insurance, PUC, fitness and
permit to vehicle_documents, and the vehicle owner's PAN, tax declaration and cancelled cheque to
owner_documents. The owner is found from the trip (see resolve_owner). A trip with no owner key keeps
the file as a trip-only document in trip_documents.

A second upload for the same owner, document and side replaces the row in place: the old bytes are
overwritten, one document_history entry records what was replaced, and every trip that still points
at the old URL is repointed to the new one in the same transaction (so older trips show the
current document, as in RR). The last upload wins; nothing is flagged when a document number differs.
The caller commits.
"""

import uuid
from pathlib import Path
from typing import Optional

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.config import settings
from app.core.document_map import DRIVER, OWNER, UPLOAD_COLUMNS, VEHICLE
from app.models.driver import Driver
from app.models.document import DriverDocument, OwnerDocument, VehicleDocument
from app.models.trip import Trip
from app.models.vehicle import Vehicle
from app.services.trip_document_service import save_trip_document
from app.services.upload_storage import StoredUpload, fill_document_row, remove_disk_copy, replacement_entry

UPLOAD_BY_COLUMN = {c.column: c for c in UPLOAD_COLUMNS}
STAGE_1_COLUMNS = [c.column for c in UPLOAD_COLUMNS if c.stage == 1]
DRIVER_COLUMNS = [c for c in UPLOAD_COLUMNS if c.stage == 1 and c.table == DRIVER]
# The sync's "already sent" key and the trip's cached RR file id for each licence/Aadhaar trip column.
DRIVER_SYNC_MARKS = {
    "s1_driving_license_url": ("Driving Licence::front", "rr_dl_file_id"),
    "s1_driving_license_back_url": ("Driving Licence::back", "rr_dl_back_file_id"),
    "s1_aadhaar_url": ("Aadhaar Card::front", "rr_aadhaar_file_id"),
    "s1_aadhaar_back_url": ("Aadhaar Card::back", "rr_aadhaar_back_file_id"),
}
MODELS = {DRIVER: DriverDocument, VEHICLE: VehicleDocument, OWNER: OwnerDocument}
HISTORY_KIND = {DRIVER: 'driver', VEHICLE: 'vehicle', OWNER: 'owner'}
OWNER_COLUMN = {
    "driver": "driver_id", "rr_driver": "rr_driver_id",
    "vehicle": "vehicle_id", "rr_vehicle": "rr_vehicle_id",
    "org": "organization_id", "rr_company": "rr_company_id",
}
# An RR id only identifies the owner of rows that have no local id (the partial unique indexes).
LOCAL_ID_COLUMN = {"rr_driver": "driver_id", "rr_vehicle": "vehicle_id", "rr_company": "organization_id"}
UUID_KINDS = {"driver", "vehicle", "org"}


def resolve_owner(db: Session, trip: Trip, table: str) -> Optional[tuple]:
    """(kind, id) of the owner of a Stage 1 document of this trip, or None.

    A driver or vehicle known locally wins over the RR id that points at it. Owner documents belong
    to the vehicle owner: the RR company on the trip, else the organization of the trip's vehicle
    (never the trip's own organization, which is the fleet running the trip).
    """
    if table == DRIVER:
        if trip.driver_id:
            # A local driver left on the trip from before a driver change (its RR id is another driver's) is ignored.
            local_rr = db.query(Driver.rr_user_id).filter(Driver.id == trip.driver_id).scalar()
            if not (trip.rr_driver_id and local_rr and local_rr != trip.rr_driver_id):
                return ("driver", str(trip.driver_id))
        if trip.rr_driver_id:
            local = db.query(Driver.id).filter(Driver.rr_user_id == trip.rr_driver_id).first()
            return ("driver", str(local[0])) if local else ("rr_driver", trip.rr_driver_id)
    elif table == VEHICLE:
        if trip.vehicle_id:
            return ("vehicle", str(trip.vehicle_id))
        if trip.rr_vehicle_id:
            local = db.query(Vehicle.id).filter(Vehicle.rr_vehicle_id == trip.rr_vehicle_id).first()
            return ("vehicle", str(local[0])) if local else ("rr_vehicle", trip.rr_vehicle_id)
    elif table == OWNER:
        if trip.transporter_rr_company_id:
            return ("rr_company", trip.transporter_rr_company_id)
        vehicle_id = trip.vehicle_id
        if not vehicle_id and trip.rr_vehicle_id:
            local = db.query(Vehicle.id).filter(Vehicle.rr_vehicle_id == trip.rr_vehicle_id).first()
            vehicle_id = local[0] if local else None
        org = db.query(Vehicle.organization_id).filter(Vehicle.id == vehicle_id).scalar() if vehicle_id else None
        if org:
            return ("org", str(org))
    return None


def _find_row(db: Session, table: str, owner: tuple, doc_type: str, side: str):
    model = MODELS[table]
    kind, value = owner
    query = db.query(model).filter(
        getattr(model, OWNER_COLUMN[kind]) == (uuid.UUID(value) if kind in UUID_KINDS else value),
        model.doc_type == doc_type,
        model.side == side,
    )
    if kind in LOCAL_ID_COLUMN:
        query = query.filter(getattr(model, LOCAL_ID_COLUMN[kind]).is_(None))
    return query.first()


def _normalized_number(trip: Trip, number_column: Optional[str]) -> str:
    return (getattr(trip, number_column) or "").strip().upper() if number_column else ""


def _expiry(trip: Trip, expiry_column: Optional[str]):
    return getattr(trip, expiry_column) if expiry_column else None


def save_stage1_document(db: Session, *, trip: Trip, column: str, url_path: str, file_name: str,
                         upload: StoredUpload, user, role_key: str, org_id,
                         uploaded_via: str = 'app', rr_file_id=None) -> None:
    """Store the file uploaded for one Stage 1 trip column (see UPLOAD_COLUMNS)."""
    col = UPLOAD_BY_COLUMN[column]
    owner = resolve_owner(db, trip, col.table)
    if owner is None:
        # No driver, vehicle or owner key on this trip: the file stays with the trip.
        save_trip_document(db, trip_id=trip.id, doc_type=f"{col.doc_type}_{col.side}", stage=1, url_path=url_path,
                           file_name=file_name, upload=upload, user=user, role_key=role_key, org_id=org_id)
        return

    row = _find_row(db, col.table, owner, col.doc_type, col.side)
    number = _normalized_number(trip, col.number_column)
    if row is not None and row.sha256 == upload.sha256:
        # The same file uploaded again: nothing changes (same link, no history, nothing to send to RR).
        setattr(trip, column, row.url_path)
        row.number = number or row.number
        row.expiry_date = _expiry(trip, col.expiry_column) or row.expiry_date
        remove_disk_copy(Path(settings.UPLOAD_DIR) / "trips" / str(trip.id) / Path(url_path).name)
        return
    if row is None:
        kind, value = owner
        row = MODELS[col.table](
            id=uuid.uuid4(), doc_type=col.doc_type, side=col.side,
            **{OWNER_COLUMN[kind]: uuid.UUID(value) if kind in UUID_KINDS else value},
        )
        db.add(row)
    else:
        db.add(replacement_entry(
            kind=HISTORY_KIND[col.table], document_id=row.id, owner_ref=":".join(owner),
            doc_type=f"{col.doc_type}_{col.side}", old_sha256=row.sha256, old_size_bytes=row.size_bytes,
            old_uploaded_by=row.uploaded_by, old_uploader_username=row.uploader_username,
            old_uploaded_at=row.uploaded_at, replaced_by=user.id, replaced_by_username=user.username,
            replaced_by_role=role_key,
        ))
        if row.url_path != url_path:
            # Every trip that shows the old file now shows the current one. updated_at is kept as it was.
            trip_column = getattr(Trip, column)
            db.execute(update(Trip).where(trip_column == row.url_path)
                       .values({column: url_path, "updated_at": Trip.updated_at})
                       .execution_options(synchronize_session=False))

    fill_document_row(row, url_path=url_path, file_name=file_name, upload=upload, user=user, role_key=role_key,
                      org_id=org_id, uploaded_via=uploaded_via, rr_file_id=rr_file_id)
    row.number = number or row.number
    if col.expiry_column:
        # A new file brings its own valid-till date; the old file's date is never kept on it.
        row.expiry_date = _expiry(trip, col.expiry_column)


def clear_driver_documents(trip: Trip) -> None:
    """Reassign (user, 2026-11-17): the OLD driver's licence and Aadhaar (front and back) and their numbers are
    taken off the trip, so the trip never shows the wrong driver's documents (F3). Nothing new is stored: the new
    driver's details come from RR web through the Stage 1 pre-fill and are saved when Stage 1 is submitted. Their
    "already sent" marks go too (the caller clears the cached RR file ids). The caller commits."""
    synced = dict(trip.rr_synced_doc_urls or {})
    for col in DRIVER_COLUMNS:
        setattr(trip, col.column, None)
        synced.pop(DRIVER_SYNC_MARKS[col.column][0], None)
    for number_column in {c.number_column for c in DRIVER_COLUMNS}:
        setattr(trip, number_column, None)
    trip.rr_synced_doc_urls = synced


OWNER_COLUMNS = [c for c in UPLOAD_COLUMNS if c.table == OWNER]
# trip column -> (this trip's "already sent" key, trip cache attribute of the RR file id or None)
OWNER_SYNC_MARKS = {
    "s1_pan": ("Owner PAN::front", "rr_pan_file_id"),
    "s1_tax_declaration": ("Owner Tax Declaration::front", "rr_tax_declaration_file_id"),
    "s1_cancelled_cheque": ("Owner Cheque::front", None),
}


def stored_owner_document(db: Session, trip: Trip, column: str):
    """The stored document of this trip's truck owner for one owner trip column (PAN, tax declaration,
    cancelled cheque), or None."""
    col = UPLOAD_BY_COLUMN[column]
    owner = resolve_owner(db, trip, OWNER)
    return _find_row(db, OWNER, owner, col.doc_type, col.side) if owner else None


def link_owner_documents(db: Session, trip: Trip) -> None:
    """The trip shows the truck owner's stored PAN, tax declaration and cheque (a document we do not hold is left as
    the trip has it), with the stored PAN number and valid-till date where the trip has none. A stored file RR
    already holds byte for byte (collected from RR, or sent before) is marked as sent, with its number / date, so
    this trip does not send it back. The caller commits."""
    synced = dict(trip.rr_synced_doc_urls or {})
    for col in OWNER_COLUMNS:
        row = stored_owner_document(db, trip, col.column)
        if row is None:
            continue
        setattr(trip, col.column, row.url_path)
        if col.number_column and row.number and not getattr(trip, col.number_column):
            setattr(trip, col.number_column, row.number)
        if col.expiry_column and row.expiry_date and not getattr(trip, col.expiry_column):
            setattr(trip, col.expiry_column, row.expiry_date)
        if row.rr_file_id and row.rr_synced_sha256 == row.sha256:
            key, cache_attr = OWNER_SYNC_MARKS[col.column]
            synced[key] = row.url_path
            base = key.split("::")[0]
            if col.number_column and row.number:
                synced[f"{base}::number"] = row.number
            if col.expiry_column and row.expiry_date:
                synced[f"{base}::expiry"] = f"{row.expiry_date.isoformat()}T00:00:00"
            if cache_attr:
                setattr(trip, cache_attr, row.rr_file_id)
    trip.rr_synced_doc_urls = synced


def refresh_stage1_numbers(db: Session, trip: Trip) -> None:
    """A corrected document number or valid-till date reaches the stored record even when no new file was uploaded."""
    for column in STAGE_1_COLUMNS:
        col = UPLOAD_BY_COLUMN[column]
        number = _normalized_number(trip, col.number_column)
        expiry = _expiry(trip, col.expiry_column)
        if not number and not expiry:
            continue
        owner = resolve_owner(db, trip, col.table)
        row = _find_row(db, col.table, owner, col.doc_type, col.side) if owner else None
        if row is None:
            continue
        if number and row.number != number:
            row.number = number
        if expiry and row.expiry_date != expiry:
            row.expiry_date = expiry
