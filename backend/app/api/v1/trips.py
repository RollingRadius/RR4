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
