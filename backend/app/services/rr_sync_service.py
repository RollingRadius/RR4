"""
RR Sync Service
Syncs RR4 trips one-way to RollingRadius (RR).

Single entry point: sync_all_to_rr(trip_id)
Called as a BackgroundTask from:
  - POST /api/rr/sync/trip/{id}  (LP dashboard sync sheet or TripStagesScreen AppBar)
  - POST /api/rr/sync/bulk       (bulk sync, uses global RR_REFRESH_TOKEN)

Flow:
  1. If trip not yet in RR → Phase 5 auto-resolve IDs + pre-flight + POST /create_trip
  2. Sync loading slip if not yet done
  3. Sync S3 data (bilty number + weight receipt + material docs) if available
  4. Sync S5 POD if available
"""

import json
import logging
import mimetypes
from datetime import datetime
from pathlib import Path

import httpx

from app.config import settings
from app.services import rr_token_service

logger = logging.getLogger(__name__)


# ── Low-level helpers ─────────────────────────────────────────────────────────

def _auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _json_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def _local_path(upload_url: str) -> Path:
    """Convert /uploads/trips/{id}/file.jpg → absolute local path."""
    rel = upload_url.removeprefix("/uploads/")
    return Path(settings.UPLOAD_DIR) / rel


async def _upload_file(upload_url: str, client: httpx.AsyncClient, token: str) -> str | None:
    """
    Upload a local file to RR /files endpoint.
    Returns the RR file ObjectId string, or None on any failure.
    """
    local_path = _local_path(upload_url)
    if not local_path.exists():
        logger.warning(f"[RR Sync] File not found locally: {local_path}")
        return None

    filename = local_path.name
    mime_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"

    try:
        with open(local_path, "rb") as f:
            resp = await client.post(
                f"{settings.RR_API_BASE}/files",
                files={"file": (filename, f, mime_type)},
                data={"file_name": filename},
                headers=_auth_header(token),
            )
    except Exception as exc:
        logger.error(f"[RR Sync] /files upload exception for {filename}: {exc}")
        return None

    if resp.status_code not in (200, 201):
        logger.error(f"[RR Sync] /files upload failed ({resp.status_code}): {resp.text[:200]}")
        return None

    rr_file_id = resp.json().get("_id")
    if not rr_file_id:
        logger.error(f"[RR Sync] /files response missing _id: {resp.text[:100]}")
    return rr_file_id


async def _fetch_parcel_etag(rr_parcel_id: str, client: httpx.AsyncClient, token: str) -> str | None:
    """Fetch the current _etag of an RR parcel. Must be called before every PATCH."""
    try:
        resp = await client.get(
            f"{settings.RR_API_BASE}/parcels/{rr_parcel_id}",
            headers=_auth_header(token),
        )
        if resp.status_code == 200:
            return resp.json().get("_etag")
        logger.error(f"[RR Sync] GET parcel etag failed ({resp.status_code}): {resp.text[:200]}")
    except Exception as exc:
        logger.error(f"[RR Sync] GET parcel etag exception: {exc}")
    return None


# ── Phase 5: Auto-resolve vehicle / driver RR IDs ────────────────────────────

