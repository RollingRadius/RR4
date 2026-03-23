"""
Trips API
Endpoints for managing trips — accessible by both fleet_manager and load_owner roles.
"""

import random
import string
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status, Query
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

    if role_key in ('fleet_management', 'super_admin'):
        query = query.filter(Trip.organization_id == user_org.organization_id)
    elif role_key == 'load_owner':
        query = query.filter(Trip.load_owner_org_id == user_org.organization_id)
    else:
        # Custom roles within a fleet org can see their org's trips
        query = query.filter(Trip.organization_id == user_org.organization_id)

    if status_filter:
        query = query.filter(Trip.status == status_filter)

    total = query.count()
    trips = query.order_by(Trip.created_at.desc()).offset(offset).limit(limit).all()

    return {
        "total": total,
        "trips": [_enrich(t, db) for t in trips],
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
    if role_key in ('fleet_management', 'super_admin'):
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

    if role_key not in ('fleet_management', 'super_admin'):
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

    if role_key not in ('fleet_management', 'super_admin'):
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

class Stage1Payload(BaseModel):
    driver_name:       str
    driver_phone:      str
    driving_license:   str
    aadhaar:           str
    rc:                str
    insurance:         str
    pollution:         str
    fitness:           str
    pan:               str
    tax_declaration:   Optional[str] = None
    cancelled_cheque:  Optional[str] = None


class Stage2Payload(BaseModel):
    specs_verified:    bool
    docs_verified:     bool
    driver_docs_valid: bool
    entry_permission:  bool


class Stage3Payload(BaseModel):
    driver_parked:        bool
    docs_submitted:       bool
    security_verified:    bool
    driver_exited_cabin:  bool
    wheel_stoppers:       bool
    safety_gear:          bool


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
def submit_stage1(
    trip_id: str,
    body: Stage1Payload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 1 — Truck Detail Registration."""
    from datetime import datetime, timezone
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('fleet_management', 'super_admin'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage >= 1:
        raise HTTPException(status_code=409, detail="Stage 1 already submitted")

    trip.s1_driver_name      = body.driver_name
    trip.s1_driver_phone     = body.driver_phone
    trip.s1_driving_license  = body.driving_license
    trip.s1_aadhaar          = body.aadhaar
    trip.s1_rc               = body.rc
    trip.s1_insurance        = body.insurance
    trip.s1_pollution        = body.pollution
    trip.s1_fitness          = body.fitness
    trip.s1_pan              = body.pan
    trip.s1_tax_declaration  = body.tax_declaration
    trip.s1_cancelled_cheque = body.cancelled_cheque
    trip.s1_submitted_at     = datetime.now(timezone.utc)
    trip.current_stage       = 1

    db.commit()
    db.refresh(trip)
    return {"success": True, "message": "Stage 1 saved. Proceed to compliance check.", "trip": _enrich(trip, db)}


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
    if role_key not in ('fleet_management', 'super_admin'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 1:
        raise HTTPException(status_code=409, detail="Complete Stage 1 first")
    if trip.current_stage >= 2:
        raise HTTPException(status_code=409, detail="Stage 2 already submitted")
    if not body.entry_permission:
        raise HTTPException(
            status_code=400,
            detail="Entry permission must be issued to proceed"
        )

    trip.s2_specs_verified    = body.specs_verified
    trip.s2_docs_verified     = body.docs_verified
    trip.s2_driver_docs_valid = body.driver_docs_valid
    trip.s2_entry_permission  = body.entry_permission
    trip.s2_verified_at       = datetime.now(timezone.utc)
    trip.current_stage        = 2

    db.commit()
    db.refresh(trip)
    return {"success": True, "message": "Entry permission issued. Coordinate truck arrival.", "trip": _enrich(trip, db)}


@router.post("/trips/{trip_id}/stage/3", status_code=200)
def submit_stage3(
    trip_id: str,
    body: Stage3Payload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Stage 3 — Truck Arrival at Factory. Completes the trip intake."""
    from datetime import datetime, timezone
    user_org = _get_user_org(current_user, db)
    role_key = _get_role_key(user_org, db)
    if role_key not in ('fleet_management', 'super_admin'):
        raise HTTPException(status_code=403, detail="Fleet managers only")

    trip = _get_fleet_trip(trip_id, user_org, db)
    if trip.current_stage < 2:
        raise HTTPException(status_code=409, detail="Complete Stage 2 first")
    if trip.current_stage >= 3:
        raise HTTPException(status_code=409, detail="Stage 3 already completed")

    trip.s3_driver_parked       = body.driver_parked
    trip.s3_docs_submitted      = body.docs_submitted
    trip.s3_security_verified   = body.security_verified
    trip.s3_driver_exited_cabin = body.driver_exited_cabin
    trip.s3_wheel_stoppers      = body.wheel_stoppers
    trip.s3_safety_gear         = body.safety_gear
    trip.s3_completed_at        = datetime.now(timezone.utc)
    trip.current_stage          = 3
    trip.status                 = 'ongoing'  # now active in factory

    db.commit()
    db.refresh(trip)
    return {"success": True, "message": "Truck intake complete. Trip is now active.", "trip": _enrich(trip, db)}


# ─── Internal enrichment ─────────────────────────────────────────────────────

def _enrich(trip: Trip, db: Session) -> dict:
    """Add vehicle plate and driver name to trip dict."""
    data = trip.to_dict()

    # Vehicle plate
    if trip.vehicle_id:
        try:
            from app.models.vehicle import Vehicle
            v = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
            data["vehicle_plate"] = v.plate_number if v else None
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

    return data
