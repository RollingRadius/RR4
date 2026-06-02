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
from app.models.trip import Trip
from app.models.user import User

logger = logging.getLogger(__name__)
router = APIRouter()


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
    import json
    where = json.dumps({"name": {"$regex": f"^{q}", "$options": "i"}})
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/cities",
                params={"where": where, "max_results": 10},
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


# ── Materials proxy ───────────────────────────────────────────────────────────

@router.get("/materials", summary="Search RR material types")
async def get_materials(
    q: str = Query("", description="Material name prefix to search"),
    _: User = Depends(get_current_user),
):
    """
    Proxy to RR GET /material_types endpoint.
    Returns a list of {rr_material_id, name} matches for the given prefix.
    """
    import json
    params: dict = {"max_results": 20}
    if q:
        params["where"] = json.dumps({"name": {"$regex": f"^{q}", "$options": "i"}})
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/material_types",
                params=params,
            )
            resp.raise_for_status()
            items = resp.json().get("_items", [])
            return {
                "items": [
                    {"rr_material_id": m["_id"], "name": m.get("name", "")}
                    for m in items
                ]
            }
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"RR material_types proxy error: {exc}")
        return {"items": []}


# ── Enum proxy ────────────────────────────────────────────────────────────────

@router.get("/enums", summary="Proxy RR get_enum — QuantityUnit, VehicleBodyTypes, etc.")
async def get_enum(
    name: str = Query(..., description="Enum name e.g. QuantityUnit or VehicleBodyTypes"),
    _: User = Depends(get_current_user),
):
    """
    Proxies GET /get_enum?enum_name=<name> (public endpoint on RR, no auth required).
    Returns {values: ["TONNES", "KILOGRAMS", ...]} for the requested enum.
    """
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/get_enum",
                params={"enum_name": name},
            )
            resp.raise_for_status()
            data = resp.json()
            # get_enum returns {"_status": "Ok", "_items": ["TONNES", ...]}
            values = data.get("_items", [])
            return {"values": values if isinstance(values, list) else []}
    except Exception as exc:
        logger.error(f"RR get_enum proxy error ({name}): {exc}")
        return {"values": []}


# ── Sync status ───────────────────────────────────────────────────────────────

