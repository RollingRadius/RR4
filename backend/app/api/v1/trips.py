"""
Trips API
Endpoints for managing trips — accessible by both fleet_manager and load_owner roles.
"""

import random
import string
from typing import Optional, List, Union
from datetime import date

import json
import uuid as _uuid_module
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, UserOrganization
from app.models.trip import Trip
from app.models.role import Role

router = APIRouter()


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _get_user_org(current_user: User, db: Session) -> UserOrganization:
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()
    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User must be in an active organization"
        )
    return user_org


def _get_role_key(user_org: UserOrganization, db: Session) -> str:
    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    return role.role_key if role else ''


def _generate_trip_number(db: Session) -> str:
    """Generate a unique RR-XXXXX trip number."""
    for _ in range(10):
        suffix = ''.join(random.choices(string.digits, k=5))
        trip_number = f"RR-{suffix}"
        if not db.query(Trip).filter(Trip.trip_number == trip_number).first():
            return trip_number
    raise HTTPException(status_code=500, detail="Could not generate unique trip number")


# ─── Schemas ─────────────────────────────────────────────────────────────────

class TripCreate(BaseModel):
    bilty_number: Optional[str] = None
    origin: str
    origin_sub: Optional[str] = None
    destination: str
    destination_sub: Optional[str] = None
    load_item: str
    weight: Optional[str] = None
    trip_amount: Optional[float] = None
    invoice_number: Optional[str] = None
    vehicle_id: Optional[str] = None
    driver_id: Optional[str] = None
    load_owner_org_id: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class TripUpdate(BaseModel):
    bilty_number: Optional[str] = None
    origin: Optional[str] = None
    origin_sub: Optional[str] = None
    destination: Optional[str] = None
    destination_sub: Optional[str] = None
    load_item: Optional[str] = None
    weight: Optional[str] = None
    trip_amount: Optional[float] = None
    invoice_number: Optional[str] = None
    vehicle_id: Optional[str] = None
    driver_id: Optional[str] = None
    status: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/trips")
