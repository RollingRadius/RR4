"""
RR Sync Service
Syncs RR4 trips to RollingRadius (RR) after Stage 2 completion.

Trigger: called as a FastAPI BackgroundTask after Stage 2 is submitted
         with a loading slip (by LP or Transporter).

Flow:
  1. Pre-flight: validate all required RR ObjectIds are present on the trip.
  2. POST /create_trip on RR → get rr_trip_id + rr_parcel_id.
  3. GET /trips/{rr_trip_id} → get RR trip_number + _etag.
  4. GET /parcels/{rr_parcel_id} → get parcel _etag.
  5. Persist rr_trip_id, rr_trip_number, rr_parcel_id, rr_parcel_etag.
  6. If loading slip file exists → upload to RR /files → POST /post_loading_slip.
"""

import logging
from datetime import datetime
from pathlib import Path

import httpx

from app.config import settings
from app.services import rr_token_service

logger = logging.getLogger(__name__)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _json_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def _local_path(upload_url: str) -> Path:
    """
    Convert a stored URL like /uploads/trips/{id}/file.jpg
    to the actual local file path using UPLOAD_DIR.
    """
    rel = upload_url.removeprefix("/uploads/")   # "trips/{id}/file.jpg"
    return Path(settings.UPLOAD_DIR) / rel


# ── Loading slip helper ───────────────────────────────────────────────────────