@router.get("/sync/status/{trip_id}", summary="Get RR sync status for a trip")
def get_sync_status(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns the current RR sync state for a given RR4 trip."""
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    trip = db.query(Trip).filter(
        Trip.id == trip_id,
        Trip.organization_id == user_org.organization_id,
    ).first()
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


# ── RR Authentication proxy ───────────────────────────────────────────────────

class RrAuthRequest(BaseModel):
    username: str
    password: str


@router.post("/auth/login", summary="Authenticate with RR and obtain an access token")
async def rr_auth_login(
    body: RrAuthRequest,
    _: User = Depends(get_current_user),
):
    """
    Proxy to RR GET /persons/authenticate (Basic Auth).
    Returns a short-lived RR access token for use in the sync endpoint.
    RR credentials are never stored — they are used once to obtain a token.
    """
    if not settings.RR_SYNC_ENABLED:
        raise HTTPException(status_code=503, detail="RR sync is disabled on this server")

    # RR requires full phone with country code (e.g. 918905393266).
    # Auto-prepend India country code if a bare 10-digit number is supplied.
    rr_username = body.username.strip()
    if rr_username.isdigit() and len(rr_username) == 10:
        rr_username = "91" + rr_username

    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/persons/authenticate",
                auth=(rr_username, body.password),
            )
    except Exception as exc:
        logger.error(f"RR auth proxy error: {exc}")
        raise HTTPException(status_code=503, detail="Could not reach RR server")

    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid RR credentials")

    data = resp.json()
    token = data.get("access_token") or data.get("token")
    if not token:
        logger.error(f"RR auth response missing token: {resp.text[:200]}")
        raise HTTPException(status_code=500, detail="RR auth response missing token")

    user_record = data.get("user_record") or {}
    rr_user_id = str(user_record.get("_id", "")) if user_record else ""

    return {"token": token, "rr_user_id": rr_user_id}


# ── Manual sync trigger ───────────────────────────────────────────────────────

class RrSyncRequest(BaseModel):
    rr_token: str


@router.post("/sync/trip/{trip_id}", summary="Manually trigger RR sync for a trip")
async def trigger_sync(
    trip_id: str,
    body: RrSyncRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Manually trigger sync of a trip to RR (runs as background task).
    Requires the LP's RR access token obtained from POST /auth/login.
    """
    from app.services import rr_sync_service
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    trip = db.query(Trip).filter(
        Trip.id == trip_id,
        Trip.organization_id == user_org.organization_id,
    ).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # Reset failed status so sync will retry
    if trip.rr_sync_status == "failed":
        trip.rr_sync_status = "not_synced"
        trip.rr_sync_error = None
        db.commit()

    background_tasks.add_task(rr_sync_service.sync_all_to_rr, trip_id, body.rr_token)

    return {
        "message": "Sync triggered — check status in a few seconds",
        "trip_id": str(trip.id),
        "trip_number": trip.trip_number,
    }


# ── Preferred partners proxy ──────────────────────────────────────────────────

@router.get("/preferred-partners", summary="Get LP's preferred partners from RR")
async def get_preferred_partners(
    rr_token: str = Query("", description="LP's RR session token"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Proxies GET /preferred_partners?where={"user_company":"<lp_rr_company_id>"}&embedded={...}
    Used to populate the consignor/consignee partner pickers in the FulfillSheet and CreateTripScreen.
    """
    import json
    from app.models import UserOrganization
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    lp_rr_company_id = user_org.organization.rr_company_id if user_org.organization else None
    if not lp_rr_company_id:
        return {"partners": []}

    params = {
        "where": json.dumps({"user_company": lp_rr_company_id}),
        "embedded": json.dumps({
            "user_preferred_partner": 1,
            "user_preferred_partner.postal_addresses.city": 1,
            "company_preferred_partner": 1,
        }),
        "max_results": 100,
    }
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/preferred_partners",
            params=params,
            headers=headers,
        )
        if resp.status_code != 200:
            logger.error(f"RR preferred-partners returned {resp.status_code}: {resp.text[:200]}")
            raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
        items = resp.json().get("_items", [])
        partners = []
        for item in items:
            user_p = item.get("user_preferred_partner")
            comp_p = item.get("company_preferred_partner")
            if isinstance(user_p, dict) and user_p.get("_id"):
                partners.append({
                    "partner_id": item["_id"],
                    "rr_user_id": user_p["_id"],
                    "name":       user_p.get("name") or user_p.get("full_name", ""),
                    "type":       "user",
                })
            elif isinstance(comp_p, dict) and comp_p.get("_id"):
                partners.append({
                    "partner_id":    item["_id"],
                    "rr_company_id": comp_p["_id"],
                    "name":          comp_p.get("name", ""),
                    "type":          "company",
                })
        return {"partners": partners}


# ── Company workers proxy ─────────────────────────────────────────────────────

@router.get("/company-workers", summary="Get LP's workers from RR")
async def get_company_workers(
    rr_token: str = Query("", description="LP's RR session token"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Proxies GET /get_company_workers?company_id=<lp_rr_company_id>
    Used to populate the RR Ops worker dropdown.
    Returns {rr_user_id, name, phone, position} per worker.
    """
    from app.models import UserOrganization
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    lp_rr_company_id = user_org.organization.rr_company_id if user_org.organization else None
    if not lp_rr_company_id:
        return {"workers": []}

    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/get_company_workers",
            params={"company_id": lp_rr_company_id},
            headers=headers,
        )
        if resp.status_code != 200:
            logger.error(f"RR company-workers returned {resp.status_code}: {resp.text[:200]}")
            raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
        data = resp.json()
        raw = data if isinstance(data, list) else data.get("workers", [])
        # Enrich with local DB UUID so the fulfill endpoint can use it
        from app.models.user import User as UserModel
        workers = []
        for w in raw:
            rr_uid = str(w.get("user_id", ""))
            if not rr_uid:
                continue
            local_user = db.query(UserModel).filter(
                UserModel.rr_company_id == rr_uid
            ).first()
            workers.append({
                "rr_user_id":    rr_uid,
                "local_user_id": str(local_user.id) if local_user else None,
                "name":          w.get("name", ""),
                "phone":         w.get("phone", ""),
                "position":      w.get("position", ""),
            })
        return {"workers": workers}


# ── Partner companies proxy ───────────────────────────────────────────────────

@router.get("/partner-companies", summary="Get RR companies linked to a preferred partner user")
async def get_partner_companies(
    user_id: str = Query(..., description="RR user ObjectId of the preferred partner"),
    rr_token: str = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Proxies GET /get_user_companies?user_id=<id>
    Called after the LP selects a preferred partner — returns the companies that partner belongs to.
    LP then picks one as the consignor/consignee company (rr_company_id).
    """
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/get_user_companies",
            params={"user_id": user_id},
            headers=headers,
        )
        if resp.status_code != 200:
            logger.error(f"RR partner-companies returned {resp.status_code}: {resp.text[:200]}")
            raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
        items = resp.json().get("_items", [])
        return {
            "companies": [
                {
                    "rr_company_id": c.get("_id", ""),
                    "name":          c.get("name", ""),
                }
                for c in items
                if c.get("_id")
            ]
        }


# ── Sync readiness list ───────────────────────────────────────────────────────

def _check_trip_readiness(trip: Trip, db: Session) -> dict:
    """
    Check whether a trip has all required RR IDs for sync.
    Returns {ready: bool, missing: [field_names]}.

    If the trip already has rr_parcel_id, it is already in RR — skip ID checks
    entirely (create_trip was already called successfully). Only trips not yet
    in RR need the full pre-flight check.
    """
    # Trip already created in RR — just needs more data pushed, always ready.
    if trip.rr_parcel_id:
        return {"ready": True, "missing": []}

    # Must match the pre-flight in rr_sync_service.sync_all_to_rr exactly (6 fields).
    # lp_org.rr_company_id, vehicle, and driver are no longer required for sync.
    missing = []

    # Consignor: prefer direct field, fall back to load owner org lookup
    consignor_ok = bool(trip.consignor_rr_company_id)
    if not consignor_ok and trip.load_owner_org_id:
        lo_org = db.query(Organization).filter(Organization.id == trip.load_owner_org_id).first()
        consignor_ok = bool(lo_org and lo_org.rr_company_id)
    if not consignor_ok:
        missing.append("consignor_rr_company_id")

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
    - ready: trips that have all required RR IDs and are not yet fully synced
    - missing_data: trips that are missing some RR IDs
    Excludes only pod_synced trips (fully complete).
    loading_slip_synced and bilty_synced are included because S3/S5 may still need pushing.
    """
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    # All ongoing trips in LP's org that aren't fully synced
    syncable_statuses = ("not_synced", "failed", "trip_created", "loading_slip_synced", "bilty_synced")
    trips = (
        db.query(Trip)
        .filter(
            Trip.organization_id == user_org.organization_id,
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

        if trip.rr_sync_status in ("pod_synced",):
            skipped.append({"trip_id": trip_id, "trip_number": trip.trip_number,
                            "reason": f"already synced ({trip.rr_sync_status})"})
            continue

        # Reset failed so sync retries
        if trip.rr_sync_status == "failed":
            trip.rr_sync_status = "not_synced"
            trip.rr_sync_error = None

        background_tasks.add_task(rr_sync_service.sync_all_to_rr, trip_id)
        queued.append({"trip_id": trip_id, "trip_number": trip.trip_number})

    db.commit()

    return {
        "message": f"{len(queued)} trip(s) queued for sync",
        "queued":  queued,
        "skipped": skipped,
    }
