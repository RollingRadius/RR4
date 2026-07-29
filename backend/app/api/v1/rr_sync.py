"""
RR Sync API
Proxy endpoints for RR city/material resolution and sync status queries.
All endpoints require authentication — RR details are never exposed to the client.
"""

import json
import logging
from datetime import datetime
from typing import List

import httpx
import mimetypes

from fastapi import APIRouter, BackgroundTasks, Depends, Form, HTTPException, Query, Response, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.models.company import Organization
from app.models.trip import Trip
from app.models.user import User
from app.services.rr_sync_service import _json_header

logger = logging.getLogger(__name__)
router = APIRouter()

# Only LP owners and RR-ops workers may authenticate to RR / drive sync. LP-workers
# (and drivers/transporters) can submit stage data locally but must never obtain or
# use an RR session — enforced here, not just hidden in the Flutter UI.
_RR_SESSION_ROLES = ('logistic_partner', 'lp_rr_operations', 'super_admin')


def _require_rr_session_role(current_user: User, db: Session) -> None:
    from app.models import UserOrganization
    from app.models.role import Role

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    role = db.query(Role).filter(Role.id == user_org.role_id).first()
    role_key = role.role_key if role else ''
    if role_key not in _RR_SESSION_ROLES:
        raise HTTPException(
            status_code=403,
            detail="Only Logistic Partner owners or RR Ops workers can sign in to / sync with RR",
        )


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
    rr_token: str = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Proxy to RR GET /material_types endpoint.
    Returns a list of {rr_material_id, name} matches for the given prefix.
    rr_token required on RR 3.6 (prod) where material_types is not public.
    """
    import json
    params: dict = {"max_results": 20}
    if q:
        params["where"] = json.dumps({"name": {"$regex": f"^{q}", "$options": "i"}})
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/material_types",
                params=params,
                headers=headers,
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Proxy to RR GET /persons/authenticate (Basic Auth).
    Returns a short-lived RR access token for use in the sync endpoint.
    RR credentials are never stored — they are used once to obtain a token.
    """
    if not settings.RR_SYNC_ENABLED:
        raise HTTPException(status_code=503, detail="RR sync is disabled on this server")

    _require_rr_session_role(current_user, db)

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
    refresh_token = data.get("refresh_token")

    user_record   = data.get("user_record") or {}
    rr_user_id    = str(user_record.get("_id",     "")) if user_record else ""
    company_raw   = user_record.get("current_company") if user_record else None
    # current_company may be a plain ObjectId string or an embedded dict
    if isinstance(company_raw, dict):
        rr_company_id = str(company_raw.get("_id", ""))
    elif company_raw:
        rr_company_id = str(company_raw)
    else:
        rr_company_id = ""

    # Auto-populate on first RR login (never overwrite once set).
    needs_commit = False
    if rr_user_id and not current_user.rr_company_id:
        current_user.rr_company_id = rr_user_id
        needs_commit = True

    from app.models import UserOrganization
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if rr_company_id and user_org and user_org.organization and not user_org.organization.rr_company_id:
        user_org.organization.rr_company_id = rr_company_id
        needs_commit = True
    if needs_commit:
        db.commit()

    # Persist this session on the org so background stage-sync tasks can reuse it
    # (LP or RR-ops signing in is what unblocks any pending/auth_required stage syncs).
    if user_org and user_org.organization and refresh_token:
        from app.services.rr_org_token_service import store_org_rr_session
        store_org_rr_session(
            user_org.organization, db, token, refresh_token, current_user.id
        )

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

    _require_rr_session_role(current_user, db)

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


class RrSyncRetryRequest(BaseModel):
    rr_token: str | None = None
    rr_refresh_token: str | None = None