async def _try_resolve_rr_ids(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Query RR to find rr_vehicle_id (by vehicle_number/rc_number) and
    rr_user_id (by driver phone). Saves results to DB if found.
    Silently skips on any failure — pre-flight will catch still-missing IDs.
    """
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver

    # ── Vehicle lookup ────────────────────────────────────────────────────────
    if trip.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
        if vehicle and not vehicle.rr_vehicle_id and vehicle.vehicle_number:
            where = json.dumps({"rc_number": vehicle.vehicle_number})
            try:
                resp = await client.get(
                    f"{settings.RR_API_BASE}/vehicles",
                    params={"where": where, "max_results": 1},
                    headers=_auth_header(token),
                )
                if resp.status_code == 200:
                    items = resp.json().get("_items", [])
                    if items:
                        vehicle.rr_vehicle_id = str(items[0]["_id"])
                        db.commit()
                        logger.info(
                            f"[RR Sync] Resolved rr_vehicle_id={vehicle.rr_vehicle_id} "
                            f"for vehicle {vehicle.vehicle_number}"
                        )
                    else:
                        logger.warning(
                            f"[RR Sync] No RR vehicle found for rc_number={vehicle.vehicle_number}"
                        )
            except Exception as exc:
                logger.warning(f"[RR Sync] Vehicle RR ID resolution failed: {exc}")

    # ── Driver lookup ─────────────────────────────────────────────────────────
    if trip.driver_id:
        driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
        if driver and not driver.rr_user_id and driver.phone:
            # RR stores phone as integer 10-digit number
            raw = driver.phone.strip().lstrip("+")
            phone_10 = raw[-10:] if len(raw) >= 10 else raw
            if phone_10.isdigit():
                where = json.dumps({"phone.number": int(phone_10)})
                try:
                    resp = await client.get(
                        f"{settings.RR_API_BASE}/users",
                        params={"where": where, "max_results": 1},
                        headers=_auth_header(token),
                    )
                    if resp.status_code == 200:
                        items = resp.json().get("_items", [])
                        if items:
                            driver.rr_user_id = str(items[0]["_id"])
                            db.commit()
                            logger.info(
                                f"[RR Sync] Resolved rr_user_id={driver.rr_user_id} "
                                f"for driver phone {phone_10}"
                            )
                        else:
                            logger.warning(
                                f"[RR Sync] No RR user found for phone.number={phone_10}"
                            )
                except Exception as exc:
                    logger.warning(f"[RR Sync] Driver RR ID resolution failed: {exc}")


# ── Stage 2: Loading slip ─────────────────────────────────────────────────────

async def _sync_loading_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """Upload loading slip to RR /files then POST /post_loading_slip."""
    if not trip.s2_loading_slip_url:
        return

    rr_file_id = await _upload_file(trip.s2_loading_slip_url, client, token)
    if not rr_file_id:
        return

    try:
        resp = await client.post(
            f"{settings.RR_API_BASE}/post_loading_slip",
            json={"trip_id": trip.rr_trip_id, "loading_slip": rr_file_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        logger.error(f"[RR Sync] post_loading_slip exception: {exc}")
        return

    if resp.status_code in (200, 201):
        trip.rr_sync_status = "loading_slip_synced"
        trip.rr_synced_at = datetime.utcnow()
        db.commit()
        logger.info(
            f"[RR Sync] Trip {trip.trip_number} loading slip synced (rr_file_id={rr_file_id})"
        )
    else:
        logger.error(
            f"[RR Sync] post_loading_slip failed ({resp.status_code}): {resp.text[:300]}"
        )


# ── Stage 3: Bilty + weight receipt + material docs ───────────────────────────

async def _sync_stage3(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    PATCH the RR parcel with Stage 3 documents:
      - documents.bilty              — bilty number string
      - documents.weight_receipt     — loaded weight kg + slip photo
      - documents.consignor_invoice  — first 2 material doc photos
    Also attaches bilty photo to trip_documents (type "Bilty") if present.
    """
    if not trip.rr_parcel_id:
        logger.warning(f"[RR Sync S3] Trip {trip.trip_number} has no rr_parcel_id — skipping")
        return

    etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
    if not etag:
        logger.error(f"[RR Sync S3] Cannot fetch parcel etag for trip {trip.trip_number}")
        return

    documents: dict = {}

    # ── Bilty number ──────────────────────────────────────────────────────────
    if trip.bilty_number:
        documents["bilty"] = trip.bilty_number

    # ── Weight receipt ────────────────────────────────────────────────────────
    weight_receipt: dict = {}
    if trip.s3_loaded_truck_weight_kg:
        try:
            weight_receipt["truck_weight_after_loading"] = float(trip.s3_loaded_truck_weight_kg)
        except (ValueError, TypeError):
            pass
    if trip.s3_loaded_weight_slip_url:
        rr_slip_id = await _upload_file(trip.s3_loaded_weight_slip_url, client, token)
        if rr_slip_id:
            weight_receipt["photos"] = [{"photo": rr_slip_id, "side": "Front"}]
    if weight_receipt:
        documents["weight_receipt"] = weight_receipt

    # ── Consignor invoice (material docs — max 2) ─────────────────────────────
    if trip.s3_material_doc_urls:
        try:
            mat_urls = (
                json.loads(trip.s3_material_doc_urls)
                if isinstance(trip.s3_material_doc_urls, str)
                else trip.s3_material_doc_urls
            )
        except Exception:
            mat_urls = []
        photos = []
        for url in mat_urls[:2]:
            rr_file_id = await _upload_file(url, client, token)
            if rr_file_id:
                photos.append({"photo": rr_file_id, "side": "Front"})
        if photos:
            documents["consignor_invoice"] = {"photos": photos}

    # ── PATCH parcel ──────────────────────────────────────────────────────────
    if not documents:
        logger.info(f"[RR Sync S3] Trip {trip.trip_number} — no S3 data to sync, skipping")
        return

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
            json={"documents": documents},
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        logger.error(f"[RR Sync S3] PATCH parcel exception: {exc}")
        return

    if patch_resp.status_code not in (200, 201):
        logger.error(
            f"[RR Sync S3] PATCH parcel failed ({patch_resp.status_code}): {patch_resp.text[:300]}"
        )
        return

    # Store updated etag from response
    new_etag = patch_resp.json().get("_etag", etag)
    trip.rr_parcel_etag = new_etag
    trip.rr_sync_status = "bilty_synced"
    trip.rr_synced_at = datetime.utcnow()
    db.commit()
    logger.info(
        f"[RR Sync S3] Trip {trip.trip_number} Stage 3 synced → parcel {trip.rr_parcel_id}"
    )

    # ── Bilty photo → trip_documents (type "Bilty") ───────────────────────────
    # Requires a separate PATCH on the trip (not the parcel).
    if trip.s3_bilty_url and trip.rr_trip_id:
        await _attach_bilty_photo_to_trip(trip, client, token, db)


async def _attach_bilty_photo_to_trip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Upload bilty photo and append it to the RR trip's trip_documents array.
    Requires GET trip for current trip_documents + etag, then PATCH.
    """
    # Fetch current trip record for etag + existing trip_documents
    try:
        t_resp = await client.get(
            f"{settings.RR_API_BASE}/trips/{trip.rr_trip_id}",
            headers=_auth_header(token),
        )
        if t_resp.status_code != 200:
            logger.warning(
                f"[RR Sync S3] GET trip for bilty attachment failed ({t_resp.status_code})"
            )
            return
        t_data = t_resp.json()
        trip_etag = t_data.get("_etag")
        trip_documents = t_data.get("trip_documents", []) or []
    except Exception as exc:
        logger.warning(f"[RR Sync S3] GET trip exception during bilty attachment: {exc}")
        return

    rr_bilty_id = await _upload_file(trip.s3_bilty_url, client, token)
    if not rr_bilty_id:
        return

    trip_documents.append({
        "document": "Bilty",
        "photos": [{"photo": rr_bilty_id, "side": "Front"}],
    })

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/trips/{trip.rr_trip_id}",
            json={"trip_documents": trip_documents},
            headers={**_json_header(token), "If-Match": trip_etag},
        )
        if patch_resp.status_code in (200, 201):
            logger.info(
                f"[RR Sync S3] Bilty photo attached to RR trip {trip.rr_trip_id} "
                f"(rr_file_id={rr_bilty_id})"
            )
        else:
            logger.warning(
                f"[RR Sync S3] Bilty photo PATCH failed ({patch_resp.status_code}): "
                f"{patch_resp.text[:200]}"
            )
    except Exception as exc:
        logger.warning(f"[RR Sync S3] Bilty photo PATCH exception: {exc}")


# ── Stage 5: POD ──────────────────────────────────────────────────────────────

async def _sync_stage5(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """PATCH the RR parcel with the POD photo in documents.pod.photos."""
    if not trip.rr_parcel_id:
        logger.warning(f"[RR Sync S5] Trip {trip.trip_number} has no rr_parcel_id — skipping")
        return

    if not trip.s5_pod_url:
        return

    etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
    if not etag:
        logger.error(f"[RR Sync S5] Cannot fetch parcel etag for trip {trip.trip_number}")
        return

    rr_pod_id = await _upload_file(trip.s5_pod_url, client, token)
    if not rr_pod_id:
        logger.error(f"[RR Sync S5] POD file upload failed for trip {trip.trip_number}")
        return

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
            json={"documents": {"pod": {"photos": [{"photo": rr_pod_id, "side": "Front"}]}}},
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        logger.error(f"[RR Sync S5] PATCH parcel exception: {exc}")
        return

    if patch_resp.status_code in (200, 201):
        trip.rr_sync_status = "pod_synced"
        trip.rr_parcel_etag = patch_resp.json().get("_etag", etag)
        trip.rr_synced_at = datetime.utcnow()
        db.commit()
        logger.info(
            f"[RR Sync S5] Trip {trip.trip_number} POD synced → parcel {trip.rr_parcel_id}"
        )
    else:
        logger.error(
            f"[RR Sync S5] PATCH parcel failed ({patch_resp.status_code}): {patch_resp.text[:300]}"
        )


# ── Top-level entry point (sync button) ──────────────────────────────────────────

async def sync_all_to_rr(trip_id: str, rr_token: str | None = None) -> None:
    """
    Background task: sync ALL available trip data to RR in one shot.
    Called by the manual sync button on the trip screen.

    rr_token: LP's RR access token (from POST /auth/login). If None, falls back
              to the global token service (used by bulk sync).

    Sequence:
      1. If trip not yet in RR → run full create_trip flow (Phase 5 auto-resolve + pre-flight)
      2. Sync loading slip if not yet done
      3. Sync S3 data (bilty, weight receipt, material docs) if available and not yet synced
      4. Sync S5 POD if available and not yet synced
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
            logger.warning(f"[RR Sync All] Trip {trip_id} not found")
            return

        token = rr_token or rr_token_service.get_access_token()
        if not token:
            trip.rr_sync_status = "failed"
            trip.rr_sync_error = (
                "RR access token not available — set RR_REFRESH_TOKEN and RR_SYNC_ENABLED=true"
            )
            db.commit()
            logger.error(f"[RR Sync All] No RR token for trip {trip.trip_number}")
            return

        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:

            # ── Step 1: Create trip in RR if not yet done ─────────────────────
            if not trip.rr_parcel_id:
                # Phase 5: auto-resolve IDs
                await _try_resolve_rr_ids(trip, client, token, db)
                db.refresh(trip)

                # Pre-flight
                missing = []
                consignor_rr_id = None
                if trip.load_owner_org_id:
                    lo_org = db.query(Organization).filter(
                        Organization.id == trip.load_owner_org_id
                    ).first()
                    consignor_rr_id = lo_org.rr_company_id if lo_org else None
                if not consignor_rr_id:
                    missing.append("load_owner_org.rr_company_id")

                lp_org = db.query(Organization).filter(
                    Organization.id == trip.organization_id
                ).first()
                vehicle_provider_rr_id = lp_org.rr_company_id if lp_org else None
                if not vehicle_provider_rr_id:
                    missing.append("lp_org.rr_company_id")

                rr_vehicle_id = None
                if trip.vehicle_id:
                    vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first()
                    rr_vehicle_id = vehicle.rr_vehicle_id if vehicle else None
                if not rr_vehicle_id:
                    missing.append("vehicle.rr_vehicle_id")

                rr_driver_id = None
                if trip.driver_id:
                    driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
                    rr_driver_id = driver.rr_user_id if driver else None
                if not rr_driver_id:
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

                if missing:
                    trip.rr_sync_status = "failed"
                    trip.rr_sync_error = f"Missing required RR fields: {', '.join(missing)}"
                    db.commit()
                    logger.warning(
                        f"[RR Sync All] Trip {trip.trip_number} blocked: {trip.rr_sync_error}"
                    )
                    return

                # Map RR4 weight units to RR's QuantityUnit enum values
                _unit_map = {"TONS": "TONNES", "KG": "KILOGRAMS", "QUINTAL": "TONNES"}
                rr_weight_unit = _unit_map.get((trip.weight_unit or "").upper(), "TONNES")

                payload = {
                    "consignor_company_id": consignor_rr_id,
                    "material":             trip.material_rr_id,
                    "vehicle_id":           rr_vehicle_id,
                    "driver_id":            rr_driver_id,
                    "vehicle_provider_id":  vehicle_provider_rr_id,
                    "pickup_city":          trip.origin_rr_city_id,
                    "unload_city":          trip.destination_rr_city_id,
                    "weight":               float(trip.weight_value),
                    "weight_unit":          rr_weight_unit,
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
                        pass

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
                    logger.error(
                        f"[RR Sync All] create_trip exception for {trip.trip_number}: {exc}"
                    )
                    return

                if create_resp.status_code not in (200, 201):
                    trip.rr_sync_status = "failed"
                    trip.rr_sync_error = (
                        f"create_trip HTTP {create_resp.status_code}: {create_resp.text[:500]}"
                    )
                    db.commit()
                    logger.error(
                        f"[RR Sync All] create_trip failed for {trip.trip_number}: "
                        f"{create_resp.text[:300]}"
                    )
                    return

                resp_data = create_resp.json()
                rr_trip_id   = str(resp_data.get("trip_id", ""))
                rr_parcel_id = str(resp_data.get("parcel_id", ""))

                if not rr_trip_id or not rr_parcel_id:
                    trip.rr_sync_status = "failed"
                    trip.rr_sync_error = (
                        f"create_trip response missing trip_id/parcel_id: "
                        f"{create_resp.text[:300]}"
                    )
                    db.commit()
                    return

                rr_trip_number = None
                try:
                    t_resp = await client.get(
                        f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                        headers=_auth_header(token),
                    )
                    if t_resp.status_code == 200:
                        rr_trip_number = t_resp.json().get("trip_number")
                except Exception:
                    pass

                rr_parcel_etag = await _fetch_parcel_etag(rr_parcel_id, client, token)

                trip.rr_trip_id     = rr_trip_id
                trip.rr_trip_number = rr_trip_number
                trip.rr_parcel_id   = rr_parcel_id
                trip.rr_parcel_etag = rr_parcel_etag
                trip.rr_sync_status = "trip_created"
                trip.rr_sync_error  = None
                trip.rr_synced_at   = datetime.utcnow()
                db.commit()
                logger.info(
                    f"[RR Sync All] Trip {trip.trip_number} → RR {rr_trip_number} "
                    f"(trip_id={rr_trip_id}, parcel_id={rr_parcel_id})"
                )

            # ── Step 2: Sync loading slip if not yet done ─────────────────────
            if trip.rr_sync_status in ("trip_created",) and trip.s2_loading_slip_url:
                await _sync_loading_slip(trip, client, token, db)

            # ── Step 3: Sync S3 data if available and not yet done ────────────
            if trip.rr_sync_status not in ("bilty_synced", "pod_synced"):
                has_s3 = any([
                    trip.s3_loaded_truck_weight_kg,
                    trip.s3_loaded_weight_slip_url,
                    trip.bilty_number,
                    trip.s3_bilty_url,
                    trip.s3_material_doc_urls,
                ])
                if has_s3:
                    await _sync_stage3(trip, client, token, db)

            # ── Step 4: Sync S5 POD if available and not yet done ────────────
            if trip.rr_sync_status != "pod_synced" and trip.s5_pod_url:
                await _sync_stage5(trip, client, token, db)

    except Exception as exc:
        logger.exception(f"[RR Sync All] Unexpected error for trip {trip_id}: {exc}")
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


