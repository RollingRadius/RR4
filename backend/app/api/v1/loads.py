"""
Load Requirements API
Endpoints for load_owner companies to submit and manage load requirements.
"""

import random
import string
import uuid
from datetime import date
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.load_requirement import LoadRequirement
from app.models.trip import Trip

router = APIRouter()


# ── Pydantic schemas ────────────────────────────────────────────────────────

class TruckSpecifications(BaseModel):
    capacity: Optional[str] = None
    axel_type: Optional[str] = None
    body: Optional[str] = None
    floor: Optional[str] = None


class LoadRequirementCreate(BaseModel):
    entry_method: str = 'manual'
    pickup_location: Optional[str] = None
    unload_location: Optional[str] = None
    material_type: Optional[str] = None
    entry_date: Optional[date] = None
    truck_count: int = 1
    specifications: Optional[TruckSpecifications] = None


class LoadRequirementResponse(BaseModel):
    id: str
    company_id: str
    created_by: Optional[str]
    entry_method: str
    pickup_location: Optional[str]
    unload_location: Optional[str]
    material_type: Optional[str]
    entry_date: Optional[date]
    truck_count: int
    capacity: Optional[str]
    axel_type: Optional[str]
    body_type: Optional[str]
    floor_type: Optional[str]
    status: str
    created_at: str

    class Config:
        from_attributes = True


# ── Helpers ─────────────────────────────────────────────────────────────────

def _get_fleet_management_company(current_user: User, db: Session) -> Organization:
    """
    Verify the current user belongs to a fleet_manager (fleet management) company.
    Returns the Organization on success, raises 403 otherwise.
    """
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    if not user_org or not user_org.organization:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must belong to a company to access this resource."
        )

    company = user_org.organization
    if company.business_type != 'fleet_management':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Fleet Management companies can access this resource."
        )

    return company


def _generate_trip_number(db: Session) -> str:
    for _ in range(10):
        suffix = ''.join(random.choices(string.digits, k=5))
        trip_number = f"RR-{suffix}"
        if not db.query(Trip).filter(Trip.trip_number == trip_number).first():
            return trip_number
    raise HTTPException(status_code=500, detail="Could not generate unique trip number")


def _get_load_owner_company(current_user: User, db: Session) -> Organization:
    """
    Verify the current user belongs to a load_owner company.
    Returns the Organization on success, raises 403 otherwise.
    """
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    if not user_org or not user_org.organization:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must belong to a company to submit load requirements."
        )

    company = user_org.organization
    if company.business_type != 'load_owner':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Load Provider companies can submit load requirements."
        )

    return company


def _record_to_response(record: LoadRequirement) -> dict:
    return {
        "id":                  str(record.id),
        "company_id":          str(record.company_id),
        "created_by":          str(record.created_by) if record.created_by else None,
        "entry_method":        record.entry_method,
        "pickup_location":     record.pickup_location,
        "unload_location":     record.unload_location,
        "material_type":       record.material_type,
        "entry_date":          record.entry_date.isoformat() if record.entry_date else None,
        "truck_count":         record.truck_count,
        "capacity":            record.capacity,
        "axel_type":           record.axel_type,
        "body_type":           record.body_type,
        "floor_type":          record.floor_type,
        "fulfilling_org_id":   str(record.fulfilling_org_id) if record.fulfilling_org_id else None,
        "status":              record.status,
        "created_at":          record.created_at.isoformat(),
    }


# ── Endpoints ───────────────────────────────────────────────────────────────

@router.post("", status_code=status.HTTP_201_CREATED)
def create_load_requirement(
    payload: LoadRequirementCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Submit a new load requirement (manual JSON entry).

    **Requires:** JWT · company business_type == 'load_owner'
    """
    company = _get_load_owner_company(current_user, db)

    specs = payload.specifications or TruckSpecifications()

    record = LoadRequirement(
        id=uuid.uuid4(),
        company_id=company.id,
        created_by=current_user.id,
        entry_method=payload.entry_method,
        pickup_location=payload.pickup_location,
        unload_location=payload.unload_location,
        material_type=payload.material_type,
        entry_date=payload.entry_date,
        truck_count=payload.truck_count,
        capacity=specs.capacity,
        axel_type=specs.axel_type,
        body_type=specs.body,
        floor_type=specs.floor,
        status='pending',
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "success": True,
        "message": "Load requirement submitted successfully.",
        "load": _record_to_response(record),
    }


@router.post("/bulk", status_code=status.HTTP_201_CREATED)
async def create_load_requirement_bulk(
    files: List[UploadFile] = File(...),
    entry_date: Optional[str] = Form(None),
    truck_count: int = Form(1),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Submit load requirements via bulk file upload (Excel / CSV).

    **Requires:** JWT · company business_type == 'load_owner'
    """
    company = _get_load_owner_company(current_user, db)

    if not files:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="At least one file is required for bulk upload."
        )

    # Validate file types
    allowed = {'.xlsx', '.xls', '.csv'}
    for f in files:
        ext = '.' + (f.filename or '').rsplit('.', 1)[-1].lower()
        if ext not in allowed:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"File '{f.filename}' is not an accepted type (xlsx, xls, csv)."
            )

    parsed_date = None
    if entry_date:
        try:
            parsed_date = date.fromisoformat(entry_date)
        except ValueError:
            pass

    record = LoadRequirement(
        id=uuid.uuid4(),
        company_id=company.id,
        created_by=current_user.id,
        entry_method='bulk',
        entry_date=parsed_date,
        truck_count=truck_count,
        status='pending',
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "success": True,
        "message": f"Bulk manifest received ({len(files)} file(s)). Processing queued.",
        "load": _record_to_response(record),
    }