@router.post("/sync/retry/{trip_id}", summary="Sync all completed stages of a trip to RR")
async def retry_stage_sync(
    trip_id: str,
    body: RrSyncRetryRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    LP/RR-ops calls this (via the trip's "Sync to RR" action) to push every
    stage submitted so far. Stages no longer auto-sync as they're submitted —
    this is the single sync trigger, so it attempts every stage up to
    current_stage regardless of prior status (not just previously-failed ones).
    If a fresh RR token is supplied, it's persisted onto the org first.
    """
    from app.models import UserOrganization

    _require_rr_session_role(current_user, db)

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

    if body.rr_token and body.rr_refresh_token:
        from app.services.rr_org_token_service import store_org_rr_session
        store_org_rr_session(
            user_org.organization, db, body.rr_token, body.rr_refresh_token, current_user.id
        )

    from app.services.rr_sync_service import sync_stage
    stages_to_sync = [s for s in (1, 2, 3, 4, 5) if s <= (trip.current_stage or 0)]
    for stage in stages_to_sync:
        background_tasks.add_task(sync_stage, str(trip.id), stage)

    return {
        "message": f"Syncing {len(stages_to_sync)} stage(s) to RR" if stages_to_sync
                   else "No stages completed yet — nothing to sync",
        "trip_id": str(trip.id),
        "synced_stages": stages_to_sync,
    }


@router.get("/identity-status/{trip_id}", summary="Check driver/vehicle doc sync status against RR")
async def get_identity_status(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    For the trip's driver + vehicle, reports each of the 8 tracked Stage 1 doc
    types: whether WE have pushed it (ours_synced, from local tracking columns)
    and whether RR already has ANY entry for that id_name (rr_has_entry) — which
    may be a different document than ours, since our auto-sync skips pushing
    when RR already has an entry rather than silently overwriting it. Use
    /identity-override to explicitly replace RR's copy with ours after preview.
    """
    from app.models import UserOrganization
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver
    from app.services.rr_sync_service import driver_doc_items, vehicle_doc_items
    from app.services.rr_org_token_service import get_org_rr_token

    _require_rr_session_role(current_user, db)

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

    token = await get_org_rr_token(user_org.organization, db)
    if not token:
        raise HTTPException(status_code=409, detail="RR login required — ask LP or RR Ops to sign in to RR")

    vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first() if trip.vehicle_id else None
    driver  = db.query(Driver).filter(Driver.id == trip.driver_id).first()   if trip.driver_id  else None

    # Prefer the local Driver/Vehicle row; fall back to the RR-picker id with
    # the trip itself as the cache entity when no local row exists — same
    # resolution as _sync_stage1_docs, so status shown here matches what a
    # sync/retry would actually do.
    driver_entity, driver_rr_id = (
        (driver, driver.rr_user_id) if driver and driver.rr_user_id
        else (trip, trip.rr_driver_id) if trip.rr_driver_id
        else (None, None)
    )
    vehicle_entity, vehicle_rr_id = (
        (vehicle, vehicle.rr_vehicle_id) if vehicle and vehicle.rr_vehicle_id
        else (trip, trip.rr_vehicle_id) if trip.rr_vehicle_id
        else (None, None)
    )

    results = []
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=20) as client:
        auth_hdr = {"Authorization": f"Bearer {token}"}

        if driver_entity is not None:
            rr_entries: dict = {}
            try:
                resp = await client.get(f"{settings.RR_API_BASE}/users/{driver_rr_id}", headers=auth_hdr)
                if resp.status_code == 200:
                    for entry in (resp.json().get("identities") or []):
                        name = entry.get("id_name")
                        photos = entry.get("photos") or []
                        if name and photos:
                            rr_entries[name] = str(photos[0].get("photo"))
            except Exception:
                pass
            for item in driver_doc_items(trip):
                results.append({
                    "entity_type": "driver",
                    "id_name": item["id_name"],
                    "ours_synced": bool(getattr(driver_entity, item["front_attr"])),
                    "rr_has_entry": item["id_name"] in rr_entries,
                    "rr_file_id": rr_entries.get(item["id_name"]),
                })

        if vehicle_entity is not None:
            rr_entries: dict = {}
            try:
                resp = await client.get(f"{settings.RR_API_BASE}/vehicles/{vehicle_rr_id}", headers=auth_hdr)
                if resp.status_code == 200:
                    for entry in (resp.json().get("identities") or []):
                        name = entry.get("id_name")
                        photos = entry.get("photos") or []
                        if name and photos:
                            rr_entries[name] = str(photos[0].get("photo"))
            except Exception:
                pass
            for item in vehicle_doc_items(trip):
                results.append({
                    "entity_type": "vehicle",
                    "id_name": item["id_name"],
                    "ours_synced": bool(getattr(vehicle_entity, item["front_attr"])),
                    "rr_has_entry": item["id_name"] in rr_entries,
                    "rr_file_id": rr_entries.get(item["id_name"]),
                })

    return {"items": results}


@router.get("/file-preview/{rr_file_id}", summary="Proxy an RR file's content for preview")
async def get_rr_file_preview(
    rr_file_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Proxies GET {RR_API_BASE}/files/{id} using the org's RR session and decodes
    Eve's base64 media response into raw bytes, so the Flutter app can just do
    Image.network(...) against this URL with no RR auth handling of its own.
    """
    import base64
    from app.models import UserOrganization
    from app.services.rr_org_token_service import get_org_rr_token

    _require_rr_session_role(current_user, db)

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    token = await get_org_rr_token(user_org.organization, db)
    if not token:
        raise HTTPException(status_code=409, detail="RR login required — ask LP or RR Ops to sign in to RR")

    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=20) as client:
            resp = await client.get(
                f"{settings.RR_API_BASE}/files/{rr_file_id}",
                headers={"Authorization": f"Bearer {token}"},
            )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Could not reach RR server: {exc}")

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR /files returned {resp.status_code}")

    data = resp.json()
    file_b64 = data.get("file")
    if not file_b64:
        raise HTTPException(status_code=502, detail="RR /files response missing file content")

    try:
        file_bytes = base64.b64decode(file_b64)
    except Exception:
        raise HTTPException(status_code=502, detail="RR /files content could not be decoded")

    content_type = data.get("content_type") or "application/octet-stream"
    return Response(content=file_bytes, media_type=content_type)


class RrIdentityOverrideRequest(BaseModel):
    trip_id: str
    entity_type: str   # "driver" | "vehicle"
    id_name: str


@router.post("/identity-override", summary="Force-replace an RR driver/vehicle doc with ours")
async def override_identity(
    body: RrIdentityOverrideRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Deliberate human action (LP/RR-ops, after previewing what RR already has via
    /identity-status + /file-preview): removes RR's existing identities[] entry
    for this id_name and replaces it with our copy. Auto-sync never does this on
    its own — _push_identities always skips on conflict to avoid silently
    clobbering RR's data.
    """
    from app.models import UserOrganization
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver
    from app.services.rr_sync_service import driver_doc_items, vehicle_doc_items, _override_identity
    from app.services.rr_org_token_service import get_org_rr_token

    _require_rr_session_role(current_user, db)

    if body.entity_type not in ("driver", "vehicle"):
        raise HTTPException(status_code=400, detail="entity_type must be 'driver' or 'vehicle'")

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    trip = db.query(Trip).filter(
        Trip.id == body.trip_id,
        Trip.organization_id == user_org.organization_id,
    ).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    token = await get_org_rr_token(user_org.organization, db)
    if not token:
        raise HTTPException(status_code=409, detail="RR login required — ask LP or RR Ops to sign in to RR")

    if body.entity_type == "driver":
        local_driver = db.query(Driver).filter(Driver.id == trip.driver_id).first() if trip.driver_id else None
        if local_driver and local_driver.rr_user_id:
            entity, rr_id = local_driver, local_driver.rr_user_id
        elif trip.rr_driver_id:
            entity, rr_id = trip, trip.rr_driver_id
        else:
            raise HTTPException(status_code=422, detail="Driver not found in RR")
        entity_collection = "users"
        items = {i["id_name"]: i for i in driver_doc_items(trip)}
    else:
        local_vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first() if trip.vehicle_id else None
        if local_vehicle and local_vehicle.rr_vehicle_id:
            entity, rr_id = local_vehicle, local_vehicle.rr_vehicle_id
        elif trip.rr_vehicle_id:
            entity, rr_id = trip, trip.rr_vehicle_id
        else:
            raise HTTPException(status_code=422, detail="Vehicle not found in RR")
        entity_collection = "vehicles"
        items = {i["id_name"]: i for i in vehicle_doc_items(trip)}

    item = items.get(body.id_name)
    if not item:
        raise HTTPException(status_code=400, detail=f"Unknown id_name: {body.id_name}")

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
        ok, err = await _override_identity(entity, entity_collection, rr_id, item, client, token, db)

    if not ok:
        raise HTTPException(status_code=502, detail=err)

    return {"success": True, "id_name": body.id_name}


def _extract_gstin(obj: dict) -> str:
    """Extract GSTIN from an RR identities array (id_name == 'GST')."""
    for identity in (obj.get("identities") or []):
        if isinstance(identity, dict) and identity.get("id_name") == "GST":
            return identity.get("number", "") or ""
    return ""


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
                raw_addrs = user_p.get("postal_addresses") or []
                addresses = []
                for addr in (raw_addrs if isinstance(raw_addrs, list) else []):
                    city = addr.get("city") if isinstance(addr.get("city"), dict) else {}
                    addresses.append({
                        "address_line_1": addr.get("address_line_1", ""),
                        "address_line_2": addr.get("address_line_2", ""),
                        "pin":            addr.get("pin", ""),
                        "no_entry_zone":  bool(addr.get("no_entry_zone", False)),
                        "city_id":        city.get("_id", ""),
                        "city_name":      city.get("name", ""),
                    })
                partners.append({
                    "partner_id":       item["_id"],
                    "rr_user_id":       user_p["_id"],
                    "name":             user_p.get("name") or user_p.get("full_name", ""),
                    "phone":            user_p.get("phone", ""),
                    "postal_addresses": addresses,
                    "gstin":            _extract_gstin(user_p),
                    "type":             "user",
                })
            elif isinstance(comp_p, dict) and comp_p.get("_id"):
                partners.append({
                    "partner_id":       item["_id"],
                    "rr_company_id":    comp_p["_id"],
                    "name":             comp_p.get("name", ""),
                    "phone":            "",
                    "postal_addresses": [],
                    "gstin":            _extract_gstin(comp_p),
                    "type":             "company",
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
                    "gstin":         _extract_gstin(c),
                }
                for c in items
                if c.get("_id")
            ]
        }


# ── Operation locations proxy ─────────────────────────────────────────────────

@router.get("/operation-locations", summary="Get company's operation locations from RR")
async def get_operation_locations(
    company_id: str = Query(..., description="RR company ObjectId"),
    rr_token: str = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Proxies GET /operation_locations?embedded={"city":1,"state":1}&where={"company":"<id>"}
    Called when a company-type partner is selected or a company is chosen from the dropdown,
    to populate the consignor/consignee address selector.
    """
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/operation_locations",
            params={
                "where":    json.dumps({"company": company_id}),
                "embedded": json.dumps({"city": 1, "state": 1}),
            },
            headers=headers,
        )
        if resp.status_code != 200:
            logger.error(f"RR operation-locations returned {resp.status_code}: {resp.text[:200]}")
            raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
        items = resp.json().get("_items", [])
        locations = []
        for loc in items:
            city = loc.get("city") if isinstance(loc.get("city"), dict) else {}
            locations.append({
                "address_line_1": loc.get("address_line_1", ""),
                "address_line_2": loc.get("address_line_2", ""),
                "pin":            loc.get("pin", ""),
                "no_entry_zone":  bool(loc.get("no_entry_zone", False)),
                "city_id":        city.get("_id", ""),
                "city_name":      city.get("name", ""),
            })
        return {"locations": locations}


# ── Vehicle-provider helpers ──────────────────────────────────────────────────

def _extract_vehicle_entry(v: dict, source: str) -> dict | None:
    """
    Build a normalised vehicle dict from a /vehicles or /market_vehicles item.
    For market_vehicles the actual vehicle doc is embedded in v["vehicle_id"].
    Also extracts the driver from crew (position == "Driver") if crew is embedded.
    """
    if source == "market_vehicles":
        actual = v.get("vehicle_id") if isinstance(v.get("vehicle_id"), dict) else {}
        if not actual.get("_id"):
            return None
        rr_id      = str(actual["_id"])
        identities = actual.get("identities") or []
        body_type  = actual.get("body_type", "")
        crew       = actual.get("crew") or []
        engine     = actual.get("engine") or {}
    else:
        if not v.get("_id"):
            return None
        rr_id      = str(v["_id"])
        identities = v.get("identities") or []
        body_type  = v.get("body_type", "")
        crew       = v.get("crew") or []
        engine     = v.get("engine") or {}

    number = next(
        (i.get("number", "") for i in identities if isinstance(i, dict) and i.get("number")),
        ""
    )
    model_name = (engine.get("model") or {}).get("name") or "" if isinstance(engine, dict) else ""

    # Extract driver from crew
    driver_id   = ""
    driver_name = ""
    for member in crew:
        if not isinstance(member, dict):
            continue
        if member.get("position") == "Driver":
            worker = member.get("worker")
            if isinstance(worker, dict):          # embedded user document
                driver_id   = str(worker.get("_id") or "")
                driver_name = worker.get("name") or ""
            elif worker:                           # raw ObjectId string
                driver_id = str(worker)
            break

    return {
        "rr_vehicle_id": rr_id,
        "number":        number,
        "model_name":    model_name,
        "body_type":     body_type,
        "source":        source,
        "driver_id":     driver_id,
        "driver_name":   driver_name,
    }


@router.get("/vehicle-provider-user", summary="Look up a vehicle provider (transporter) by phone in RR")
async def get_vehicle_provider_user(
    phone: str = Query(..., description="Phone number of the transporter"),
    rr_token: str = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Proxies GET /users/get_user_by_phone → returns {"_items": [{...}]}.
    Returns {user_id, name} so the frontend can load companies + vehicles.
    """
    raw = phone.strip().lstrip("+")
    phone_10 = raw[-10:] if len(raw) >= 10 else raw
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/users/get_user_by_phone",
            params={"phone_number": phone_10, "username": phone_10},
            headers=headers,
        )
    if resp.status_code not in (200,):
        raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
    # Response shape: {"_items": [{_id, name, phone, ...}]}
    items = resp.json().get("_items", [])
    if not items:
        raise HTTPException(status_code=404, detail="No RR user found for this phone number")
    user = items[0]
    return {
        "user_id": str(user.get("_id") or ""),
        "name":    user.get("name") or "",
    }


@router.get("/user-vehicles", summary="Get vehicles directly owned by an RR user (no company)")
async def get_user_vehicles(
    user_id: str  = Query(..., description="RR user ObjectId"),
    rr_token: str = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Proxies GET /vehicles?where={"$and":[{"created_by":"<id>","$or":[...no company...]}]}
    Returns vehicles personally created by the user (not linked to a company).
    """
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    where = json.dumps({"$and": [
        {
            "created_by": user_id,
            "$or": [
                {"created_by_company": {"$eq": None}},
                {"created_by_company": {"$exists": False}},
            ],
        }
    ]})
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/vehicles",
            params={
                "where":      where,
                "embedded":   json.dumps({"engine.model": 1, "created_by": 1, "crew.worker": 1}),
                "sort":       json.dumps([("_created", -1)]),
                "max_results": 300000,
            },
            headers=headers,
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
    vehicles = []
    for v in resp.json().get("_items", []):
        entry = _extract_vehicle_entry(v, "vehicles")
        if entry:
            vehicles.append(entry)
    return {"vehicles": vehicles}


@router.get("/company-vehicles", summary="Get vehicles linked to an RR company")
async def get_company_vehicles(
    company_id: str = Query(..., description="RR company ObjectId"),
    rr_token: str   = Query("", description="LP's RR session token"),
    _: User = Depends(get_current_user),
):
    """
    Combines:
    - GET /vehicles?where={"$and":[{"created_by_company":"<id>"}]}  (owned fleet)
    - GET /market_vehicles?where={"$and":[{"third_party_company_id":"<id>"},{"status":"Approved"},…]}
    Returns a deduplicated vehicle list.
    """
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    vehicles: list[dict] = []

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        # ── Owned fleet vehicles ──────────────────────────────────────────────
        try:
            resp = await client.get(
                f"{settings.RR_API_BASE}/vehicles",
                params={
                    "where":      json.dumps({"$and": [{"created_by_company": company_id}]}),
                    "embedded":   json.dumps({"engine.model": 1, "travel_locations.city": 1,
                                              "travel_locations.state": 1, "created_by": 1,
                                              "crew.worker": 1}),
                    "sort":       json.dumps([("_created", -1)]),
                    "max_results": 300000,
                },
                headers=headers,
            )
            if resp.status_code == 200:
                for v in resp.json().get("_items", []):
                    entry = _extract_vehicle_entry(v, "vehicles")
                    if entry:
                        vehicles.append(entry)
        except Exception as exc:
            logger.warning(f"[company-vehicles] /vehicles failed: {exc}")

        # ── Market vehicles (third-party, approved) ───────────────────────────
        try:
            resp = await client.get(
                f"{settings.RR_API_BASE}/market_vehicles",
                params={
                    "where": json.dumps({"$and": [
                        {"third_party_company_id": company_id},
                        {"status": "Approved"},
                        {"approved_start_date": {"$exists": True, "$ne": None}},
                        {"approved_end_date":   {"$exists": True, "$ne": None}},
                    ]}),
                    "embedded":   json.dumps({"vehicle_id": 1, "vehicle_id.engine.model": 1,
                                              "vehicle_id.crew.worker": 1,
                                              "third_party_company_id": 1}),
                    "max_results": 300000,
                },
                headers=headers,
            )
            if resp.status_code == 200:
                for v in resp.json().get("_items", []):
                    entry = _extract_vehicle_entry(v, "market_vehicles")
                    if entry:
                        vehicles.append(entry)
        except Exception as exc:
            logger.warning(f"[company-vehicles] /market_vehicles failed: {exc}")

    # deduplicate by rr_vehicle_id
    seen: set[str] = set()
    unique = []
    for v in vehicles:
        if v["rr_vehicle_id"] not in seen:
            seen.add(v["rr_vehicle_id"])
            unique.append(v)
    return {"vehicles": unique}


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


# ── Complete Trip (calls POST /create_trip on RR) ────────────────────────────

_RR_DEFAULT_VEHICLE_PROVIDER = "62d66794e54f47829a886a1d"  # Rolling Radius LP company

_RR_UNITS = {"TONNES", "KILOGRAMS", "LITRES", "BOX", "CUBIC METERS"}
_UNIT_MAP  = {"TONS": "TONNES", "KG": "KILOGRAMS", "QUINTAL": "TONNES"}


class RrCompleteTripRequest(BaseModel):
    rr_token: str


async def _do_create_trip_in_rr(trip, rr_token: str, db) -> dict:
    """
    Core POST /create_trip logic. Auto-resolves vehicle/driver/provider IDs,
    calls RR, saves results back to trip.
    Raises ValueError for missing required fields, RuntimeError for RR API errors.
    """
    from datetime import datetime as _dt
    from app.models.user import User as UserModel
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver

    auth_hdr = {"Authorization": f"Bearer {rr_token}"}

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:

        # ── Resolve vehicle RR ID ─────────────────────────────────────────────
        rr_vehicle_id = None
        rr_vehicle_company_id = None  # company_id from RR vehicle (overrides transporter phone lookup)

        # Path A: directly selected via picker (already resolved — no lookup needed)
        if trip.rr_vehicle_id:
            rr_vehicle_id = trip.rr_vehicle_id
            # vehicle_provider_id comes from transporter_rr_company_id set during selection

        # Path B: fleet vehicle linked to trip
        elif trip.vehicle_id:
            vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
            if vehicle:
                rr_vehicle_id = vehicle.rr_vehicle_id
                if not rr_vehicle_id and vehicle.vehicle_number:
                    try:
                        resp = await client.get(
                            f"{settings.RR_API_BASE}/vehicles",
                            params={"where": json.dumps({"identities.number": vehicle.vehicle_number}), "max_results": 1},
                            headers=auth_hdr,
                        )
                        if resp.status_code == 200:
                            items = resp.json().get("_items", [])
                            if items:
                                rr_vehicle_id = str(items[0]["_id"])
                                rr_vehicle_company_id = str(items[0].get("company_id") or "")
                                vehicle.rr_vehicle_id = rr_vehicle_id
                                db.flush()
                                logger.info(f"[Create Trip] Resolved rr_vehicle_id={rr_vehicle_id} for {vehicle.vehicle_number}")
                    except Exception as exc:
                        logger.warning(f"[Create Trip] Vehicle lookup failed: {exc}")

        # Path C: manually entered vehicle number (no fleet link) — lookup by reg number
        if not rr_vehicle_id and trip.vehicle_number:
            try:
                resp = await client.get(
                    f"{settings.RR_API_BASE}/vehicles",
                    params={"where": json.dumps({"identities.number": trip.vehicle_number}), "max_results": 1},
                    headers=auth_hdr,
                )
                if resp.status_code == 200:
                    items = resp.json().get("_items", [])
                    if items:
                        rr_vehicle_id = str(items[0]["_id"])
                        rr_vehicle_company_id = str(items[0].get("company_id") or "")
                        logger.info(f"[Create Trip] Resolved rr_vehicle_id={rr_vehicle_id} for manual number {trip.vehicle_number}")
            except Exception as exc:
                logger.warning(f"[Create Trip] Manual vehicle lookup failed: {exc}")

        if not rr_vehicle_id:
            raise ValueError("No vehicle resolved — select a vehicle via the provider picker or link a fleet vehicle")

        # ── Resolve driver RR user ID ─────────────────────────────────────────
        rr_driver_id = None

        # Path A: directly selected via picker (already resolved)
        if trip.rr_driver_id:
            rr_driver_id = trip.rr_driver_id

        # Path B: fleet driver linked
        elif trip.driver_id:
            driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
            if driver:
                rr_driver_id = driver.rr_user_id
                if not rr_driver_id and driver.phone:
                    raw = driver.phone.strip().lstrip("+")
                    phone_10 = raw[-10:] if len(raw) >= 10 else raw
                    if phone_10.isdigit():
                        try:
                            resp = await client.get(
                                f"{settings.RR_API_BASE}/users",
                                params={"where": json.dumps({"phone.number": int(phone_10)}), "max_results": 1},
                                headers=auth_hdr,
                            )
                            if resp.status_code == 200:
                                items = resp.json().get("_items", [])
                                if items:
                                    rr_driver_id = str(items[0]["_id"])
                                    driver.rr_user_id = rr_driver_id
                                    db.flush()
                                    logger.info(f"[Create Trip] Resolved rr_driver_id={rr_driver_id} for phone {phone_10}")
                        except Exception as exc:
                            logger.warning(f"[Create Trip] Driver lookup failed: {exc}")

        # ── Resolve vehicle_provider_id (prefer vehicle's own company_id) ───────
        # vehicle lookup already gave us the company — use it first
        vehicle_provider_id = rr_vehicle_company_id or trip.transporter_rr_company_id
        if not vehicle_provider_id and trip.transporter_user_id:
            transporter = db.query(UserModel).filter(UserModel.id == trip.transporter_user_id).first()
            if transporter and transporter.phone:
                raw = transporter.phone.strip().lstrip("+")
                phone_10 = raw[-10:] if len(raw) >= 10 else raw
                if phone_10.isdigit():
                    try:
                        # Step 1: get RR user_id by phone (response: {"_items": [{_id, name, ...}]})
                        r1 = await client.get(
                            f"{settings.RR_API_BASE}/users/get_user_by_phone",
                            params={"phone_number": phone_10, "username": phone_10},
                            headers=auth_hdr,
                        )
                        rr_user_id = None
                        if r1.status_code == 200:
                            items = r1.json().get("_items", [])
                            if items:
                                rr_user_id = str(items[0].get("_id") or "")
                        # Step 2: get companies for that user
                        if rr_user_id:
                            r2 = await client.get(
                                f"{settings.RR_API_BASE}/get_user_companies",
                                params={"user_id": rr_user_id},
                                headers=auth_hdr,
                            )
                            if r2.status_code == 200:
                                companies = r2.json().get("_items", [])
                                if companies:
                                    company_id = str(companies[0].get("_id") or "")
                                    if company_id:
                                        vehicle_provider_id = company_id
                                        trip.transporter_rr_company_id = vehicle_provider_id
                                        db.flush()
                                        logger.info(f"[Create Trip] Resolved vehicle_provider_id={vehicle_provider_id} for transporter phone {phone_10}")
                    except Exception as exc:
                        logger.warning(f"[Create Trip] Transporter company lookup failed: {exc}")
        vehicle_provider_id = vehicle_provider_id or _RR_DEFAULT_VEHICLE_PROVIDER

    # ── Pre-flight checks ─────────────────────────────────────────────────────
    missing = []
    if not trip.consignor_rr_company_id:           missing.append("consignor_rr_company_id")
    if not trip.origin_rr_city_id:                 missing.append("origin_rr_city_id")
    if not trip.destination_rr_city_id:            missing.append("destination_rr_city_id")
    if not trip.material_rr_id:                    missing.append("material_rr_id")
    if not trip.weight_value:                      missing.append("weight_value")
    if not trip.weight_unit:                       missing.append("weight_unit")
    if not trip.invoice_value:                     missing.append("invoice_value")
    if not trip.expected_freight or float(trip.expected_freight) <= 0:
        missing.append("expected_freight (freight amount must be > 0)")
    if not trip.booking_amount or float(trip.booking_amount) <= 0:
        missing.append("booking_amount (LP offline bid price must be > 0)")
    if not (trip.rr_vehicle_id or trip.vehicle_id or trip.vehicle_number): missing.append("vehicle (select via provider picker)")
    if not rr_driver_id: missing.append("driver (no driver linked to selected vehicle — ensure vehicle has a driver assigned in RR)")
    if missing:
        raise ValueError(f"Missing required fields: {', '.join(missing)}")

    # ── Map weight unit to RR enum ────────────────────────────────────────────
    raw_unit = (trip.weight_unit or "").strip().upper()
    rr_weight_unit = raw_unit if raw_unit in _RR_UNITS else _UNIT_MAP.get(raw_unit, "TONNES")

    # ── Build create_trip payload ─────────────────────────────────────────────
    payload: dict = {
        "consignor_company_id":       trip.consignor_rr_company_id,
        "vehicle_provider_id":        vehicle_provider_id,
        "pickup_city":                trip.origin_rr_city_id,
        "unload_city":                trip.destination_rr_city_id,
        "material":                   trip.material_rr_id,
        "weight":                     float(trip.weight_value),
        "weight_unit":                rr_weight_unit,
        "freight_amount":             float(trip.expected_freight or 0),
        "invoice_value":              float(trip.invoice_value),
        "booking_amount":             float(trip.booking_amount or 0),
        "loading_amount":             0,
        "unloading_amount":           0,
        "advance_amount":             0,
        "diesel_charges":             0,
        "back_entry_date":            trip.created_at.strftime("%Y-%m-%dT%H:%M:%S"),
        "force_create":               True,
        "data_entry":                 True,
        "consignor_address_1":        trip.pickup_address_line1 or None,
        "consignor_address_pin_code": int(trip.pickup_pin) if trip.pickup_pin and trip.pickup_pin.isdigit() else None,
        "consignee_address_1":        trip.unload_address_line1 or None,
        "consignee_address_pin_code": int(trip.unload_pin) if trip.unload_pin and trip.unload_pin.isdigit() else None,
    }
    if trip.consignee_rr_company_id: payload["consignee_company_id"] = trip.consignee_rr_company_id
    if rr_vehicle_id:                payload["vehicle_id"]           = rr_vehicle_id
    if rr_driver_id:                 payload["driver_id"]            = rr_driver_id

    # ── Call RR POST /create_trip ─────────────────────────────────────────────
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=60) as client:
            resp = await client.post(
                f"{settings.RR_API_BASE}/create_trip",
                json=payload,
                headers={"Authorization": f"Bearer {rr_token}", "Content-Type": "application/json"},
            )
    except Exception as exc:
        raise RuntimeError(f"Could not reach RR server: {exc}")

    if resp.status_code not in (200, 201):
        raise RuntimeError(f"RR create_trip failed ({resp.status_code}): {resp.text[:300]}")

    data          = resp.json()
    rr_trip_id    = data.get("trip_id")
    rr_parcel_id  = data.get("parcel_id")
    rr_booking_id = str(data.get("booking_id")) if data.get("booking_id") else None

    if not rr_trip_id:
        raise RuntimeError(f"RR create_trip missing trip_id: {resp.text[:200]}")

    # ── Fetch trip_number + parcel etag from RR ───────────────────────────────
    rr_trip_number = None
    rr_parcel_etag = None
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
        try:
            tr = await client.get(
                f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                headers={"Authorization": f"Bearer {rr_token}"},
            )
            if tr.status_code == 200:
                rr_trip_number = tr.json().get("trip_number")
        except Exception:
            pass
        if rr_parcel_id:
            try:
                pr = await client.get(
                    f"{settings.RR_API_BASE}/parcels/{rr_parcel_id}",
                    headers={"Authorization": f"Bearer {rr_token}"},
                )
                if pr.status_code == 200:
                    rr_parcel_etag = pr.json().get("_etag")
            except Exception:
                pass

    # ── Guard: ensure no other trip already owns this rr_trip_id ─────────────
    existing = db.query(Trip).filter(
        Trip.rr_trip_id == rr_trip_id,
        Trip.id != trip.id,
    ).first()
    if existing:
        raise RuntimeError(
            f"rr_trip_id {rr_trip_id} is already linked to trip "
            f"{existing.trip_number} — possible RR deduplication collision"
        )

    # ── Save back to trip ─────────────────────────────────────────────────────
    trip.rr_trip_id     = rr_trip_id
    trip.rr_trip_number = rr_trip_number
    trip.rr_parcel_id   = rr_parcel_id
    trip.rr_parcel_etag = rr_parcel_etag
    trip.rr_booking_id  = rr_booking_id
    trip.rr_sync_status = "trip_created"
    trip.rr_sync_error  = None
    trip.rr_synced_at   = _dt.utcnow()
    db.commit()

    logger.info(
        f"[Create Trip] {trip.trip_number} -> rr_trip_id={rr_trip_id}, "
        f"rr_trip_number={rr_trip_number}, parcel_id={rr_parcel_id}, booking_id={rr_booking_id}"
    )
    return {
        "rr_trip_id":     rr_trip_id,
        "rr_trip_number": rr_trip_number,
        "rr_parcel_id":   rr_parcel_id,
        "rr_booking_id":  rr_booking_id,
    }


@router.post("/complete-trip/{trip_id}", summary="Push trip to RR via POST /create_trip")
async def complete_trip_in_rr(
    trip_id: str,
    body: RrCompleteTripRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Calls _do_create_trip_in_rr after auth + ownership checks."""
    from app.models import UserOrganization

    _require_rr_session_role(current_user, db)

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
    if trip.rr_trip_id:
        raise HTTPException(status_code=409, detail="Trip already exists in RR")

    try:
        result = await _do_create_trip_in_rr(trip, body.rr_token, db)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except RuntimeError as exc:
        trip.rr_sync_status = "failed"
        trip.rr_sync_error  = str(exc)[:500]
        db.commit()
        raise HTTPException(status_code=503, detail=str(exc))

    return {
        "success":       True,
        "trip_number":   trip.trip_number,
        "rr_trip_id":    result["rr_trip_id"],
        "rr_parcel_id":  result["rr_parcel_id"],
        "rr_booking_id": result["rr_booking_id"],
    }



# ── Loading slip upload ───────────────────────────────────────────────────────

@router.post("/sync/loading-slip/{trip_id}", summary="Upload loading slip to RR")
async def post_loading_slip(
    trip_id: str,
    file: UploadFile,
    rr_token: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Accepts a loading slip image from the mobile app:
    1. Saves the file to local storage (uploads/trips/{trip_id}/)
    2. Uploads it to RR /files → gets rr_file_id
    3. Calls RR /post_loading_slip
    4. Persists rr_loading_slip_url, rr_loading_slip_file_id, rr_sync_status
    """
    import uuid as _uuid_mod
    import datetime as _dt
    from pathlib import Path
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
    if not trip.rr_trip_id:
        raise HTTPException(status_code=409, detail="Trip has not been synced to RR yet")

    file_bytes = await file.read()
    orig_name  = file.filename or "loading_slip.jpg"
    ext        = Path(orig_name).suffix or ".jpg"
    mime_type  = file.content_type or mimetypes.guess_type(orig_name)[0] or "image/jpeg"

    # ── Step 1: save locally ──────────────────────────────────────────────────
    trip_dir  = Path(settings.UPLOAD_DIR) / "trips" / trip_id
    trip_dir.mkdir(parents=True, exist_ok=True)
    local_name = f"rr_loading_slip_{_uuid_mod.uuid4().hex[:8]}{ext}"
    (trip_dir / local_name).write_bytes(file_bytes)
    local_url = f"/uploads/trips/{trip_id}/{local_name}"

    auth_hdr = {"Authorization": f"Bearer {rr_token}"}

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
        # ── Step 2: upload to RR /files ───────────────────────────────────────
        try:
            files_resp = await client.post(
                f"{settings.RR_API_BASE}/files",
                files={"file": (local_name, file_bytes, mime_type)},
                data={"file_name": local_name},
                headers=auth_hdr,
            )
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"RR /files upload failed: {exc}")

        if files_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"RR /files returned {files_resp.status_code}: {files_resp.text[:200]}",
            )

        rr_file_id = files_resp.json().get("_id")
        if not rr_file_id:
            raise HTTPException(status_code=502, detail="RR /files response missing _id")

        # ── Step 3: call RR /post_loading_slip ────────────────────────────────
        try:
            slip_resp = await client.post(
                f"{settings.RR_API_BASE}/post_loading_slip",
                json={"trip_id": trip.rr_trip_id, "loading_slip": rr_file_id},
                headers={**auth_hdr, "Content-Type": "application/json"},
            )
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"RR /post_loading_slip failed: {exc}")

        if slip_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"RR /post_loading_slip returned {slip_resp.status_code}: {slip_resp.text[:200]}",
            )

    # ── Step 4: persist to DB ─────────────────────────────────────────────────
    trip.rr_loading_slip_url     = local_url
    trip.rr_loading_slip_file_id = rr_file_id
    trip.s2_loading_slip_url     = local_url   # also set stage field for consistency
    trip.rr_sync_status          = "loading_slip_synced"
    trip.rr_synced_at            = _dt.datetime.utcnow()
    db.commit()

    logger.info(
        f"[Loading Slip] {trip.trip_number} -> local={local_url}, "
        f"rr_file_id={rr_file_id}, status=loading_slip_synced"
    )

    return {"success": True, "rr_file_id": rr_file_id, "local_url": local_url, "trip": trip.to_dict()}


@router.post("/sync/loading-slip-from-local/{trip_id}", summary="Sync LP Worker's loading slip to RR")
async def sync_loading_slip_from_local(
    trip_id: str,
    rr_token: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    RR Ops / LP Owner triggers sync of a loading slip already saved locally by LP Worker.
    1. Reads file from trip.rr_loading_slip_url on disk
    2. Uploads to RR /files → gets rr_file_id
    3. Calls RR /post_loading_slip
    4. Updates rr_loading_slip_file_id, rr_sync_status = loading_slip_synced
    """
    import datetime as _dt
    from pathlib import Path
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
    if not trip.rr_trip_id:
        raise HTTPException(status_code=409, detail="Trip has not been synced to RR yet")
    if not trip.rr_loading_slip_url:
        raise HTTPException(status_code=409, detail="No loading slip uploaded yet. LP Worker must upload first.")

    file_path = Path(settings.UPLOAD_DIR) / trip.rr_loading_slip_url[len("/uploads/"):]
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Loading slip file not found on server")

    file_bytes = file_path.read_bytes()
    file_name  = file_path.name
    mime_type  = mimetypes.guess_type(file_name)[0] or "image/jpeg"
    auth_hdr   = {"Authorization": f"Bearer {rr_token}"}

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
        try:
            files_resp = await client.post(
                f"{settings.RR_API_BASE}/files",
                files={"file": (file_name, file_bytes, mime_type)},
                data={"file_name": file_name},
                headers=auth_hdr,
            )
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"RR /files upload failed: {exc}")

        if files_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"RR /files returned {files_resp.status_code}: {files_resp.text[:200]}",
            )

        rr_file_id = files_resp.json().get("_id")
        if not rr_file_id:
            raise HTTPException(status_code=502, detail="RR /files response missing _id")

        try:
            slip_resp = await client.post(
                f"{settings.RR_API_BASE}/post_loading_slip",
                json={"trip_id": trip.rr_trip_id, "loading_slip": rr_file_id},
                headers={**auth_hdr, "Content-Type": "application/json"},
            )
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"RR /post_loading_slip failed: {exc}")

        if slip_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"RR /post_loading_slip returned {slip_resp.status_code}: {slip_resp.text[:200]}",
            )

    trip.rr_loading_slip_file_id = rr_file_id
    trip.s2_loading_slip_url     = trip.rr_loading_slip_url
    trip.rr_sync_status          = "loading_slip_synced"
    trip.rr_synced_at            = _dt.datetime.utcnow()
    db.commit()

    logger.info(
        f"[Loading Slip From Local] {trip.trip_number} -> rr_file_id={rr_file_id}, status=loading_slip_synced"
    )

    return {"success": True, "rr_file_id": rr_file_id, "status": "loading_slip_synced", "trip": trip.to_dict()}


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


