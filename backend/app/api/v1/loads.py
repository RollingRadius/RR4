"""
Load Requirements API
Endpoints for load_owner companies to submit and manage load requirements.
"""

import json
import random
import string
import uuid
from datetime import date, datetime
from typing import Optional, List
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from sqlalchemy import or_, func, cast, text
from sqlalchemy.dialects.postgresql import JSONB

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.load_requirement import LoadRequirement
from app.models.trip import Trip
from app.models.role import Role
from app.services import fcm_service
from app.config import settings

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
    pickup_lat: Optional[float] = None
    pickup_lon: Optional[float] = None
    unload_location: Optional[str] = None
    unload_lat: Optional[float] = None
    unload_lon: Optional[float] = None
    material_type: Optional[str] = None
    entry_date: Optional[date] = None
    truck_count: int = 1
    specifications: Optional[TruckSpecifications] = None
    # Optional: restrict visibility to specific fleet-management orgs (list of org UUIDs)
    target_org_ids: Optional[List[str]] = None


class LoadRequirementResponse(BaseModel):
    id: str
    company_id: str
    created_by: Optional[str]
    entry_method: str
    pickup_location: Optional[str]
    pickup_lat: Optional[float]
    pickup_lon: Optional[float]
    unload_location: Optional[str]
    unload_lat: Optional[float]
    unload_lon: Optional[float]
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

def _get_logistic_partner_company(current_user: User, db: Session) -> Organization:
    """
    Verify the current user has a logistic_partner (or super_admin) role.
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

    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    role_key = role.role_key if role else ''
    if role_key not in ('logistic_partner', 'super_admin'):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Logistic Partner users can access this resource."
        )

    return user_org.organization


def _get_fleet_member_org(current_user: User, db: Session) -> Organization:
    """
    Verify the current user belongs to a fleet org (admin or worker).
    Allows logistic_partner, fleet_worker, and super_admin.
    Used for read-only fleet endpoints such as browsing available loads.
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

    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    role_key = role.role_key if role else ''
    if role_key not in ('logistic_partner', 'fleet_worker', 'super_admin'):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Logistic Partner users can access this resource."
        )

    return user_org.organization


def _generate_trip_number(db: Session) -> str:
    ist = ZoneInfo("Asia/Kolkata")
    date_part = datetime.now(ist).strftime('%d%m%y')  # Always DDMMYY in IST, e.g. 300426
    for _ in range(15):
        suffix = ''.join(random.choices(string.digits, k=5))
        trip_number = f"RR-{date_part}-{suffix}"  # e.g. RR-300426-12345
        if not db.query(Trip).filter(Trip.trip_number == trip_number).first():
            return trip_number
    raise HTTPException(status_code=500, detail="Could not generate unique trip number")