async def _sync_loading_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """Upload loading slip to RR /files then POST /post_loading_slip."""
    if not trip.s2_loading_slip_url:
        return

    local_path = _local_path(trip.s2_loading_slip_url)
    if not local_path.exists():
        logger.warning(f"[RR Sync] Loading slip file not found locally: {local_path}")
        return

    filename = local_path.name

    # Upload file bytes to RR
    try:
        with open(local_path, "rb") as f:
            file_resp = await client.post(
                f"{settings.RR_API_BASE}/files",
                files={"file": (filename, f, "image/jpeg")},
                data={"file_name": filename},
                headers=_auth_header(token),
            )
    except Exception as exc:
        logger.error(f"[RR Sync] /files upload exception: {exc}")
        return

    if file_resp.status_code not in (200, 201):
        logger.error(f"[RR Sync] /files upload failed ({file_resp.status_code}): {file_resp.text[:300]}")
        return

    rr_file_id = file_resp.json().get("_id")
    if not rr_file_id:
        logger.error(f"[RR Sync] /files response missing _id: {file_resp.text[:200]}")
        return

    # Post loading slip reference to RR trip
    try:
        slip_resp = await client.post(
            f"{settings.RR_API_BASE}/post_loading_slip",
            json={"trip_id": trip.rr_trip_id, "loading_slip": rr_file_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        logger.error(f"[RR Sync] post_loading_slip exception: {exc}")
        return

    if slip_resp.status_code in (200, 201):
        trip.rr_sync_status = "loading_slip_synced"
        trip.rr_synced_at = datetime.utcnow()
        db.commit()
        logger.info(f"[RR Sync] Trip {trip.trip_number} loading slip synced (rr_file_id={rr_file_id})")
    else:
        logger.error(
            f"[RR Sync] post_loading_slip failed ({slip_resp.status_code}): {slip_resp.text[:300]}"
        )


# ── Main sync entry point ─────────────────────────────────────────────────────

async def sync_trip_to_rr(trip_id: str) -> None:
    """
    Background task: sync an RR4 trip to RR.
    Creates its own DB session — safe to run as a BackgroundTask.
    """
    if not settings.RR_SYNC_ENABLED:
        return

    from app.database import SessionLocal
    from app.models.trip import Trip
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver
    from app.models.company import Organization

    db = SessionLocal()
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            logger.warning(f"[RR Sync] Trip {trip_id} not found")
            return

        # Already fully synced — skip
        # NOTE: trip_created is NOT in this list — it means trip exists in RR but
        # loading slip not yet pushed. Transporter may upload slip after S2, so we
        # must continue and attempt the loading slip sync.
        if trip.rr_sync_status in ("loading_slip_synced", "bilty_synced", "pod_synced"):
            logger.info(f"[RR Sync] Trip {trip.trip_number} already synced ({trip.rr_sync_status}), skipping")
            return

        # ── Pre-flight: resolve all required RR ObjectIds ─────────────────────
        missing = []

        # Consignor = load owner org
        consignor_rr_id = None
        if trip.load_owner_org_id:
            lo_org = db.query(Organization).filter(Organization.id == trip.load_owner_org_id).first()
            consignor_rr_id = lo_org.rr_company_id if lo_org else None
        if not consignor_rr_id:
            missing.append("load_owner_org.rr_company_id")

        # Vehicle provider = LP org
        lp_org = db.query(Organization).filter(Organization.id == trip.organization_id).first()
        vehicle_provider_rr_id = lp_org.rr_company_id if lp_org else None
        if not vehicle_provider_rr_id:
            missing.append("lp_org.rr_company_id")

        # Vehicle
        rr_vehicle_id = None
        if trip.vehicle_id:
            vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
            rr_vehicle_id = vehicle.rr_vehicle_id if vehicle else None
        if not rr_vehicle_id:
            missing.append("vehicle.rr_vehicle_id")

        # Driver
        rr_driver_id = None
        if trip.driver_id:
            driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
            rr_driver_id = driver.rr_user_id if driver else None
        if not rr_driver_id:
            missing.append("driver.rr_user_id")

        # Cities
        if not trip.origin_rr_city_id:
            missing.append("origin_rr_city_id")
        if not trip.destination_rr_city_id:
            missing.append("destination_rr_city_id")

        # Material
        if not trip.material_rr_id:
            missing.append("material_rr_id")

        # Weight
        if not trip.weight_value:
            missing.append("weight_value")
        if not trip.weight_unit:
            missing.append("weight_unit")

        if missing:
            trip.rr_sync_status = "failed"
            trip.rr_sync_error = f"Missing required RR fields: {', '.join(missing)}"
            db.commit()
            logger.warning(f"[RR Sync] Trip {trip.trip_number} blocked: {trip.rr_sync_error}")
            return

        # ── Get access token ─────────────────────────────────────────────────
        token = rr_token_service.get_access_token()
        if not token:
            trip.rr_sync_status = "failed"
            trip.rr_sync_error = "RR access token not available — set RR_REFRESH_TOKEN and RR_SYNC_ENABLED=true"
            db.commit()
            logger.error(f"[RR Sync] No RR token available for trip {trip.trip_number}")
            return

        # ── Build create_trip payload ─────────────────────────────────────────
        payload = {
            "consignor_company_id": consignor_rr_id,
            "material":             trip.material_rr_id,
            "vehicle_id":           rr_vehicle_id,
            "driver_id":            rr_driver_id,
            "vehicle_provider_id":  vehicle_provider_rr_id,
            "pickup_city":          trip.origin_rr_city_id,
            "unload_city":          trip.destination_rr_city_id,
            "weight":               float(trip.weight_value),
            "weight_unit":          trip.weight_unit,
            "freight_amount":       float(trip.trip_amount or 0),
            "invoice_value":        float(trip.invoice_value or trip.trip_amount or 0),
            "booking_amount":       0.0,
            "back_entry_date":      trip.created_at.date().isoformat(),
            "human_trip_number":    trip.trip_number,
            "force_create":         True,
        }
        if trip.invoice_number:
            payload["invoice_number"] = trip.invoice_number
        if trip.bilty_number:
            try:
                payload["bilty_number"] = int(trip.bilty_number)
            except (ValueError, TypeError):
                pass  # bilty_number not a valid integer — skip

        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:

            # ── Step 1: Create trip in RR ─────────────────────────────────────
            try:
                create_resp = await client.post(
                    f"{settings.RR_API_BASE}/create_trip",
                    json=payload,
                    headers=_json_header(token),
                )
            except Exception as exc:
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = f"create_trip request failed: {exc}"
                db.commit()
                logger.error(f"[RR Sync] create_trip exception for {trip.trip_number}: {exc}")
                return

            if create_resp.status_code not in (200, 201):
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = (
                    f"create_trip HTTP {create_resp.status_code}: {create_resp.text[:500]}"
                )
                db.commit()
                logger.error(f"[RR Sync] create_trip failed for {trip.trip_number}: {create_resp.text[:300]}")
                return

            resp_data = create_resp.json()
            rr_trip_id   = str(resp_data.get("trip_id", ""))
            rr_parcel_id = str(resp_data.get("parcel_id", ""))

            if not rr_trip_id or not rr_parcel_id:
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = f"create_trip response missing trip_id/parcel_id: {create_resp.text[:300]}"
                db.commit()
                return

            # ── Step 2: Fetch trip to get RR trip_number ──────────────────────
            rr_trip_number = None
            try:
                t_resp = await client.get(
                    f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                    headers=_auth_header(token),
                )
                if t_resp.status_code == 200:
                    rr_trip_number = t_resp.json().get("trip_number")
            except Exception:
                pass  # non-fatal — trip_number is cosmetic

            # ── Step 3: Fetch parcel to get _etag ────────────────────────────
            rr_parcel_etag = None
            try:
                p_resp = await client.get(
                    f"{settings.RR_API_BASE}/parcels/{rr_parcel_id}",
                    headers=_auth_header(token),
                )
                if p_resp.status_code == 200:
                    rr_parcel_etag = p_resp.json().get("_etag")
            except Exception:
                pass  # non-fatal — etag fetched fresh before every PATCH anyway

            # ── Step 4: Persist cross-reference IDs ──────────────────────────
            trip.rr_trip_id     = rr_trip_id
            trip.rr_trip_number = rr_trip_number
            trip.rr_parcel_id   = rr_parcel_id
            trip.rr_parcel_etag = rr_parcel_etag
            trip.rr_sync_status = "trip_created"
            trip.rr_sync_error  = None
            trip.rr_synced_at   = datetime.utcnow()
            db.commit()

            logger.info(
                f"[RR Sync] Trip {trip.trip_number} → RR {rr_trip_number} "
                f"(trip_id={rr_trip_id}, parcel_id={rr_parcel_id})"
            )

            # ── Step 5: Sync loading slip if present ──────────────────────────
            if trip.s2_loading_slip_url:
                await _sync_loading_slip(trip, client, token, db)

    except Exception as exc:
        logger.exception(f"[RR Sync] Unexpected error syncing trip {trip_id}: {exc}")
        try:
            trip = db.query(Trip).filter(Trip.id == trip_id).first()
            if trip:
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = f"Unexpected error: {str(exc)[:400]}"
                db.commit()
        except Exception:
            pass
    finally:
        db.close()