def list_trips(
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List trips visible to the current user.
    - fleet_manager: sees all trips for their organisation
    - load_owner:  sees trips where load_owner_org_id == their org
    """
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    query = db.query(Trip)

    if role_key in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        query = query.filter(Trip.organization_id == user_org.organization_id)
    elif role_key == 'load_owner':
        query = query.filter(Trip.load_owner_org_id == user_org.organization_id)
    else:
        query = query.filter(Trip.organization_id == user_org.organization_id)

    if status_filter:
        statuses = [s.strip() for s in status_filter.split(',') if s.strip()]
        if len(statuses) == 1:
            query = query.filter(Trip.status == statuses[0])
        elif len(statuses) > 1:
            query = query.filter(Trip.status.in_(statuses))

    total = query.count()
    trips = query.order_by(Trip.created_at.desc()).offset(offset).limit(limit).all()

    return {
        "total": total,
        "trips": _enrich_bulk(trips, db),
    }


@router.get("/trips/{trip_id}")
def get_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a single trip by ID (both roles)."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # Access check
    if role_key in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        if str(trip.organization_id) != str(user_org.organization_id):
            raise HTTPException(status_code=403, detail="Access denied")
    elif role_key == 'load_owner':
        if str(trip.load_owner_org_id) != str(user_org.organization_id):
            raise HTTPException(status_code=403, detail="Access denied")
    else:
        if str(trip.organization_id) != str(user_org.organization_id):
            raise HTTPException(status_code=403, detail="Access denied")

    return _enrich(trip, db)


@router.post("/trips", status_code=201)
def create_trip(
    body: TripCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a trip. Only fleet_manager / super_admin can create trips."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    if role_key not in ('logistic_partner', 'super_admin'):
        raise HTTPException(
            status_code=403,
            detail="Only fleet managers can create trips"
        )

    trip = Trip(
        trip_number=_generate_trip_number(db),
        bilty_number=body.bilty_number,
        origin=body.origin,
        origin_sub=body.origin_sub,
        destination=body.destination,
        destination_sub=body.destination_sub,
        load_item=body.load_item,
        weight=body.weight,
        trip_amount=body.trip_amount,
        invoice_number=body.invoice_number,
        status='ongoing',
        organization_id=user_org.organization_id,
        load_owner_org_id=body.load_owner_org_id,
        vehicle_id=body.vehicle_id,
        driver_id=body.driver_id,
        created_by=current_user.id,
        start_date=body.start_date,
        end_date=body.end_date,
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return _enrich(trip, db)


@router.patch("/trips/{trip_id}")
def update_trip(
    trip_id: str,
    body: TripUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a trip. Only fleet_manager / super_admin can update trips."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    if role_key not in ('logistic_partner', 'super_admin'):
        raise HTTPException(status_code=403, detail="Only fleet managers can update trips")

    trip = db.query(Trip).filter(
        Trip.id == trip_id,
        Trip.organization_id == user_org.organization_id
    ).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(trip, field, value)

    db.commit()
    db.refresh(trip)
    return _enrich(trip, db)


@router.get("/trips/{trip_id}/vehicle-location")
def get_trip_vehicle_location(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get the current GPS location of the vehicle assigned to this trip.
    Both fleet_manager and load_owner can call this to locate the trip on a map.
    """
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # Access check
    org_id_str = str(user_org.organization_id)
    if role_key == 'load_owner':
        if str(trip.load_owner_org_id) != org_id_str:
            raise HTTPException(status_code=403, detail="Access denied")
    else:
        if str(trip.organization_id) != org_id_str:
            raise HTTPException(status_code=403, detail="Access denied")

    if not trip.vehicle_id:
        raise HTTPException(status_code=404, detail="No vehicle assigned to this trip")

    # Pull latest location from driver_locations table via the vehicle's current driver
    from app.models.vehicle import Vehicle
    vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    # Try to get latest GPS location for the driver assigned to the trip
    driver_id = str(trip.driver_id) if trip.driver_id else None
    if driver_id:
        try:
            from app.models.driver_location import DriverLocation
            loc = db.query(DriverLocation).filter(
                DriverLocation.driver_id == trip.driver_id
            ).order_by(DriverLocation.timestamp.desc()).first()

            if loc:
                return {
                    "trip_id": trip_id,
                    "trip_number": trip.trip_number,
                    "vehicle_id": str(trip.vehicle_id),
                    "driver_id": driver_id,
                    "latitude": float(loc.latitude),
                    "longitude": float(loc.longitude),
                    "speed": float(loc.speed) if loc.speed else None,
                    "heading": float(loc.heading) if loc.heading else None,
                    "timestamp": loc.timestamp.isoformat() if loc.timestamp else None,
                    "has_location": True,
                }
        except Exception:
            pass

    # No location data available yet
    return {
        "trip_id": trip_id,
        "trip_number": trip.trip_number,
        "vehicle_id": str(trip.vehicle_id),
        "driver_id": driver_id,
        "has_location": False,
        "message": "No GPS location available yet for this trip",
    }


# ─── Stage Schemas ────────────────────────────────────────────────────────────

# Stage1Payload replaced by Form + File params in the endpoint below.


class Stage2Payload(BaseModel):
    specs_verified:    bool
    docs_verified:     bool
    driver_docs_valid: bool
    entry_permission:  bool


# Stage3Payload is replaced by Form fields + UploadFile in the endpoint below.
# Helper to coerce form string → bool
def _form_bool(v: str) -> bool:
    return v.lower() in ('true', '1', 'yes')


# ─── Stage Endpoints ──────────────────────────────────────────────────────────

def _get_fleet_trip(trip_id: str, user_org, db: Session) -> Trip:
    """Fetch a trip that belongs to the current fleet org. Raises 404/403."""
    from datetime import datetime
    import uuid as _uuid
    try:
        uid = _uuid.UUID(trip_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid trip ID")
    trip = db.query(Trip).filter(Trip.id == uid).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if str(trip.organization_id) != str(user_org.organization_id):
        raise HTTPException(status_code=403, detail="Access denied")
    return trip


@router.post("/trips/{trip_id}/stage/1", status_code=200)
async def submit_stage1(
    trip_id: str,
    # Required text fields
    driver_name:          str           = Form(...),
    driver_phone:         str           = Form(...),
    driving_license:      str           = Form(...),
    aadhaar:              str           = Form(...),
    # Optional document uploads
    driving_license_doc:  Optional[UploadFile] = File(None),
    aadhaar_doc:          Optional[UploadFile] = File(None),
    rc_doc:               Optional[UploadFile] = File(None),
    insurance_doc:        Optional[UploadFile] = File(None),
    pollution_doc:        Optional[UploadFile] = File(None),
    fitness_doc:          Optional[UploadFile] = File(None),
    pan_doc:              Optional[UploadFile] = File(None),
    tax_declaration_doc:  Optional[UploadFile] = File(None),
    cancelled_cheque_doc: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 1 — Truck Detail Registration. Accepts multipart/form-data."""
    from datetime import datetime, timezone
    from app.config import settings

    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)

    # Stage lock: first worker to submit owns this stage; owners can always re-edit
    if trip.s1_submitted_by is not None and role_key == 'logistic_partner_worker':
        if str(trip.s1_submitted_by) != str(current_user.id):
            raise HTTPException(status_code=409, detail="Stage 1 has already been completed by another worker.")

    # Helper: save an uploaded file and return its URL path.
    # Returns None (leave existing) if no new file was uploaded.
    async def _save_doc(upload: Optional[UploadFile], prefix: str) -> Optional[str]:
        if upload is None or not upload.filename:
            return None
        ext = Path(upload.filename).suffix or '.jpg'
        trip_dir = Path(settings.UPLOAD_DIR) / "trips" / trip_id
        trip_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{prefix}_{_uuid_module.uuid4().hex}{ext}"
        with open(trip_dir / filename, "wb") as f:
            f.write(await upload.read())
        return f"/uploads/trips/{trip_id}/{filename}"

    trip.s1_driver_name     = driver_name
    trip.s1_driver_phone    = driver_phone
    trip.s1_driving_license = driving_license
    trip.s1_aadhaar         = aadhaar

    # For file fields: only overwrite if a new file was uploaded, otherwise keep existing URL
    new_dl      = await _save_doc(driving_license_doc,  "dl")
    new_aadhaar = await _save_doc(aadhaar_doc,          "aadhaar")
    new_rc      = await _save_doc(rc_doc,               "rc")
    new_ins     = await _save_doc(insurance_doc,        "insurance")
    new_pol     = await _save_doc(pollution_doc,        "pollution")
    new_fit     = await _save_doc(fitness_doc,          "fitness")
    new_pan     = await _save_doc(pan_doc,              "pan")
    new_tax     = await _save_doc(tax_declaration_doc,  "tax_decl")
    new_chq     = await _save_doc(cancelled_cheque_doc, "cheque")

    if new_dl      is not None: trip.s1_driving_license_url = new_dl
    if new_aadhaar is not None: trip.s1_aadhaar_url         = new_aadhaar
    if new_rc      is not None: trip.s1_rc                  = new_rc
    if new_ins     is not None: trip.s1_insurance           = new_ins
    if new_pol     is not None: trip.s1_pollution           = new_pol
    if new_fit     is not None: trip.s1_fitness             = new_fit
    if new_pan     is not None: trip.s1_pan                 = new_pan
    if new_tax     is not None: trip.s1_tax_declaration     = new_tax
    if new_chq     is not None: trip.s1_cancelled_cheque    = new_chq

    was_already_submitted = trip.current_stage >= 1
    trip.s1_submitted_by = current_user.id
    trip.s1_claimed_by   = None  # release claim on submit
    trip.s1_claimed_at   = None
    trip.s1_submitted_at = datetime.now(timezone.utc)
    # Advance to stage 1 if not already past it; never regress
    if trip.current_stage < 1:
        trip.current_stage = 1
    trip.draft_data = None  # clear draft on submit

    db.commit()
    db.refresh(trip)
    msg = "Stage 1 updated." if was_already_submitted else "Stage 1 saved. Proceed to compliance check."
    return {"success": True, "message": msg, "trip": _enrich(trip, db)}


@router.post("/trips/{trip_id}/stage/2", status_code=200)
def submit_stage2(
    trip_id: str,
    body: Stage2Payload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 2 — Pre-Arrival Compliance Check."""
    from datetime import datetime, timezone
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 1:
        raise HTTPException(status_code=409, detail="Complete Stage 1 first")

    # Stage lock: first worker to submit owns this stage; owners can always re-edit
    if trip.s2_submitted_by is not None and role_key == 'logistic_partner_worker':
        if str(trip.s2_submitted_by) != str(current_user.id):
            raise HTTPException(status_code=409, detail="Stage 2 has already been completed by another worker.")

    was_already_submitted = trip.current_stage >= 2
    if not body.entry_permission:
        raise HTTPException(
            status_code=400,
            detail="Entry permission must be issued to proceed"
        )

    trip.s2_specs_verified    = body.specs_verified
    trip.s2_docs_verified     = body.docs_verified
    trip.s2_driver_docs_valid = body.driver_docs_valid
    trip.s2_entry_permission  = body.entry_permission
    trip.s2_submitted_by      = current_user.id
    trip.s2_claimed_by        = None  # release claim on submit
    trip.s2_claimed_at        = None
    trip.s2_verified_at       = datetime.now(timezone.utc)
    if trip.current_stage < 2:
        trip.current_stage = 2

    db.commit()
    db.refresh(trip)
    msg = "Stage 2 updated." if was_already_submitted else "Entry permission issued. Coordinate truck arrival."
    return {"success": True, "message": msg, "trip": _enrich(trip, db)}


@router.post("/trips/{trip_id}/loading-slip", status_code=200)
async def upload_loading_slip(
    trip_id: str,
    slip: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload loading slip after Stage 2 compliance check, before Stage 3."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 2:
        raise HTTPException(status_code=409, detail="Complete Stage 2 first")

    upload_dir = Path(f"uploads/trips/{trip_id}")
    upload_dir.mkdir(parents=True, exist_ok=True)
    ext = Path(slip.filename).suffix if slip.filename else '.jpg'
    filename = f"loading_slip_{_uuid_module.uuid4().hex}{ext}"
    file_path = upload_dir / filename
    content = await slip.read()
    file_path.write_bytes(content)

    trip.s2_loading_slip_url = f"/uploads/trips/{trip_id}/{filename}"
    trip.draft_data = None   # clear loading slip draft on successful upload
    db.commit()
    db.refresh(trip)
    return {"success": True, "message": "Loading slip uploaded.", "trip": _enrich(trip, db)}


@router.post("/trips/{trip_id}/stage/3", status_code=200)
async def submit_stage3(
    trip_id: str,
    driver_parked:           str = Form(...),
    docs_submitted:          str = Form(...),
    security_verified:       str = Form(...),
    driver_exited_cabin:     str = Form(...),
    wheel_stoppers:          str = Form(...),
    safety_gear:             str = Form(...),
    empty_truck_weight_kg:   Optional[str] = Form(None),
    empty_truck_weight_unit: Optional[str] = Form('tons'),
    loaded_truck_weight_kg:  Optional[str] = Form(None),
    loaded_truck_weight_unit: Optional[str] = Form('tons'),
    bilty:                   Optional[UploadFile] = File(None),
    material_docs:           Optional[List[UploadFile]] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 3 — Truck Arrival at Factory. Completes the trip intake.
    Accepts multipart/form-data so bilty and material documents can be uploaded."""
    from datetime import datetime, timezone
    from app.config import settings

    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 2:
        raise HTTPException(status_code=409, detail="Complete Stage 2 first")

    # Stage lock: first worker to submit owns this stage; owners can always re-edit
    if trip.s3_submitted_by is not None and role_key == 'logistic_partner_worker':
        if str(trip.s3_submitted_by) != str(current_user.id):
            raise HTTPException(status_code=409, detail="Stage 3 has already been completed by another worker.")

    was_already_submitted = trip.current_stage >= 3

    # Save bilty file
    bilty_url = None
    if bilty and bilty.filename:
        ext = Path(bilty.filename).suffix or '.jpg'
        trip_dir = Path(settings.UPLOAD_DIR) / "trips" / trip_id
        trip_dir.mkdir(parents=True, exist_ok=True)
        filename = f"bilty_{_uuid_module.uuid4().hex}{ext}"
        with open(trip_dir / filename, "wb") as f:
            f.write(await bilty.read())
        bilty_url = f"/uploads/trips/{trip_id}/{filename}"

    # Save material doc files
    material_urls = []
    if material_docs:
        trip_dir = Path(settings.UPLOAD_DIR) / "trips" / trip_id
        trip_dir.mkdir(parents=True, exist_ok=True)
        for doc in material_docs:
            if doc and doc.filename:
                ext = Path(doc.filename).suffix or '.jpg'
                filename = f"material_{_uuid_module.uuid4().hex}{ext}"
                with open(trip_dir / filename, "wb") as f:
                    f.write(await doc.read())
                material_urls.append(f"/uploads/trips/{trip_id}/{filename}")

    trip.s3_driver_parked            = _form_bool(driver_parked)
    trip.s3_docs_submitted           = _form_bool(docs_submitted)
    trip.s3_security_verified        = _form_bool(security_verified)
    trip.s3_driver_exited_cabin      = _form_bool(driver_exited_cabin)
    trip.s3_wheel_stoppers           = _form_bool(wheel_stoppers)
    trip.s3_safety_gear              = _form_bool(safety_gear)
    trip.s3_empty_truck_weight_kg    = empty_truck_weight_kg
    trip.s3_empty_truck_weight_unit  = empty_truck_weight_unit or 'tons'
    trip.s3_loaded_truck_weight_kg   = loaded_truck_weight_kg
    trip.s3_loaded_truck_weight_unit = loaded_truck_weight_unit or 'tons'
    if bilty_url:
        trip.s3_bilty_url = bilty_url
    if material_urls:
        trip.s3_material_doc_urls = json.dumps(material_urls)
    trip.s3_submitted_by             = current_user.id
    trip.s3_claimed_by               = None  # release claim on submit
    trip.s3_claimed_at               = None
    trip.s3_completed_at             = datetime.now(timezone.utc)
    if trip.current_stage < 3:
        trip.current_stage = 3
    trip.status                      = 'ongoing'
    trip.draft_data                  = None  # clear draft on submit

    db.commit()
    db.refresh(trip)
    msg = "Stage 3 updated." if was_already_submitted else "Truck intake complete. Trip is now active."
    return {"success": True, "message": msg, "trip": _enrich(trip, db)}


class Stage4Payload(BaseModel):
    truck_moved:       bool
    security_verified: bool
    bilty_checked:     bool
    weight_checked:    bool
    material_checked:  bool


@router.post("/trips/{trip_id}/stage/4", status_code=200)
def submit_stage4(
    trip_id: str,
    body: Stage4Payload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 4 — Truck Exit From Factory. Records exit checklist; advances currentStage to 4."""
    from datetime import datetime, timezone

    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 3:
        raise HTTPException(status_code=409, detail="Complete Stage 3 first")

    # Stage lock: first worker to submit owns this stage; owners can always re-edit
    if trip.s4_submitted_by is not None and role_key == 'logistic_partner_worker':
        if str(trip.s4_submitted_by) != str(current_user.id):
            raise HTTPException(status_code=409, detail="Stage 4 has already been completed by another worker.")

    was_already_submitted = trip.current_stage >= 4

    trip.s4_truck_moved       = body.truck_moved
    trip.s4_security_verified = body.security_verified
    trip.s4_bilty_checked     = body.bilty_checked
    trip.s4_weight_checked    = body.weight_checked
    trip.s4_material_checked  = body.material_checked
    trip.s4_submitted_by      = current_user.id
    trip.s4_claimed_by        = None  # release claim on submit
    trip.s4_claimed_at        = None
    trip.s4_completed_at      = datetime.now(timezone.utc)
    if trip.current_stage < 4:
        trip.current_stage = 4
    trip.draft_data           = None  # clear draft on submit

    db.commit()
    db.refresh(trip)
    msg = "Stage 4 updated." if was_already_submitted else "Truck exit recorded. You can now notify the load owner."
    return {"success": True, "message": msg, "trip": _enrich(trip, db)}


class DraftPayload(BaseModel):
    stage: Union[int, str]   # int for stages 1-3, 'loading_slip' for the mini-stage
    data: dict
    saved_at: Optional[str] = None


@router.patch("/trips/{trip_id}/draft", status_code=200)
def save_draft(
    trip_id: str,
    body: DraftPayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Save partial stage form data as a draft. Does not advance the stage."""
    from datetime import datetime, timezone

    user_org = _get_user_org(current_user, db)
    trip = _get_fleet_trip(trip_id, user_org, db)

    trip.draft_data = {
        "stage": body.stage,
        "data": body.data,
        "saved_at": body.saved_at or datetime.now(timezone.utc).isoformat(),
    }
    db.commit()
    return {"success": True}


@router.post("/trips/{trip_id}/claim-stage/{stage}", status_code=200)
def claim_stage(
    trip_id: str,
    stage: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Claim system disabled — any worker can access any stage freely."""
    return {"success": True}


@router.delete("/trips/{trip_id}/claim-stage/{stage}", status_code=200)
def release_stage_claim(
    trip_id: str,
    stage: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Claim system disabled — no-op."""
    return {"success": True}


@router.post("/trips/{trip_id}/notify-stage4", status_code=200)
async def notify_stage4(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Send a real-time notification + persist it for the load owner org."""
    import uuid as _uuid_mod
    from datetime import datetime, timezone

    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 4:
        raise HTTPException(status_code=409, detail="Complete Stage 4 first before notifying")

    if not trip.load_owner_org_id:
        raise HTTPException(status_code=400, detail="No load owner organisation linked to this trip")

    recipient_org_id = str(trip.load_owner_org_id)
    title = "Truck has exited the factory"
    body  = (
        f"Your shipment {trip.trip_number} ({trip.origin} → {trip.destination}) "
        "truck has completed factory exit. All documents were verified."
    )

    # Persist notification
    from app.models.notification import Notification
    notif = Notification(
        recipient_org_id=trip.load_owner_org_id,
        trip_id=trip.id,
        type="stage4_exit",
        title=title,
        body=body,
    )
    db.add(notif)

    trip.s4_notified_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(notif)

    # Push real-time message over WebSocket (best-effort)
    from app.services.ws_manager import manager
    message = {
        "type":        "stage4_exit",
        "id":          str(notif.id),
        "trip_id":     str(trip.id),
        "trip_number": trip.trip_number,
        "origin":      trip.origin,
        "destination": trip.destination,
        "title":       title,
        "body":        body,
        "is_read":     False,
        "created_at":  notif.created_at.isoformat() if notif.created_at else None,
    }
    await manager.send_to_org(recipient_org_id, message)

    connected = manager.connected_count(recipient_org_id)
    return {
        "success": True,
        "message": "Notification sent.",
        "realtime_clients": connected,
        "notification": notif.to_dict(),
    }


@router.post("/trips/{trip_id}/notify-lp", status_code=200)
async def notify_lp(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Notify the LP company's own workers/owner that Stage 4 is complete."""
    import uuid as _uuid_mod
    from datetime import datetime, timezone

    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin', 'logistic_partner_worker'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 4:
        raise HTTPException(status_code=409, detail="Complete Stage 4 first before notifying")

    recipient_org_id = str(trip.organization_id)
    title = "Trip Stage 4 Complete"
    body = (
        f"Trip {trip.trip_number} ({trip.origin} → {trip.destination}) "
        "has completed all factory exit procedures. The truck is now on its way."
    )

    from app.models.notification import Notification
    notif = Notification(
        recipient_org_id=trip.organization_id,
        recipient_role='logistic_partner',   # only LP owner sees this, not LP workers
        trip_id=trip.id,
        type="trip_complete",
        title=title,
        body=body,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    from app.services.ws_manager import manager
    message = {
        "type":        "trip_complete",
        "id":          str(notif.id),
        "trip_id":     str(trip.id),
        "trip_number": trip.trip_number,
        "origin":      trip.origin,
        "destination": trip.destination,
        "title":       title,
        "body":        body,
        "is_read":     False,
        "created_at":  notif.created_at.isoformat() if notif.created_at else None,
    }
    # Push only to LP owner connections — workers are excluded
    await manager.send_to_org_role(recipient_org_id, 'logistic_partner', message)

    return {
        "success": True,
        "message": "LP owner notified.",
        "realtime_clients": manager.connected_count(recipient_org_id),
        "notification": notif.to_dict(),
    }


@router.patch("/trips/{trip_id}/cancel")
def cancel_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cancel a trip. Allowed by load_owner (their trip) or logistic_partner (their org's trip)."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # Access check
    if role_key in ('logistic_partner', 'super_admin'):
        if str(trip.organization_id) != str(user_org.organization_id):
            raise HTTPException(status_code=403, detail="Access denied")
    elif role_key == 'load_owner':
        if str(trip.load_owner_org_id) != str(user_org.organization_id):
            raise HTTPException(status_code=403, detail="Access denied")
    else:
        raise HTTPException(status_code=403, detail="Access denied")

    if trip.status == 'cancelled':
        raise HTTPException(status_code=409, detail="Trip is already cancelled.")
    if trip.status == 'completed':
        raise HTTPException(status_code=409, detail="Completed trips cannot be cancelled.")

    trip.status = 'cancelled'
    db.commit()
    db.refresh(trip)
    return {"success": True, "message": "Trip cancelled successfully.", "trip": _enrich(trip, db)}


@router.post("/trips/{trip_id}/complete", status_code=200)
async def complete_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a trip as completed (LP owner only). Notifies the load owner."""
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('logistic_partner', 'super_admin'):
        raise HTTPException(status_code=403, detail="Only the logistic partner can mark a trip as completed")

    trip = _get_fleet_trip(trip_id, user_org, db)

    if trip.status == 'completed':
        raise HTTPException(status_code=409, detail="Trip is already completed.")
    if trip.status == 'cancelled':
        raise HTTPException(status_code=409, detail="Cancelled trips cannot be completed.")
    if (trip.current_stage or 0) < 4:
        raise HTTPException(status_code=400, detail="Trip can only be completed after all 4 stages are done.")

    trip.status = 'completed'
    db.commit()

    # Notify load owner if linked
    if trip.load_owner_org_id:
        from app.models.notification import Notification
        from app.services.ws_manager import manager
        from datetime import datetime, timezone

        title = "Trip Completed"
        body = (
            f"Your shipment {trip.trip_number} ({trip.origin} → {trip.destination}) "
            "has been marked as completed by the logistic partner."
        )
        notif = Notification(
            recipient_org_id=trip.load_owner_org_id,
            trip_id=trip.id,
            type="trip_complete",
            title=title,
            body=body,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)

        message = {
            "type":        "trip_complete",
            "id":          str(notif.id),
            "trip_id":     str(trip.id),
            "trip_number": trip.trip_number,
            "origin":      trip.origin,
            "destination": trip.destination,
            "title":       title,
            "body":        body,
            "is_read":     False,
            "created_at":  notif.created_at.isoformat() if notif.created_at else None,
        }
        await manager.send_to_org(str(trip.load_owner_org_id), message)

    db.refresh(trip)
    return {"success": True, "message": "Trip marked as completed.", "trip": _enrich(trip, db)}


# ─── Internal enrichment ─────────────────────────────────────────────────────

def _enrich_bulk(trips: list, db: Session) -> list:
    """Batch-enrich a list of trips — 4 queries total regardless of trip count."""
    if not trips:
        return []

    from app.models.company import Organization
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver

    # Collect unique IDs
    vehicle_ids = {t.vehicle_id for t in trips if t.vehicle_id}
    driver_ids  = {t.driver_id  for t in trips if t.driver_id}
    org_ids     = {t.organization_id for t in trips if t.organization_id} | \
                  {t.load_owner_org_id for t in trips if t.load_owner_org_id}

    # Single query per type
    vehicles = {v.id: v for v in db.query(Vehicle).filter(Vehicle.id.in_(vehicle_ids)).all()} if vehicle_ids else {}
    drivers  = {d.id: d for d in db.query(Driver).filter(Driver.id.in_(driver_ids)).all()}   if driver_ids  else {}
    orgs     = {o.id: o for o in db.query(Organization).filter(Organization.id.in_(org_ids)).all()} if org_ids else {}

    result = []
    for trip in trips:
        data = trip.to_dict()
        # Strip draft_data from list responses — it can contain large base64 blobs
        # (e.g. Aadhaar / DL images) that bloat the payload significantly.
        # draft_data is only needed when resuming a single draft form.
        data.pop("draft_data", None)
        v = vehicles.get(trip.vehicle_id)
        data["vehicle_plate"] = v.vehicle_number if v else None
        data["vehicle_model"] = v.model if v else None
        d = drivers.get(trip.driver_id)
        data["driver_name"] = d.full_name if d else None
        lp_org = orgs.get(trip.organization_id)
        data["lp_org_name"] = lp_org.company_name if lp_org else None
        lo_org = orgs.get(trip.load_owner_org_id)
        data["load_owner_org_name"] = lo_org.company_name if lo_org else None
        result.append(data)

    return result


def _enrich(trip: Trip, db: Session) -> dict:
    """Add vehicle plate, driver name, and org names to trip dict."""
    from app.models.company import Organization

    data = trip.to_dict()

    # Vehicle plate
    if trip.vehicle_id:
        try:
            from app.models.vehicle import Vehicle
            v = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
            data["vehicle_plate"] = v.vehicle_number if v else None
            data["vehicle_model"] = v.model if v else None
        except Exception:
            data["vehicle_plate"] = None
            data["vehicle_model"] = None

    # Driver name
    if trip.driver_id:
        try:
            from app.models.driver import Driver
            d = db.query(Driver).filter(Driver.id == trip.driver_id).first()
            data["driver_name"] = d.full_name if d else None
        except Exception:
            data["driver_name"] = None

    # LP org name (the trip's own organisation)
    try:
        lp_org = db.query(Organization).filter(Organization.id == trip.organization_id).first()
        data["lp_org_name"] = lp_org.company_name if lp_org else None
    except Exception:
        data["lp_org_name"] = None

    # Load owner org name
    if trip.load_owner_org_id:
        try:
            lo_org = db.query(Organization).filter(Organization.id == trip.load_owner_org_id).first()
            data["load_owner_org_name"] = lo_org.company_name if lo_org else None
        except Exception:
            data["load_owner_org_name"] = None
    else:
        data["load_owner_org_name"] = None

    return data