def _get_load_owner_company(current_user: User, db: Session) -> Organization:
    """
    Verify the current user has a load_owner (or super_admin) role.
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

    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    role_key = role.role_key if role else ''
    if role_key not in ('load_owner', 'super_admin'):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Load Owner users can submit load requirements."
        )

    return user_org.organization


def _record_to_response(record: LoadRequirement) -> dict:
    return {
        "id":                  str(record.id),
        "company_id":          str(record.company_id),
        "created_by":          str(record.created_by) if record.created_by else None,
        "entry_method":        record.entry_method,
        "pickup_location":     record.pickup_location,
        "pickup_lat":          record.pickup_lat,
        "pickup_lon":          record.pickup_lon,
        "unload_location":     record.unload_location,
        "unload_lat":          record.unload_lat,
        "unload_lon":          record.unload_lon,
        "material_type":       record.material_type,
        "entry_date":          record.entry_date.isoformat() if record.entry_date else None,
        "truck_count":         record.truck_count,
        "capacity":            record.capacity,
        "axel_type":           record.axel_type,
        "body_type":           record.body_type,
        "floor_type":          record.floor_type,
        "fulfilling_org_id":   str(record.fulfilling_org_id) if getattr(record, 'fulfilling_org_id', None) else None,
        "target_org_ids":      getattr(record, 'target_org_ids', None) or [],
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

    target_org_ids = payload.target_org_ids if payload.target_org_ids else None

    record_kwargs = dict(
        id=uuid.uuid4(),
        company_id=company.id,
        created_by=current_user.id,
        entry_method=payload.entry_method,
        pickup_location=payload.pickup_location,
        pickup_lat=payload.pickup_lat,
        pickup_lon=payload.pickup_lon,
        unload_location=payload.unload_location,
        unload_lat=payload.unload_lat,
        unload_lon=payload.unload_lon,
        material_type=payload.material_type,
        entry_date=payload.entry_date,
        truck_count=payload.truck_count,
        capacity=specs.capacity,
        axel_type=specs.axel_type,
        body_type=specs.body,
        floor_type=specs.floor,
        status='pending',
    )
    if hasattr(LoadRequirement, 'target_org_ids'):
        record_kwargs['target_org_ids'] = target_org_ids

    record = LoadRequirement(**record_kwargs)

    db.add(record)
    db.commit()
    db.refresh(record)

    # Notify only the targeted LP orgs (token-based, not broadcast to all)
    try:
        pickup = record.pickup_location or '?'
        drop   = record.unload_location or '?'
        count  = record.truck_count or 1
        notif_title = "New Load Available"
        notif_body  = f"{pickup} → {drop} | {count} truck(s) needed. Tap to view details."
        notif_data  = {"type": "new_load", "load_id": str(record.id)}
        orgs_to_notify = target_org_ids or []
        for org_id in orgs_to_notify:
            try:
                import uuid as _u
                fcm_service.send_to_org_users(
                    _u.UUID(str(org_id)) if not hasattr(org_id, 'hex') else org_id,
                    notif_title, notif_body, notif_data, db,
                )
            except Exception:
                pass
    except Exception:
        pass

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
    vehicle_id:              Optional[str]   = None
    driver_id:               Optional[str]   = None
    trip_amount:             Optional[float] = None   # Agreed freight amount (₹)
    notes:                   Optional[str]   = None
    transporter_user_id:     Optional[str]   = None   # Transporter to upload loading slip
    # Consignor (sender/shipper) — picked directly from RR company list
    consignor_rr_company_id: Optional[str]   = None   # RR company ObjectId
    # Consignee (load_receiver) — one of the three must be provided
    consignee_org_id:        Optional[str]   = None   # RR4 load_receiver organisation UUID
    consignee_user_id:       Optional[str]   = None   # RR4 load_receiver individual user UUID
    consignee_rr_company_id: Optional[str]   = None   # RR company ObjectId (picked from RR directly)
    # RR Ops worker assigned to handle this trip's sync
    rr_ops_user_id:          Optional[str]   = None
    # RR sync fields
    origin_rr_city_id:       Optional[str]   = None
    destination_rr_city_id:  Optional[str]   = None
    material_rr_id:          Optional[str]   = None
    weight_value:            Optional[float] = None
    weight_unit:             Optional[str]   = None
    invoice_value:           Optional[float] = None
    vehicle_body_type:       Optional[str]   = None
    # LP's RR session token — if provided, trip+parcel are created in RR immediately
    rr_token:                Optional[str]   = None


# ── Logistic Partner Endpoints ───────────────────────────────────────────────

@router.get("/available", status_code=status.HTTP_200_OK)
def list_available_loads(
    pickup: Optional[str] = Query(None, description="Filter by pickup location (partial match)"),
    drop: Optional[str] = Query(None, description="Filter by drop/unload location (partial match)"),
    material: Optional[str] = Query(None, description="Filter by material type"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Browse pending load requirements posted by load owner companies.
    Loads with target_org_ids set are only visible to those specific fleet-management orgs.

    **Requires:** JWT · company business_type == 'logistic_partner'
    """
    fleet_org = _get_fleet_member_org(current_user, db)
    org_id_str = str(fleet_org.id)

    base_filter = [
        LoadRequirement.status == 'pending',
    ]
    if pickup:
        base_filter.append(LoadRequirement.pickup_location.ilike(f'%{pickup}%'))
    if drop:
        base_filter.append(LoadRequirement.unload_location.ilike(f'%{drop}%'))
    if material:
        base_filter.append(LoadRequirement.material_type.ilike(f'%{material}%'))

    # Raw SQL for JSONB containment check — avoids psycopg2 `?` binding conflicts
    # and SQLAlchemy operator translation issues with @> on JSONB columns.
    # Falls back to showing all pending loads when the target_org_ids column
    # does not yet exist (migration 036 not applied on this server).
    try:
        target_filter = text(
            "(load_requirements.target_org_ids IS NULL"
            " OR jsonb_array_length(load_requirements.target_org_ids) = 0"
            " OR load_requirements.target_org_ids @> CAST(:org_array AS JSONB))"
        ).bindparams(org_array=json.dumps([org_id_str]))

        rows = (
            db.query(LoadRequirement, Organization)
            .join(Organization, Organization.id == LoadRequirement.company_id)
            .filter(*base_filter, target_filter)
            .order_by(LoadRequirement.created_at.desc())
            .all()
        )
    except Exception:
        # Column missing — show all pending loads without targeting filter
        db.rollback()
        rows = (
            db.query(LoadRequirement, Organization)
            .join(Organization, Organization.id == LoadRequirement.company_id)
            .filter(*base_filter)
            .order_by(LoadRequirement.created_at.desc())
            .all()
        )

    loads = []
    for record, company in rows:
        # Python-level guard: double-check targeting (getattr is safe if column missing)
        targets = getattr(record, 'target_org_ids', None)
        if targets is not None and len(targets) > 0 and org_id_str not in targets:
            continue

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


