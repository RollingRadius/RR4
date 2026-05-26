"""
RR Sync API
Proxy endpoints for RR city/material resolution and sync status queries.
All endpoints require authentication — RR details are never exposed to the client.
"""

import logging
from typing import List

import httpx
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.models.company import Organization
from app.models.driver import Driver
from app.models.material_type import MaterialType
from app.models.trip import Trip
from app.models.user import User
from app.models.vehicle import Vehicle
from app.services import rr_token_service

logger = logging.getLogger(__name__)
router = APIRouter()


# ── Helpers ───────────────────────────────────────────────────────────────────

def _rr_headers() -> dict:
    token = rr_token_service.get_access_token()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="RR service not available — token not initialised"
        )
    return {"Authorization": f"Bearer {token}"}


# ── City proxy ────────────────────────────────────────────────────────────────

@router.get("/cities", summary="Resolve city name to RR ObjectId")
async def get_rr_cities(
    q: str = Query(..., min_length=2, description="City name prefix to search"),
    _: User = Depends(get_current_user),
):
    """
    Proxy to RR /cities endpoint.
    Returns a list of {_id, name} matches for the given prefix.
    Used silently when the user picks a LocationIQ autocomplete result.
    """
    if not settings.RR_SYNC_ENABLED:
        return {"items": []}

    import json
    where = json.dumps({"name": {"$regex": f"^{q}", "$options": "i"}})
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/cities",
                params={"where": where, "max_results": 10},
                headers=_rr_headers(),
            )
            resp.raise_for_status()
            data = resp.json()
            items = data.get("_items", [])
            return {
                "items": [
                    {"rr_city_id": c["_id"], "name": c.get("name", "")}
                    for c in items
                ]
            }
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"RR city proxy error: {exc}")
        return {"items": []}   # non-fatal — trip still syncs without city link


# ── Materials (local DB) ──────────────────────────────────────────────────────