# ── Quick-add: Vehicle / Company / User directly on RR ───────────────────────
# LP/RR-ops sidebar shortcuts (mirrors rr_kanpur's Add Vehicle/Add Company/Add
# User screens) — these write straight to RR, not into RR4's local DB, since
# there's nothing for RR4 to do with this data offline. Search endpoints power
# each screen's typeahead fields; create endpoints do the actual POST to RR.

@router.get("/users/search", summary="Search RR users by phone prefix or name (typeahead)")
async def search_rr_users(
    q: str = Query(..., min_length=1, description="Phone number prefix or name substring"),
    rr_token: str = Query("", description="LP's RR session token"),
    drivers_only: bool = Query(
        False,
        description="If true, restrict results to driver-role users "
                     "(plus untagged legacy users) — used by the trip driver picker. "
                     "Other callers (vehicle owner / company contact / hire-person "
                     "search) must leave this false so non-driver users aren't excluded.",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    # RR's generic `GET /users?where=...` (Eve resource GET) is restricted
    # server-side to the querying token's own record (`auth_field` self-only —
    # confirmed live: even an Admin/CSR token searching for a known, existing
    # user gets back an empty result). RR's own web app never queries /users
    # directly for this reason — it uses this dedicated endpoint instead,
    # which runs its own unrestricted DB lookup (rrbc-api/app/users/app.py:
    # get_user_by_phone). It only does an EXACT phone match (no prefix), so
    # pass q as both phone_number and name to cover "typed a full phone" and
    # "typed part of a name" in one call — RR tries phone first, falls back
    # to name-substring if that misses.
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/users/get_user_by_phone",
            params={"phone_number": q, "name": q},
            headers=headers,
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
    items = []
    for u in resp.json().get("_items", []):
        # This endpoint's projection doesn't include `user_type`, so
        # drivers_only can't be filtered server-side here — return all
        # matches rather than silently hiding real drivers.
        items.append({
            "user_id": str(u.get("_id") or ""),
            "name": u.get("name") or "",
            "phone": (u.get("phone") or {}).get("number") or "",
        })
    return {"items": items}


@router.get("/companies/search", summary="Search RR companies by name (typeahead)")
async def search_rr_companies(
    q: str = Query(..., min_length=1, description="Company name prefix"),
    rr_token: str = Query("", description="LP's RR session token"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    match = json.dumps({"name": {"$regex": f"^{q}", "$options": "-i"}})
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/get_all_companies",
            params={"page": 1, "max_results": 5, "sort": '("_created",-1)', "match": match},
            headers=headers,
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
    body = resp.json()
    raw_items = body.get("_items") if isinstance(body, dict) else body
    items = []
    for c in (raw_items or []):
        items.append({"company_id": str(c.get("_id") or ""), "name": c.get("name") or ""})
    return {"items": items}


@router.get("/vehicle-engine-models/search", summary="Search RR vehicle engine models (typeahead)")
async def search_vehicle_engine_models(
    q: str = Query(..., min_length=1, description="Engine model name prefix"),
    rr_token: str = Query("", description="LP's RR session token"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    where = json.dumps({"name": {"$regex": f"^{q}", "$options": "i"}})
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.get(
            f"{settings.RR_API_BASE}/vehicle_engine_models",
            params={"where": where, "max_results": 10},
            headers=headers,
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR API error {resp.status_code}")
    items = []
    for m in resp.json().get("_items", []):
        items.append({"engine_model_id": str(m.get("_id") or ""), "name": m.get("name") or ""})
    return {"items": items}


class RrCreateVehicleRequest(BaseModel):
    rr_token: str
    engine_model_id: str
    rc_number: str
    owner_user_id: str
    company_id: str | None = None


@router.post("/vehicles", summary="Create a new vehicle directly on RR")
async def create_rr_vehicle(
    body: RrCreateVehicleRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    payload = {
        "engine.model": body.engine_model_id,
        "body": {
            "body_type": None,
            "number_of_wheels": 6,
            "carrying_capacity": 19000,
            "capacity_unit": "KG",
            "axle_type": None,
            "body_length_in_feet": None,
            "body_height_in_feet": None,
        },
        "travel_locations": [],
        "created_by": body.owner_user_id,
        "created_by_company": body.company_id,
        "identities": [
            {"id_name": "Registration Certificate", "number": body.rc_number}
        ],
    }
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.post(
            f"{settings.RR_API_BASE}/vehicles",
            json=payload,
            headers=_json_header(body.rr_token),
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"RR vehicle creation failed: {resp.text[:400]}")
    data = resp.json()
    return {"vehicle_id": str(data.get("_id") or ""), "rc_number": body.rc_number}


class RrCreateCompanyRequest(BaseModel):
    rr_token: str
    name: str
    city_id: str
    business_type: str
    owner_user_id: str | None = None
    new_owner_phone: str | None = None


@router.post("/companies", summary="Create a new company (vehicle provider) directly on RR")
async def create_rr_company(
    body: RrCreateCompanyRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    if not body.owner_user_id and not body.new_owner_phone:
        raise HTTPException(status_code=400, detail="Provide either owner_user_id or new_owner_phone")

    payload = {
        "name": body.name,
        "city": body.city_id,
        "business_type": body.business_type,
        "website_address": "",
        "address_line_1": "",
        "pin": "",
        "logo": None,
        # RR's /add_company only reads "owner"/"new_owner" below when a
        # recognized "source" is present (CRM/Dashboard/Trip/MobileApp) —
        # without it, RR silently attributes the company to whoever's
        # logged in instead of the picked/typed owner. rr_kanpur's own
        # payload omits this and has the same gap; we fix it here.
        # Must be the enum VALUE string ("Mobile App", not the Python
        # member name "MobileApp") — verified against a live RR test call.
        "source": "Mobile App",
    }
    if body.owner_user_id:
        payload["owner"] = body.owner_user_id
    else:
        payload["new_owner"] = {"phone": {"number": body.new_owner_phone}}

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.post(
            f"{settings.RR_API_BASE}/add_company",
            json=payload,
            headers=_json_header(body.rr_token),
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"RR company creation failed: {resp.text[:400]}")
    data = resp.json()
    company = data.get("company") if isinstance(data, dict) and "company" in data else data
    return {
        "company_id": str((company or {}).get("_id") or (data.get("_id") if isinstance(data, dict) else "") or ""),
        "name": body.name,
    }


class RrCreateUserRequest(BaseModel):
    rr_token: str
    name: str
    phone: str


@router.post("/users", summary="Create a new user (driver) directly on RR")
async def create_rr_user(
    body: RrCreateUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    payload = {
        "phone": {"country_phone_code": "91", "number": body.phone},
        "name": body.name,
        "password": "",
        # Tags this user as a driver on RR from creation, independent of any
        # trip assignment — lets /users/search filter to drivers only.
        "user_type": "Driver",
    }
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.post(
            f"{settings.RR_API_BASE}/users",
            json=payload,
            headers=_json_header(body.rr_token),
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"RR user creation failed: {resp.text[:400]}")
    data = resp.json()
    return {"user_id": str(data.get("_id") or ""), "name": body.name, "phone": body.phone}


# ── Vehicle hire requests (Market Vehicles — Requested → Approved/Rejected) ────
# We just hit a real trip stuck because a hired (third-party) vehicle's owner
# had never approved the hire request — RR's own booking flow refuses to book
# an unapproved market vehicle, surfacing a confusing unrelated error. This
# lets LP/RR-ops review and approve/reject those requests without leaving the
# app. market_vehicles has no self-only access restriction on RR's side
# (unlike /users), so any authenticated RR token can query/act on it.

def _to_rr_datetime_str(iso_str: str) -> str:
    """
    RR's Eve app pins DATE_FORMAT to "%Y-%m-%dT%H:%M:%S" (see rrbc-api/app/settings.py)
    and rejects anything else — including Dart's default `.toIso8601String()` output,
    which appends milliseconds (e.g. "2026-07-24T00:00:00.000") and 404s/422s as
    "must be of datetime type". Reparse and reformat to RR's exact expected format.
    """
    return datetime.fromisoformat(iso_str).strftime("%Y-%m-%dT%H:%M:%S")


def _resolve_org_rr_company_id(current_user: User, db: Session) -> str:
    from app.models import UserOrganization

    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="User must be in an active organization")

    org = db.query(Organization).filter(Organization.id == user_org.organization_id).first()
    if not org or not org.rr_company_id:
        raise HTTPException(status_code=400, detail="Organization has no linked RR company")
    return org.rr_company_id


class RrCreateHireRequest(BaseModel):
    rr_token: str
    vehicle_id: str
    owner_user_id: str | None = None
    owner_company_id: str | None = None
    hirer_user_id: str | None = None
    hirer_company_id: str | None = None
    requested_start_date: str | None = None
    requested_end_date: str | None = None


@router.post("/vehicle-hire-requests", summary="Request to hire a vehicle on behalf of any hirer")
async def create_vehicle_hire_request(
    body: RrCreateHireRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    The requester side of RR's vehicle-hire marketplace — mirrors RR web's
    "Hire Market Vehicle" dialog (hire-market-vehicle.component.ts) field for
    field: Vehicle Hire Person (hirer) and Vehicle Owner (lender) are both
    independent search fields, exactly like RR web — not implicitly the
    caller's own org, since a privileged RR session (Admin/CSR/CSR
    Supervisor — see get_vehicle_hire_requests above) can hire on behalf of
    any company, same as RR web's own CSR/Admin dashboard.
    """
    _require_rr_session_role(current_user, db)

    if bool(body.owner_user_id) == bool(body.owner_company_id):
        raise HTTPException(status_code=400, detail="Provide exactly one of owner_user_id or owner_company_id")
    if bool(body.hirer_user_id) == bool(body.hirer_company_id):
        raise HTTPException(status_code=400, detail="Provide exactly one of hirer_user_id or hirer_company_id")

    owner_id = body.owner_user_id or body.owner_company_id
    hirer_id = body.hirer_user_id or body.hirer_company_id
    if owner_id == hirer_id:
        raise HTTPException(status_code=400, detail="The hiring person and lender must be different. You cannot hire your own vehicle.")

    payload: dict = {"vehicle_id": body.vehicle_id}
    if body.owner_user_id:
        payload["owner_user_id"] = body.owner_user_id
    if body.owner_company_id:
        payload["owner_company_id"] = body.owner_company_id
    if body.hirer_user_id:
        payload["third_party_user_id"] = body.hirer_user_id
    if body.hirer_company_id:
        payload["third_party_company_id"] = body.hirer_company_id
    if body.requested_start_date:
        payload["requested_start_date"] = _to_rr_datetime_str(body.requested_start_date)
    if body.requested_end_date:
        payload["requested_end_date"] = _to_rr_datetime_str(body.requested_end_date)

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.post(
            f"{settings.RR_API_BASE}/market_vehicles",
            json=payload,
            headers=_json_header(body.rr_token),
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"RR hire request failed: {resp.text[:400]}")
    data = resp.json()
    return {"market_vehicle_id": str(data.get("_id") or ""), "status": "Requested"}


@router.get("/vehicle-hire-requests", summary="List pending hire requests marketplace-wide")
async def get_vehicle_hire_requests(
    rr_token: str = Query("", description="LP's RR session token"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    RR's own `market_vehicles` resource carries no company-level access
    restriction (allowed_roles: RolesAllowedWithAndForUser — see
    rrbc-api/app/enum_directory.py); Admin/CSR/CSR Supervisor RR sessions can
    already see and act on every company's requests, RR web just doesn't
    surface that broader view outside its CSR/Admin-only dashboard table. We
    mirror that broader marketplace list here (any LP/RR-ops session sees
    who's requesting what from whom, own-company requests always included
    regardless of the marketplace cap) and tag each row with `is_mine` as a
    display hint only — the review endpoint below defers to RR's own
    authorization, matching its real per-role access model.
    """
    _require_rr_session_role(current_user, db)
    company_id = _resolve_org_rr_company_id(current_user, db)
    headers = {"Authorization": f"Bearer {rr_token}"} if rr_token else {}
    embedded = json.dumps({
        "vehicle_id": 1,
        "vehicle_id.engine.model": 1,
        "owner_company_id": 1,
        "owner_user_id": 1,
        "third_party_company_id": 1,
        "third_party_user_id": 1,
    })

    def _to_item(mv: dict) -> dict:
        vehicle = mv.get("vehicle_id") if isinstance(mv.get("vehicle_id"), dict) else {}
        rc_number = ""
        for ident in (vehicle.get("identities") or []):
            if ident.get("id_name") == "Registration Certificate":
                rc_number = ident.get("number") or ""
                break
        engine_model = ((vehicle.get("engine") or {}).get("model") or {}).get("name") or ""
        owner = mv.get("owner_company_id") if isinstance(mv.get("owner_company_id"), dict) else None
        if not owner:
            owner = mv.get("owner_user_id") if isinstance(mv.get("owner_user_id"), dict) else {}
        hirer = mv.get("third_party_company_id") if isinstance(mv.get("third_party_company_id"), dict) else None
        if not hirer:
            hirer = mv.get("third_party_user_id") if isinstance(mv.get("third_party_user_id"), dict) else {}
        raw_owner_company_id = mv.get("owner_company_id")
        owner_company_id = raw_owner_company_id.get("_id") if isinstance(raw_owner_company_id, dict) else raw_owner_company_id
        return {
            "market_vehicle_id": str(mv.get("_id") or ""),
            "vehicle_number": rc_number,
            "vehicle_model": engine_model,
            "owner_name": (owner or {}).get("name") or "",
            "hirer_name": (hirer or {}).get("name") or "",
            "requested_start_date": mv.get("requested_start_date"),
            "requested_end_date": mv.get("requested_end_date"),
            "is_mine": str(owner_company_id or "") == company_id,
        }

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        # Own company's requests — never subject to the marketplace cap below,
        # so a busy shared test/prod DB can never bury the requests this user
        # actually needs to act on. Sorted the same as the marketplace query
        # so the merge below produces one newest-first list either way.
        own_resp = await client.get(
            f"{settings.RR_API_BASE}/market_vehicles",
            params={
                "where": json.dumps({"$and": [{"status": "Requested"}, {"owner_company_id": company_id}]}),
                "sort": json.dumps([("_created", -1)]),
                "embedded": embedded,
                "max_results": 300,
            },
            headers=headers,
        )
        if own_resp.status_code != 200:
            raise HTTPException(status_code=502, detail=f"RR API error {own_resp.status_code}: {own_resp.text[:300]}")
        own_mvs = own_resp.json().get("_items", [])
        own_ids = {mv.get("_id") for mv in own_mvs}

        # Rest of the marketplace, newest first.
        rest_resp = await client.get(
            f"{settings.RR_API_BASE}/market_vehicles",
            params={
                "where": json.dumps({"status": "Requested"}),
                "sort": json.dumps([("_created", -1)]),
                "embedded": embedded,
                "max_results": 300,
            },
            headers=headers,
        )
    if rest_resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"RR API error {rest_resp.status_code}: {rest_resp.text[:300]}")

    rest_mvs = [mv for mv in rest_resp.json().get("_items", []) if mv.get("_id") not in own_ids]

    # Merge both newest-first lists into a single newest-first list — own
    # requests are still guaranteed present (never dropped by the marketplace
    # cap), but the combined order still reads newest-on-top, matching RR
    # web's own dashboard table instead of showing "own" as a separate block.
    all_mvs = sorted(own_mvs + rest_mvs, key=lambda mv: mv.get("_created") or "", reverse=True)
    return {"items": [_to_item(mv) for mv in all_mvs]}


class RrReviewHireRequest(BaseModel):
    rr_token: str
    status: str  # "Approved" | "Rejected"
    approved_start_date: str | None = None
    approved_end_date: str | None = None


@router.post("/vehicle-hire-requests/{market_vehicle_id}/review", summary="Approve or reject a vehicle hire request")
async def review_vehicle_hire_request(
    market_vehicle_id: str,
    body: RrReviewHireRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _require_rr_session_role(current_user, db)
    if body.status not in ("Approved", "Rejected"):
        raise HTTPException(status_code=400, detail="status must be 'Approved' or 'Rejected'")
    if body.status == "Approved" and not (body.approved_start_date and body.approved_end_date):
        raise HTTPException(status_code=400, detail="approved_start_date and approved_end_date are required to approve")

    # No ownership check here — RR's own market_vehicles access control
    # (allowed_roles: RolesAllowedWithAndForUser, rrbc-api/app/enum_directory.py)
    # already lets Admin/CSR/CSR Supervisor RR sessions review ANY request
    # regardless of company (confirmed live: a CSR test session successfully
    # rejected a request for a vehicle owned by a company it has no relation
    # to). A plain "User"-role RR session is restricted by RR itself via
    # Eve's auth_field self-ownership check, so RR's own review_market_vehicle_request
    # call below is the real authority — we just forward whatever it decides.
    payload = {"market_vehicle_id": market_vehicle_id, "status": body.status}
    if body.status == "Approved":
        payload["approved_start_date"] = _to_rr_datetime_str(body.approved_start_date)
        payload["approved_end_date"] = _to_rr_datetime_str(body.approved_end_date)

    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
        resp = await client.post(
            f"{settings.RR_API_BASE}/review_market_vehicle_request",
            json=payload,
            headers=_json_header(body.rr_token),
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"RR review failed: {resp.text[:400]}")
    return {"market_vehicle_id": market_vehicle_id, "status": body.status}