@router.post("/photo", status_code=status.HTTP_201_CREATED)
async def create_load_requirement_photo(
    photo: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Submit a load requirement via photo (AI-assisted data entry).

    **Requires:** JWT · company business_type == 'load_owner'
    """
    company = _get_load_owner_company(current_user, db)

    allowed_mime = {'image/jpeg', 'image/png', 'image/webp'}
    if photo.content_type not in allowed_mime:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Photo must be JPEG, PNG, or WebP."
        )

    record = LoadRequirement(
        id=uuid.uuid4(),
        company_id=company.id,
        created_by=current_user.id,
        entry_method='photo',
        status='pending',
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "success": True,
        "message": "Photo received. AI extraction queued.",
        "load": _record_to_response(record),
    }


class FulfillPayload(BaseModel):
    vehicle_id: Optional[str] = None
    driver_id: Optional[str] = None
    notes: Optional[str] = None


# ── Fleet Management Endpoints ───────────────────────────────────────────────

@router.get("/available", status_code=status.HTTP_200_OK)
def list_available_loads(
    pickup: Optional[str] = Query(None, description="Filter by pickup location (partial match)"),
    drop: Optional[str] = Query(None, description="Filter by drop/unload location (partial match)"),
    material: Optional[str] = Query(None, description="Filter by material type"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Browse all pending load requirements posted by load owner companies.

    **Requires:** JWT · company business_type == 'fleet_management'
    """
    _get_fleet_management_company(current_user, db)

    query = db.query(LoadRequirement, Organization).join(
        Organization, Organization.id == LoadRequirement.company_id
    ).filter(
        LoadRequirement.status == 'pending'
    )

    if pickup:
        query = query.filter(LoadRequirement.pickup_location.ilike(f'%{pickup}%'))
    if drop:
        query = query.filter(LoadRequirement.unload_location.ilike(f'%{drop}%'))
    if material:
        query = query.filter(LoadRequirement.material_type.ilike(f'%{material}%'))

    rows = query.order_by(LoadRequirement.created_at.desc()).all()

    loads = []
    for record, company in rows:
        item = _record_to_response(record)
        item['company_name'] = company.company_name
        item['company_city'] = company.city
        item['company_state'] = company.state
        item['company_phone'] = company.business_phone
        loads.append(item)

    return {
        "success": True,
        "loads": loads,
        "count": len(loads),
    }


@router.post("/{load_id}/fulfill", status_code=status.HTTP_201_CREATED)
def fulfill_load_requirement(
    load_id: str,
    payload: FulfillPayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Fleet management accepts a load requirement and creates a trip to fulfill it.

    **Requires:** JWT · company business_type == 'fleet_management'
    """
    fleet_company = _get_fleet_management_company(current_user, db)

    # Fetch load requirement
    try:
        load_uuid = uuid.UUID(load_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid load ID.")

    load = db.query(LoadRequirement).filter(LoadRequirement.id == load_uuid).first()
    if not load:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Load requirement not found.")
    if load.status != 'pending':
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Load requirement is already '{load.status}' and cannot be fulfilled."
        )

    # Parse optional vehicle/driver IDs
    vehicle_uuid = None
    if payload.vehicle_id:
        try:
            vehicle_uuid = uuid.UUID(payload.vehicle_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid vehicle_id.")

    driver_uuid = None
    if payload.driver_id:
        try:
            driver_uuid = uuid.UUID(payload.driver_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid driver_id.")

    # Create trip
    trip = Trip(
        id=uuid.uuid4(),
        trip_number=_generate_trip_number(db),
        origin=load.pickup_location or '',
        destination=load.unload_location or '',
        load_item=load.material_type or 'Cargo',
        weight=load.capacity,
        status='pending',
        organization_id=fleet_company.id,
        load_owner_org_id=load.company_id,
        load_requirement_id=load.id,
        vehicle_id=vehicle_uuid,
        driver_id=driver_uuid,
        created_by=current_user.id,
    )
    db.add(trip)

    # Mark load as matched
    load.status = 'matched'
    load.fulfilling_org_id = fleet_company.id

    db.commit()
    db.refresh(trip)
    db.refresh(load)

    return {
        "success": True,
        "message": "Load requirement accepted. Trip created successfully.",
        "trip": trip.to_dict(),
        "load": _record_to_response(load),
    }


@router.get("", status_code=status.HTTP_200_OK)
def list_load_requirements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List all load requirements for the current user's company.

    **Requires:** JWT · company business_type == 'load_owner'
    """
    company = _get_load_owner_company(current_user, db)

    records = db.query(LoadRequirement).filter(
        LoadRequirement.company_id == company.id
    ).order_by(LoadRequirement.created_at.desc()).all()

    return {
        "success": True,
        "loads": [_record_to_response(r) for r in records],
        "count": len(records),
    }