@router.get("/materials", summary="Search local material types")
def get_materials(
    q: str = Query("", description="Material name prefix to search"),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """
    Query local material_types table (seeded from RR).
    Zero runtime calls to RR — always fast.
    """
    query = db.query(MaterialType)
    if q:
        query = query.filter(MaterialType.name.ilike(f"{q}%"))
    items = query.order_by(MaterialType.name).limit(20).all()
    return {"items": [m.to_dict() for m in items]}


# ── Sync status ───────────────────────────────────────────────────────────────

@router.get("/sync/status/{trip_id}", summary="Get RR sync status for a trip")
def get_sync_status(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns the current RR sync state for a given RR4 trip."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    return {
        "trip_id":        str(trip.id),
        "trip_number":    trip.trip_number,
        "rr_sync_status": trip.rr_sync_status,
        "rr_sync_error":  trip.rr_sync_error,
        "rr_trip_id":     trip.rr_trip_id,
        "rr_trip_number": trip.rr_trip_number,
        "rr_parcel_id":   trip.rr_parcel_id,
        "rr_synced_at":   trip.rr_synced_at.isoformat() if trip.rr_synced_at else None,
    }


# ── Manual sync trigger (stub — wired in Phase 4) ────────────────────────────

@router.post("/sync/trip/{trip_id}", summary="Manually trigger RR sync for a trip")
async def trigger_sync(
    trip_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Manually trigger sync of a trip to RR (runs as background task)."""
    from app.services import rr_sync_service

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    if not trip.s2_loading_slip_url:
        raise HTTPException(
            status_code=400,
            detail="Loading slip must be uploaded before sync can be triggered"
        )

    # Reset failed status so sync will retry
    if trip.rr_sync_status == "failed":
        trip.rr_sync_status = "not_synced"
        trip.rr_sync_error = None
        db.commit()

    background_tasks.add_task(rr_sync_service.sync_trip_to_rr, trip_id)

    return {
        "message": "Sync triggered — check status in a few seconds",
        "trip_id": str(trip.id),
        "trip_number": trip.trip_number,
    }


# ── Sync readiness list ───────────────────────────────────────────────────────

def _check_trip_readiness(trip: Trip, db: Session) -> dict:
    """
    Check whether a trip has all required RR IDs for sync.
    Returns {ready: bool, missing: [field_names]}.
    """
    missing = []

    if trip.load_owner_org_id:
        lo_org = db.query(Organization).filter(Organization.id == trip.load_owner_org_id).first()
        if not (lo_org and lo_org.rr_company_id):
            missing.append("load_owner_org.rr_company_id")
    else:
        missing.append("load_owner_org.rr_company_id")

    lp_org = db.query(Organization).filter(Organization.id == trip.organization_id).first()
    if not (lp_org and lp_org.rr_company_id):
        missing.append("lp_org.rr_company_id")

    if trip.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
        if not (vehicle and vehicle.rr_vehicle_id):
            missing.append("vehicle.rr_vehicle_id")
    else:
        missing.append("vehicle.rr_vehicle_id")

    if trip.driver_id:
        driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
        if not (driver and driver.rr_user_id):
            missing.append("driver.rr_user_id")
    else:
        missing.append("driver.rr_user_id")

    if not trip.origin_rr_city_id:
        missing.append("origin_rr_city_id")
    if not trip.destination_rr_city_id:
        missing.append("destination_rr_city_id")
    if not trip.material_rr_id:
        missing.append("material_rr_id")
    if not trip.weight_value:
        missing.append("weight_value")
    if not trip.weight_unit:
        missing.append("weight_unit")

    return {"ready": len(missing) == 0, "missing": missing}


def _last_completed_stage(trip: Trip) -> str:
    if trip.s5_completed_at:
        return "S5"
    if trip.s3_completed_at:
        return "S3"
    if trip.s2_verified_at or trip.s2_loading_slip_url:
        return "S2"
    return "S1"


@router.get("/sync/ready", summary="List trips ready or pending sync")
def get_sync_ready(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns two lists:
    - ready: trips that have a loading slip and all required RR IDs
    - missing_data: trips that have a loading slip but are missing some RR IDs
    Excludes trips already fully synced (loading_slip_synced / bilty_synced / pod_synced).
    """
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    # Trips belonging to LP's org that have a loading slip and are not yet fully synced
    syncable_statuses = ("not_synced", "failed", "trip_created")
    trips = (
        db.query(Trip)
        .filter(
            Trip.organization_id == user_org.organization_id,
            Trip.s2_loading_slip_url.isnot(None),
            Trip.rr_sync_status.in_(syncable_statuses),
        )
        .order_by(Trip.created_at.desc())
        .limit(100)
        .all()
    )

    ready = []
    missing_data = []

    for trip in trips:
        check = _check_trip_readiness(trip, db)
        entry = {
            "trip_id":        str(trip.id),
            "trip_number":    trip.trip_number,
            "origin":         trip.origin or "",
            "destination":    trip.destination or "",
            "rr_sync_status": trip.rr_sync_status,
            "rr_sync_error":  trip.rr_sync_error,
            "last_stage":     _last_completed_stage(trip),
        }
        if check["ready"]:
            ready.append(entry)
        else:
            missing_data.append({**entry, "missing": check["missing"]})

    return {
        "ready":        ready,
        "missing_data": missing_data,
        "ready_count":  len(ready),
    }


# ── Bulk sync trigger ─────────────────────────────────────────────────────────

class BulkSyncRequest(BaseModel):
    trip_ids: List[str]


@router.post("/sync/bulk", summary="Trigger RR sync for multiple trips")
async def trigger_bulk_sync(
    body: BulkSyncRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Trigger sync for a list of trip IDs. Each trip runs as an independent
    background task. Returns immediately — check /sync/status/{trip_id} for results.
    """
    from app.services import rr_sync_service
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    if not body.trip_ids:
        raise HTTPException(status_code=400, detail="Provide at least one trip_id")

    if len(body.trip_ids) > 50:
        raise HTTPException(status_code=400, detail="Maximum 50 trips per bulk sync request")

    queued = []
    skipped = []

    for trip_id in body.trip_ids:
        trip = db.query(Trip).filter(
            Trip.id == trip_id,
            Trip.organization_id == user_org.organization_id,
        ).first()

        if not trip:
            skipped.append({"trip_id": trip_id, "reason": "not found"})
            continue

        if not trip.s2_loading_slip_url:
            skipped.append({"trip_id": trip_id, "trip_number": trip.trip_number,
                            "reason": "no loading slip"})
            continue

        if trip.rr_sync_status in ("loading_slip_synced", "bilty_synced", "pod_synced"):
            skipped.append({"trip_id": trip_id, "trip_number": trip.trip_number,
                            "reason": f"already synced ({trip.rr_sync_status})"})
            continue

        # Reset failed so sync retries
        if trip.rr_sync_status == "failed":
            trip.rr_sync_status = "not_synced"
            trip.rr_sync_error = None

        background_tasks.add_task(rr_sync_service.sync_trip_to_rr, trip_id)
        queued.append({"trip_id": trip_id, "trip_number": trip.trip_number})

    db.commit()

    return {
        "message": f"{len(queued)} trip(s) queued for sync",
        "queued":  queued,
        "skipped": skipped,
    }