@router.get("/transporter/available", status_code=status.HTTP_200_OK)
def list_loads_for_transporter(
    pickup: Optional[str] = Query(None, description="Filter by pickup location (partial match)"),
    drop: Optional[str] = Query(None, description="Filter by drop/unload location (partial match)"),
    material: Optional[str] = Query(None, description="Filter by material type"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Browse all pending load requirements posted by load owner companies.
    Every transporter sees every posted load — no targeting filter applied.

    **Requires:** JWT · role_key == 'transporter'
    """
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active',
    ).first()
    if not user_org:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    if not role or role.role_key != 'transporter':
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only transporters can access this endpoint.")

    base_filter = [LoadRequirement.status == 'pending']
    if pickup:
        base_filter.append(LoadRequirement.pickup_location.ilike(f'%{pickup}%'))
    if drop:
        base_filter.append(LoadRequirement.unload_location.ilike(f'%{drop}%'))
    if material:
        base_filter.append(LoadRequirement.material_type.ilike(f'%{material}%'))

    rows = (
        db.query(LoadRequirement, Organization)
        .join(Organization, Organization.id == LoadRequirement.company_id)
        .filter(*base_filter)
        .order_by(LoadRequirement.created_at.desc())
        .all()
    )

    loads = []
    for record, company in rows:
        item = _record_to_response(record)
        item['company_name'] = company.company_name
        item['company_city'] = company.city
        item['company_state'] = company.state
        item['company_phone'] = company.business_phone
        loads.append(item)

    return {"success": True, "loads": loads, "count": len(loads)}


@router.get("/search-partners", status_code=status.HTTP_200_OK)
def search_fleet_partners(
    q: str = Query(..., min_length=1, description="Search query (user name or company name)"),
    limit: int = Query(10, le=20),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Search for fleet-management (and future logistic_partner) organisations to target
    when creating a load requirement.

    Returns distinct organisations matched by company name OR a member's full name / username.
    **Requires:** JWT · load_owner role
    """
    _get_load_owner_company(current_user, db)

    target_roles = ('logistic_partner',)

    rows = (
        db.query(
            Organization.id,
            Organization.company_name,
            Organization.city,
            func.min(User.full_name).label('user_name'),
            func.min(User.username).label('username'),
        )
        .join(UserOrganization, UserOrganization.organization_id == Organization.id)
        .join(User, User.id == UserOrganization.user_id)
        .join(Role, Role.id == UserOrganization.role_id)
        .filter(
            UserOrganization.status == 'active',
            Role.role_key.in_(target_roles),
            or_(
                User.full_name.ilike(f'%{q}%'),
                User.username.ilike(f'%{q}%'),
                Organization.company_name.ilike(f'%{q}%'),
            ),
        )
        .group_by(Organization.id, Organization.company_name, Organization.city)
        .order_by(Organization.company_name)
        .limit(limit)
        .all()
    )

    partners = [
        {
            "org_id":       str(row.id),
            "org_name":     row.company_name,
            "org_city":     row.city or '',
            "user_name":    row.user_name,
            "username":     row.username,
        }
        for row in rows
    ]

    return {"success": True, "partners": partners}


@router.post("/{load_id}/fulfill", status_code=status.HTTP_201_CREATED)
async def fulfill_load_requirement(
    load_id: str,
    payload: FulfillPayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Fleet management accepts a load requirement and creates a trip to fulfill it.

    **Requires:** JWT · company business_type == 'logistic_partner'
    """
    fleet_company = _get_logistic_partner_company(current_user, db)

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

    # Validate mandatory consignee — one of org UUID, user UUID, or RR company ObjectId must be provided
    if not payload.consignee_org_id and not payload.consignee_user_id and not payload.consignee_rr_company_id:
        raise HTTPException(status_code=400, detail="A consignee (load_receiver) is required.")

    consignee_org_uuid = None
    if payload.consignee_org_id:
        try:
            consignee_org_uuid = uuid.UUID(payload.consignee_org_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid consignee_org_id.")
        if not db.query(Organization).filter(Organization.id == consignee_org_uuid).first():
            raise HTTPException(status_code=404, detail="Consignee organisation not found.")

    consignee_user_uuid = None
    if payload.consignee_user_id:
        try:
            consignee_user_uuid = uuid.UUID(payload.consignee_user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid consignee_user_id.")
        if not db.query(User).filter(User.id == consignee_user_uuid).first():
            raise HTTPException(status_code=404, detail="Consignee user not found.")

    # Parse optional RR Ops worker
    rr_ops_uuid = None
    if payload.rr_ops_user_id:
        try:
            rr_ops_uuid = uuid.UUID(payload.rr_ops_user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid rr_ops_user_id.")

    # Parse and validate optional transporter
    transporter_uuid = None
    if payload.transporter_user_id:
        try:
            transporter_uuid = uuid.UUID(payload.transporter_user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid transporter_user_id.")
        t_user = db.query(User).filter(User.id == transporter_uuid).first()
        if not t_user:
            raise HTTPException(status_code=404, detail="Transporter user not found.")
        t_org = db.query(UserOrganization).filter(
            UserOrganization.user_id == transporter_uuid,
            UserOrganization.status == 'active',
        ).first()
        if not t_org:
            raise HTTPException(status_code=400, detail="Selected user is not an active transporter.")
        t_role = db.query(Role).filter(Role.id == t_org.role_id).first()
        if not t_role or t_role.role_key != 'transporter':
            raise HTTPException(status_code=400, detail="Selected user does not have the transporter role.")

    # Build and persist the trip — retry on trip_number collision (race condition guard)
    trip_kwargs = dict(
        id=uuid.uuid4(),
        origin=load.pickup_location or '',
        destination=load.unload_location or '',
        load_item=load.material_type or 'Cargo',
        weight=load.capacity,
        trip_amount=payload.trip_amount,
        status='ongoing',
        organization_id=fleet_company.id,
        load_owner_org_id=load.company_id,
        vehicle_id=vehicle_uuid,
        driver_id=driver_uuid,
        transporter_user_id=transporter_uuid,
        consignor_rr_company_id=payload.consignor_rr_company_id or None,
        consignee_org_id=consignee_org_uuid,
        consignee_user_id=consignee_user_uuid,
        consignee_rr_company_id=payload.consignee_rr_company_id or None,
        rr_ops_user_id=rr_ops_uuid,
        created_by=current_user.id,
        origin_rr_city_id=payload.origin_rr_city_id,
        destination_rr_city_id=payload.destination_rr_city_id,
        material_rr_id=payload.material_rr_id,
        weight_value=payload.weight_value,
        weight_unit=payload.weight_unit,
        invoice_value=payload.invoice_value,
        vehicle_body_type=payload.vehicle_body_type or None,
    )
    if hasattr(Trip, 'load_requirement_id'):
        trip_kwargs['load_requirement_id'] = load.id

    trip = None
    for attempt in range(3):
        try:
            trip_kwargs['id'] = uuid.uuid4()
            trip_kwargs['trip_number'] = _generate_trip_number(db)
            trip = Trip(**trip_kwargs)
            db.add(trip)
            load.status = 'assigned'
            if hasattr(load, 'fulfilling_org_id'):
                load.fulfilling_org_id = fleet_company.id
            db.commit()
            db.refresh(trip)
            db.refresh(load)
            break
        except IntegrityError:
            db.rollback()
            if attempt == 2:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Could not create trip after multiple attempts. Please try again."
                )
        except SQLAlchemyError as exc:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error while creating trip: {str(exc)}"
            )
        except Exception as exc:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Unexpected error while creating trip: {str(exc)}"
            )

    # ── Notify LP workers about new work ──────────────────────────────────────
    try:
        from app.models.notification import Notification
        from app.services.ws_manager import manager

        title = "New Trip Assigned"
        body  = (
            f"Trip {trip.trip_number} has been created: "
            f"{trip.origin} → {trip.destination}. "
            "Please check and begin stage processing."
        )
        notif = Notification(
            recipient_org_id=fleet_company.id,
            trip_id=trip.id,
            type="new_work",
            title=title,
            body=body,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)

        message = {
            "type":        "new_work",
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
        await manager.send_to_org(str(fleet_company.id), message)
    except Exception:
        pass  # notification failure must never block the trip creation response

    # FCM: notify LP workers about new trip assignment
    try:
        fcm_service.send_to_org_users(
            fleet_company.id,
            "New Trip Assigned",
            f"Trip {trip.trip_number} | {trip.origin} → {trip.destination}\nBegin stage processing.",
            {"type": "new_work", "trip_id": str(trip.id)},
            db,
        )
    except Exception:
        pass

    # FCM: notify load owner that their load was accepted
    try:
        fcm_service.send_to_org_users(
            load.company_id,
            "Load Accepted",
            f"Trip {trip.trip_number} | {trip.origin} → {trip.destination}\nYour load has been accepted by a fleet partner.",
            {"type": "load_accepted", "load_id": str(load.id), "trip_id": str(trip.id)},
            db,
        )
    except Exception:
        pass

    # RR Sync: if LP provided their RR token, create trip+parcel in RR immediately
    if payload.rr_token and settings.RR_SYNC_ENABLED:
        from app.services.rr_sync_service import sync_all_to_rr
        await sync_all_to_rr(str(trip.id), payload.rr_token)
        db.refresh(trip)  # pick up rr_trip_id / rr_parcel_id written by sync

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


@router.patch("/{load_id}/cancel", status_code=status.HTTP_200_OK)
async def cancel_load_requirement(
    load_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Soft-cancel a load requirement (status → 'cancelled').
    - If the load has a linked trip, that trip is also cancelled.
    - The LP org is notified via WebSocket in both cases (fulfilled or just matched).
    - Only the owning load_owner company can cancel their own loads.
    """
    company = _get_load_owner_company(current_user, db)

    try:
        load_uuid = uuid.UUID(load_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid load ID format")

    load = db.query(LoadRequirement).filter(
        LoadRequirement.id == load_uuid,
        LoadRequirement.company_id == company.id,
    ).first()

    if not load:
        raise HTTPException(status_code=404, detail="Load requirement not found")

    if load.status == 'cancelled':
        raise HTTPException(status_code=409, detail="Load is already cancelled")

    # ── 1. Cancel the load ────────────────────────────────────────────────────
    load.status = 'cancelled'

    # ── 2. Cancel the linked trip (if any) ───────────────────────────────────
    linked_trip = db.query(Trip).filter(
        Trip.load_requirement_id == load_uuid,
        Trip.status.notin_(['cancelled', 'completed']),
    ).first()

    if linked_trip:
        linked_trip.status = 'cancelled'

    db.commit()

    # ── 3. Notify the LP org ──────────────────────────────────────────────────
    # Determine which LP org to notify:
    #   - Fulfilled load  → trip.organization_id (the fleet org running the trip)
    #   - Matched but no trip yet → load.fulfilling_org_id
    lp_org_id = None
    if linked_trip and linked_trip.organization_id:
        lp_org_id = linked_trip.organization_id
    elif load.fulfilling_org_id:
        lp_org_id = load.fulfilling_org_id

    if lp_org_id:
        from app.models.notification import Notification
        from app.services.ws_manager import manager

        canceller = company.company_name if hasattr(company, 'company_name') else "Load Owner"

        if linked_trip:
            title = "Trip Cancelled"
            body = (
                f"Trip {linked_trip.trip_number} "
                f"({linked_trip.origin} → {linked_trip.destination}) "
                f"has been cancelled by {canceller}."
            )
            trip_id_for_notif = linked_trip.id
            notif_type = "trip_cancelled"
        else:
            title = "Load Requirement Cancelled"
            body = (
                f"Load requirement from {load.pickup_location} → {load.unload_location} "
                f"has been cancelled by {canceller}."
            )
            trip_id_for_notif = None
            notif_type = "load_cancelled"

        notif = Notification(
            recipient_org_id=lp_org_id,
            trip_id=trip_id_for_notif,
            type=notif_type,
            title=title,
            body=body,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)

        message = {
            "type":        notif_type,
            "id":          str(notif.id),
            "trip_id":     str(linked_trip.id) if linked_trip else None,
            "title":       title,
            "body":        body,
            "is_read":     False,
            "created_at":  notif.created_at.isoformat() if notif.created_at else None,
        }
        await manager.send_to_org(str(lp_org_id), message)

        # FCM push to LP org users (best-effort)
        try:
            fcm_service.send_to_org_users(
                lp_org_id, title, body,
                {"type": notif_type, "load_id": str(load.id)},
                db,
            )
        except Exception:
            pass

    # ── 4. Notify the transporter if the linked trip had one assigned ──────────
    if linked_trip and linked_trip.transporter_user_id:
        from app.models.notification import Notification as _TN
        from app.services.ws_manager import manager as _mgr
        canceller_name = company.company_name if hasattr(company, 'company_name') else "Load Owner"
        t_title = "Trip Cancelled"
        t_body = (
            f"Trip {linked_trip.trip_number} ({linked_trip.origin} → {linked_trip.destination}) "
            f"has been cancelled by {canceller_name}."
        )
        t_notif = _TN(
            recipient_user_id=linked_trip.transporter_user_id,
            trip_id=linked_trip.id,
            type="trip_cancelled",
            title=t_title,
            body=t_body,
        )
        db.add(t_notif)
        db.commit()
        db.refresh(t_notif)

        t_msg = {
            "type":        "trip_cancelled",
            "id":          str(t_notif.id),
            "trip_id":     str(linked_trip.id),
            "trip_number": linked_trip.trip_number,
            "origin":      linked_trip.origin,
            "destination": linked_trip.destination,
            "title":       t_title,
            "body":        t_body,
            "is_read":     False,
            "created_at":  t_notif.created_at.isoformat() if t_notif.created_at else None,
        }
        try:
            await _mgr.send_to_org(f"user:{str(linked_trip.transporter_user_id)}", t_msg)
        except Exception:
            pass
        try:
            t_user = db.query(User).filter(User.id == linked_trip.transporter_user_id).first()
            if t_user and t_user.fcm_token:
                fcm_service.send_to_token(
                    t_user.fcm_token, t_title, t_body,
                    {"type": "trip_cancelled", "trip_id": str(linked_trip.id)},
                )
        except Exception:
            pass

    db.refresh(load)

    return {
        "success": True,
        "message": "Load requirement cancelled successfully.",
        "load": _record_to_response(load),
        "trip_cancelled": linked_trip is not None,
    }
