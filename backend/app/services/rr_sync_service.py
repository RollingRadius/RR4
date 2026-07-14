"""
RR Sync Service
Syncs RR4 trips one-way to RollingRadius (RR).

Single entry point: sync_all_to_rr(trip_id)
Called as a BackgroundTask from:
  - POST /api/rr/sync/trip/{id}  (LP dashboard sync sheet or TripStagesScreen AppBar)
  - POST /api/rr/sync/bulk       (bulk sync, uses global RR_REFRESH_TOKEN)

Flow:
  1. Trip must already exist in RR (rr_parcel_id set via POST /api/rr/complete-trip/{id})
  2. Sync loading slip if not yet done
  3. Sync S3 data (bilty number + weight receipt + material docs) if available
  4. Sync S5 POD if available

Note: Trip creation is now done via POST /api/rr/complete-trip/{id} which calls
POST /create_trip on RR web (3.7 branch — JWT bug fixed). The sync button only
pushes document stages (loading slip, S3, S5) after the trip is already in RR.
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
            where = json.dumps({"identities.number": vehicle.vehicle_number})
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


# ── Stage 1: Driver KYC + vehicle compliance docs ─────────────────────────────

async def _push_identities(
    entity,
    entity_collection: str,
    rr_id: str,
    items: list[dict],
    client: httpx.AsyncClient,
    token: str,
    db,
) -> tuple[bool, str | None]:
    """
    Push identity docs into `identities[]` on a `users`/`vehicles` RR record,
    tracking each doc's RR file id locally (on `entity`) so re-submits skip
    straight past docs already pushed instead of re-checking RR every time.

    items: list of {id_name, front_url, back_url, front_attr, back_attr}
    front_attr/back_attr are column names on `entity` that cache the RR file id.
    Returns (success, error_message).
    """
    to_push = [
        it for it in items
        if it["front_url"] and not getattr(entity, it["front_attr"])
    ]
    if not to_push:
        return True, None  # everything already pushed for this driver/vehicle

    try:
        get_resp = await client.get(
            f"{settings.RR_API_BASE}/{entity_collection}/{rr_id}", headers=_auth_header(token)
        )
    except Exception as exc:
        return False, f"GET {entity_collection} exception: {exc}"
    if get_resp.status_code != 200:
        return False, f"GET {entity_collection} HTTP {get_resp.status_code}: {get_resp.text[:300]}"

    data = get_resp.json()
    etag = data.get("_etag")
    identities = data.get("identities") or []
    existing_names = {i.get("id_name") for i in identities}

    new_entries = []
    local_updates: list[tuple[str, str]] = []  # (attr, rr_file_id)
    for it in to_push:
        if it["id_name"] in existing_names:
            continue  # already on RR (pushed via another channel) — nothing to attach locally
        photos = []
        front_id = await _upload_file(it["front_url"], client, token)
        if front_id:
            photos.append({"photo": front_id, "side": "Front"})
            local_updates.append((it["front_attr"], front_id))
        if it["back_url"]:
            back_id = await _upload_file(it["back_url"], client, token)
            if back_id:
                photos.append({"photo": back_id, "side": "Back"})
                if it["back_attr"]:
                    local_updates.append((it["back_attr"], back_id))
        if photos:
            new_entries.append({"id_name": it["id_name"], "photos": photos})

    if not new_entries:
        return True, None

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/{entity_collection}/{rr_id}",
            json={"identities": identities + new_entries},
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        return False, f"PATCH {entity_collection} exception: {exc}"
    if patch_resp.status_code not in (200, 201):
        return False, f"PATCH {entity_collection} HTTP {patch_resp.status_code}: {patch_resp.text[:300]}"

    for attr, file_id in local_updates:
        setattr(entity, attr, file_id)
    db.commit()
    return True, None


async def _sync_stage1_docs(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Push driver KYC docs (DL, Aadhaar, PAN, tax declaration) to users.identities[]
    and vehicle compliance docs (RC, PUC, fitness, permit) to vehicles.identities[].
    Insurance and cancelled cheque have no RR field and are never pushed — same for
    the boolean checklist fields elsewhere in Stage 1-4, which have no RR equivalent.
    """
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver

    if not trip.vehicle_id and not trip.driver_id:
        return  # nothing assigned to this trip yet — leave as not_synced

    await _try_resolve_rr_ids(trip, client, token, db)

    vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first() if trip.vehicle_id else None
    driver  = db.query(Driver).filter(Driver.id == trip.driver_id).first()   if trip.driver_id  else None

    errors: list[str] = []
    attempted = False

    if driver and driver.rr_user_id:
        attempted = True
        ok, err = await _push_identities(driver, "users", driver.rr_user_id, [
            {"id_name": "Driving Licence", "front_url": trip.s1_driving_license_url,
             "back_url": trip.s1_driving_license_back_url,
             "front_attr": "rr_dl_file_id", "back_attr": "rr_dl_back_file_id"},
            {"id_name": "Aadhaar Card", "front_url": trip.s1_aadhaar_url,
             "back_url": trip.s1_aadhaar_back_url,
             "front_attr": "rr_aadhaar_file_id", "back_attr": "rr_aadhaar_back_file_id"},
            {"id_name": "PAN Card", "front_url": trip.s1_pan, "back_url": None,
             "front_attr": "rr_pan_file_id", "back_attr": None},
            {"id_name": "Tax Declaration Slip", "front_url": trip.s1_tax_declaration, "back_url": None,
             "front_attr": "rr_tax_declaration_file_id", "back_attr": None},
        ], client, token, db)
        if not ok:
            errors.append(f"Driver docs: {err}")
    elif trip.driver_id:
        errors.append("Driver not found in RR — driver must exist in RR web first")

    if vehicle and vehicle.rr_vehicle_id:
        attempted = True
        ok, err = await _push_identities(vehicle, "vehicles", vehicle.rr_vehicle_id, [
            {"id_name": "Registration Certificate", "front_url": trip.s1_rc, "back_url": None,
             "front_attr": "rr_rc_file_id", "back_attr": None},
            {"id_name": "PUC Certificate", "front_url": trip.s1_pollution, "back_url": None,
             "front_attr": "rr_puc_file_id", "back_attr": None},
            {"id_name": "Fitness Certificate", "front_url": trip.s1_fitness, "back_url": None,
             "front_attr": "rr_fitness_file_id", "back_attr": None},
            {"id_name": "Permit", "front_url": trip.s1_permit, "back_url": None,
             "front_attr": "rr_permit_file_id", "back_attr": None},
        ], client, token, db)
        if not ok:
            errors.append(f"Vehicle docs: {err}")
    elif trip.vehicle_id:
        errors.append("Vehicle not found in RR — vehicle must exist in RR web first")

    if not attempted and not errors:
        return  # neither vehicle nor driver resolvable yet — nothing to do

    if errors:
        trip.rr_s1_sync_status = "failed"
        trip.rr_s1_sync_error = "; ".join(errors)[:800]
    else:
        trip.rr_s1_sync_status = "synced"
        trip.rr_s1_synced_at = datetime.utcnow()
        trip.rr_s1_sync_error = None
    db.commit()
    logger.info(f"[RR Sync S1] Trip {trip.trip_number} stage1 doc sync: status={trip.rr_s1_sync_status}")


# ── Stage 2: Loading slip ─────────────────────────────────────────────────────

async def _sync_loading_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """Upload loading slip to RR /files then POST /post_loading_slip."""
    if not trip.s2_loading_slip_url:
        return

    if not trip.rr_trip_id:
        logger.info(f"[RR Sync] Trip {trip.trip_number} has no rr_trip_id yet — pending trip creation")
        trip.rr_sync_status = "pending_trip_creation"
        db.commit()
        return

    rr_file_id = await _upload_file(trip.s2_loading_slip_url, client, token)
    if not rr_file_id:
        trip.rr_sync_status = "failed"
        trip.rr_sync_error = "Loading slip file upload to RR failed"
        db.commit()
        return

    try:
        resp = await client.post(
            f"{settings.RR_API_BASE}/post_loading_slip",
            json={"trip_id": trip.rr_trip_id, "loading_slip": rr_file_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        logger.error(f"[RR Sync] post_loading_slip exception: {exc}")
        trip.rr_sync_status = "failed"
        trip.rr_sync_error = f"post_loading_slip exception: {exc}"[:500]
        db.commit()
        return

    if resp.status_code in (200, 201):
        trip.rr_sync_status = "loading_slip_synced"
        trip.rr_synced_at = datetime.utcnow()
        trip.rr_sync_error = None
        db.commit()
        logger.info(
            f"[RR Sync] Trip {trip.trip_number} loading slip synced (rr_file_id={rr_file_id})"
        )
    else:
        logger.error(
            f"[RR Sync] post_loading_slip failed ({resp.status_code}): {resp.text[:300]}"
        )
        trip.rr_sync_status = "failed"
        trip.rr_sync_error = f"HTTP {resp.status_code}: {resp.text[:400]}"
        db.commit()


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
        logger.info(f"[RR Sync S3] Trip {trip.trip_number} has no rr_parcel_id yet — pending trip creation")
        trip.rr_s3_sync_status = "pending_trip_creation"
        db.commit()
        return

    etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
    if not etag:
        logger.error(f"[RR Sync S3] Cannot fetch parcel etag for trip {trip.trip_number}")
        trip.rr_s3_sync_status = "failed"
        trip.rr_s3_sync_error = "Could not fetch parcel etag from RR"
        db.commit()
        return

    documents: dict = {}

    # ── Bilty date ────────────────────────────────────────────────────────────
    # RR's own mobile client (rr_kanpur) does not write documents.bilty as a raw
    # string — it only ever sets documents.bilty_date. Follow that verified shape.
    if trip.bilty_number:
        bilty_dt = trip.s3_completed_at or datetime.utcnow()
        documents["bilty_date"] = bilty_dt.strftime("%Y-%m-%dT%H:%M:%S")

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
        trip.rr_s3_sync_status = "failed"
        trip.rr_s3_sync_error = f"PATCH parcel exception: {exc}"[:500]
        db.commit()
        return

    if patch_resp.status_code not in (200, 201):
        logger.error(
            f"[RR Sync S3] PATCH parcel failed ({patch_resp.status_code}): {patch_resp.text[:300]}"
        )
        trip.rr_s3_sync_status = "failed"
        trip.rr_s3_sync_error = f"HTTP {patch_resp.status_code}: {patch_resp.text[:400]}"
        db.commit()
        return

    # Store updated etag from response
    new_etag = patch_resp.json().get("_etag", etag)
    trip.rr_parcel_etag = new_etag
    trip.rr_sync_status = "bilty_synced"
    trip.rr_synced_at = datetime.utcnow()
    trip.rr_s3_sync_status = "synced"
    trip.rr_s3_synced_at = datetime.utcnow()
    trip.rr_s3_sync_error = None
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


# ── Stage 4: Fuel/diesel receipt ───────────────────────────────────────────────

async def _sync_stage4_fuel_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """Upload diesel receipt to RR /files then POST /post_loading_slip with fuel_slip."""
    if not trip.s4_diesel_receipt_url:
        return

    if not trip.rr_trip_id:
        logger.info(f"[RR Sync S4] Trip {trip.trip_number} has no rr_trip_id yet — pending trip creation")
        trip.rr_s4_sync_status = "pending_trip_creation"
        db.commit()
        return

    rr_file_id = await _upload_file(trip.s4_diesel_receipt_url, client, token)
    if not rr_file_id:
        trip.rr_s4_sync_status = "failed"
        trip.rr_s4_sync_error = "Diesel receipt file upload to RR failed"
        db.commit()
        return

    try:
        resp = await client.post(
            f"{settings.RR_API_BASE}/post_loading_slip",
            json={"trip_id": trip.rr_trip_id, "fuel_slip": rr_file_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        logger.error(f"[RR Sync S4] post_loading_slip (fuel_slip) exception: {exc}")
        trip.rr_s4_sync_status = "failed"
        trip.rr_s4_sync_error = f"post_loading_slip exception: {exc}"[:500]
        db.commit()
        return

    if resp.status_code in (200, 201):
        trip.rr_s4_sync_status = "synced"
        trip.rr_s4_synced_at = datetime.utcnow()
        trip.rr_s4_sync_error = None
        db.commit()
        logger.info(
            f"[RR Sync S4] Trip {trip.trip_number} fuel slip synced (rr_file_id={rr_file_id})"
        )
    else:
        logger.error(
            f"[RR Sync S4] post_loading_slip (fuel_slip) failed ({resp.status_code}): {resp.text[:300]}"
        )
        trip.rr_s4_sync_status = "failed"
        trip.rr_s4_sync_error = f"HTTP {resp.status_code}: {resp.text[:400]}"
        db.commit()


# ── Stage 5: POD ──────────────────────────────────────────────────────────────

async def _sync_stage5(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    PATCH the RR parcel with:
      - documents.pod.{datetime, photos}  — POD photo (no "side" key — matches
        rr_kanpur's verified shape, unlike weight_receipt/consignor_invoice which do use it)
      - unloading.halting_charge          — halting charge, NOT under documents
    """
    if not trip.rr_parcel_id:
        logger.info(f"[RR Sync S5] Trip {trip.trip_number} has no rr_parcel_id yet — pending trip creation")
        trip.rr_s5_sync_status = "pending_trip_creation"
        db.commit()
        return

    if not trip.s5_pod_url and trip.s5_halting_charge is None:
        return

    etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
    if not etag:
        logger.error(f"[RR Sync S5] Cannot fetch parcel etag for trip {trip.trip_number}")
        trip.rr_s5_sync_status = "failed"
        trip.rr_s5_sync_error = "Could not fetch parcel etag from RR"
        db.commit()
        return

    patch_body: dict = {}

    if trip.s5_pod_url:
        rr_pod_id = await _upload_file(trip.s5_pod_url, client, token)
        if not rr_pod_id:
            logger.error(f"[RR Sync S5] POD file upload failed for trip {trip.trip_number}")
            trip.rr_s5_sync_status = "failed"
            trip.rr_s5_sync_error = "POD file upload to RR failed"
            db.commit()
            return
        pod_dt = trip.s5_completed_at or datetime.utcnow()
        patch_body["documents"] = {
            "pod": {
                "datetime": pod_dt.strftime("%Y-%m-%dT%H:%M:%S"),
                "photos": [{"photo": rr_pod_id}],
            }
        }

    if trip.s5_halting_charge is not None:
        patch_body["unloading"] = {"halting_charge": float(trip.s5_halting_charge)}

    if not patch_body:
        return

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
            json=patch_body,
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        logger.error(f"[RR Sync S5] PATCH parcel exception: {exc}")
        trip.rr_s5_sync_status = "failed"
        trip.rr_s5_sync_error = f"PATCH parcel exception: {exc}"[:500]
        db.commit()
        return

    if patch_resp.status_code in (200, 201):
        trip.rr_sync_status = "pod_synced"
        trip.rr_parcel_etag = patch_resp.json().get("_etag", etag)
        trip.rr_synced_at = datetime.utcnow()
        trip.rr_s5_sync_status = "synced"
        trip.rr_s5_synced_at = datetime.utcnow()
        trip.rr_s5_sync_error = None
        db.commit()
        logger.info(
            f"[RR Sync S5] Trip {trip.trip_number} Stage 5 synced → parcel {trip.rr_parcel_id}"
        )
    else:
        logger.error(
            f"[RR Sync S5] PATCH parcel failed ({patch_resp.status_code}): {patch_resp.text[:300]}"
        )
        trip.rr_s5_sync_status = "failed"
        trip.rr_s5_sync_error = f"HTTP {patch_resp.status_code}: {patch_resp.text[:400]}"
        db.commit()


# ── Create trip + parcel in RR directly ──────────────────────────────────────

async def _create_rr_trip(
    trip,
    client: httpx.AsyncClient,
    token: str,
    consignor_rr_id: str,
    rr_weight_unit: str,
    lp_rr_company_id: str | None = None,
    rr_ops_rr_id: str | None = None,
    consignee_rr_id: str | None = None,
    vehicle_body_type: str | None = None,
) -> tuple[str | None, str | None, str | None]:
    """
    Create trip + parcel in RR using direct Eve endpoints (JSON body).
    Returns (rr_trip_id, rr_parcel_id, error_message).
    """
    import base64
    import json as _json

    # Decode JWT payload to get the LP's RR user ObjectId for created_by / handled_by
    rr_user_id = None
    try:
        parts = token.split(".")
        padded = parts[1] + "=" * (-len(parts[1]) % 4)
        rr_user_id = _json.loads(base64.b64decode(padded).decode()).get("sub")
    except Exception:
        pass

    # ── Step 1: POST /trips ───────────────────────────────────────────────────
    trip_payload: dict = {"source": "Other"}
    if rr_user_id:
        trip_payload["created_by"] = rr_user_id
    # handled_by = RR Ops worker's RR user ID if available, else fall back to creator
    handled = rr_ops_rr_id or rr_user_id
    if handled:
        trip_payload["handled_by"] = handled
    # created_by_company = LP's own RR company (makes trip visible in their portal)
    if lp_rr_company_id:
        trip_payload["created_by_company"] = lp_rr_company_id
    if trip.created_at:
        trip_payload["back_entry_date"] = trip.created_at.strftime("%Y-%m-%dT%H:%M:%S")

    # Vehicle requirements (build once, add to as we go)
    svr: dict = {}
    if vehicle_body_type:
        svr["vehicle_body_type"] = vehicle_body_type
    if getattr(trip, 'axle_type', None):
        svr["axle_type"] = trip.axle_type
    if getattr(trip, 'number_of_wheels', None):
        svr["number_of_wheels"] = [trip.number_of_wheels]   # RR expects a list
    if getattr(trip, 'expected_freight', None):
        svr["expected_price"] = float(trip.expected_freight)
    if svr:
        trip_payload["specific_vehicle_requirements"] = svr

    try:
        trip_resp = await client.post(
            f"{settings.RR_API_BASE}/trips",
            json=trip_payload,
            headers=_auth_header(token),
        )
    except Exception as exc:
        return None, None, f"POST /trips request failed: {exc}"

    if trip_resp.status_code not in (200, 201):
        return None, None, f"POST /trips HTTP {trip_resp.status_code}: {trip_resp.text[:300]}"

    rr_trip_id = trip_resp.json().get("_id")
    if not rr_trip_id:
        return None, None, f"POST /trips response missing _id: {trip_resp.text[:200]}"

    # ── Step 2: POST /parcels ─────────────────────────────────────────────────
    # Build pickup / unload address dicts
    pickup_addr: dict = {"city": trip.origin_rr_city_id}
    if getattr(trip, 'pickup_address_line1', None):
        pickup_addr["address_line_1"] = trip.pickup_address_line1
    if getattr(trip, 'pickup_address_line2', None):
        pickup_addr["address_line_2"] = trip.pickup_address_line2
    if getattr(trip, 'pickup_pin', None):
        try:
            pickup_addr["pin"] = int(trip.pickup_pin)
        except (ValueError, TypeError):
            pass
    if getattr(trip, 'pickup_no_entry_zone', None) is not None:
        pickup_addr["no_entry_zone"] = bool(trip.pickup_no_entry_zone)

    unload_addr: dict = {"city": trip.destination_rr_city_id}
    if getattr(trip, 'unload_address_line1', None):
        unload_addr["address_line_1"] = trip.unload_address_line1
    if getattr(trip, 'unload_address_line2', None):
        unload_addr["address_line_2"] = trip.unload_address_line2
    if getattr(trip, 'unload_pin', None):
        try:
            unload_addr["pin"] = int(trip.unload_pin)
        except (ValueError, TypeError):
            pass
    if getattr(trip, 'unload_no_entry_zone', None) is not None:
        unload_addr["no_entry_zone"] = bool(trip.unload_no_entry_zone)

    # Sender (consignor)
    sender: dict = {"sender_company": consignor_rr_id}
    if getattr(trip, 'consignor_name', None):
        sender["name"] = trip.consignor_name
    if getattr(trip, 'consignor_gstin', None):
        sender["gstin"] = trip.consignor_gstin

    parcel_payload: dict = {
        "trip_id":               rr_trip_id,
        "pickup_postal_address": pickup_addr,
        "unload_postal_address": unload_addr,
        "quantity":              float(trip.weight_value),
        "quantity_unit":         rr_weight_unit,
        "material_type":         trip.material_rr_id,
        "cost":                  float(trip.invoice_value or trip.trip_amount or 0),
        "sender":                sender,
        "source":                "Other",
    }
    # Receiver (consignee)
    if consignee_rr_id:
        receiver: dict = {"receiver_company": consignee_rr_id}
        if getattr(trip, 'consignee_name', None):
            receiver["name"] = trip.consignee_name
        if getattr(trip, 'consignee_gstin', None):
            receiver["gstin"] = trip.consignee_gstin
        parcel_payload["receiver"] = receiver

    if lp_rr_company_id:
        parcel_payload["created_by_company"] = lp_rr_company_id
    if trip.created_at:
        parcel_payload["back_entry_date"] = trip.created_at.strftime("%Y-%m-%dT%H:%M:%S")
    if getattr(trip, 'parcel_description', None):
        parcel_payload["description"] = trip.parcel_description
    if getattr(trip, 'part_load', None):
        parcel_payload["part_load"] = bool(trip.part_load)
    if getattr(trip, 'depot_code', None):
        parcel_payload["depot_code"] = trip.depot_code

    # Documents — must be proper nested dict, NOT dot-notation keys
    docs: dict = {}
    if trip.bilty_number:
        docs["bilty"] = trip.bilty_number
    if trip.invoice_number:
        docs["consignor_invoice"] = {"number": str(trip.invoice_number).upper()}
    if docs:
        parcel_payload["documents"] = docs

    try:
        parcel_resp = await client.post(
            f"{settings.RR_API_BASE}/parcels",
            json=parcel_payload,
            headers=_json_header(token),
        )
    except Exception as exc:
        # Best-effort rollback: delete the trip we just created
        try:
            t_data = (await client.get(
                f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                headers=_auth_header(token),
            )).json()
            await client.delete(
                f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                headers={**_auth_header(token), "If-Match": t_data.get("_etag", "")},
            )
        except Exception:
            pass
        return None, None, f"POST /parcels request failed: {exc}"

    if parcel_resp.status_code not in (200, 201):
        # Best-effort rollback
        try:
            t_data = (await client.get(
                f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                headers=_auth_header(token),
            )).json()
            await client.delete(
                f"{settings.RR_API_BASE}/trips/{rr_trip_id}",
                headers={**_auth_header(token), "If-Match": t_data.get("_etag", "")},
            )
        except Exception:
            pass
        return None, None, f"POST /parcels HTTP {parcel_resp.status_code}: {parcel_resp.text[:300]}"

    rr_parcel_id = parcel_resp.json().get("_id")
    if not rr_parcel_id:
        return None, None, f"POST /parcels response missing _id: {parcel_resp.text[:200]}"

    return rr_trip_id, rr_parcel_id, None


# ── Vehicle hiring flow (APIs 3-7 from RR web create_trip) ───────────────────

async def _assign_vehicle_to_rr_trip(
    rr_trip_id: str,
    rr_vehicle_id: str,
    rr_user_id: str | None,
    transporter_rr_company_id: str | None,
    booking_amount: float,
    client: httpx.AsyncClient,
    token: str,
) -> str | None:
    """
    Complete the vehicle hiring flow in RR after trip + parcel are created.
    Mirrors what RR web's create_trip does internally (steps 3-7):
      3. POST /v2/save_potential_vehicle_to_be_hired
      4. POST /submit_offline_bid_by_trip_owner
      5. POST /award_bidding
      6. POST /market_vehicles  (only if vehicle_relation == "Market")
      7. POST /award_vehicle

    Returns an error string on failure or None on success.
    Caller should treat failures as warnings (non-fatal) since trip+parcel exist.
    """
    from datetime import timezone, timedelta

    # ── 3: Save potential vehicle ──────────────────────────────────────────────
    pv_payload: dict = {
        "vehicle_id": rr_vehicle_id,
        "trip_id":    rr_trip_id,
    }
    if transporter_rr_company_id:
        pv_payload["participant_company_id"] = transporter_rr_company_id
    elif rr_user_id:
        pv_payload["participant_user_id"] = rr_user_id
    else:
        return "No participant for potential vehicle — need transporter_rr_company_id or rr_user_id"

    try:
        pv_resp = await client.post(
            f"{settings.RR_API_BASE}/v2/save_potential_vehicle_to_be_hired",
            json=pv_payload,
            headers=_json_header(token),
        )
    except Exception as exc:
        return f"POST /v2/save_potential_vehicle_to_be_hired failed: {exc}"

    if pv_resp.status_code != 200:
        return f"POST /v2/save_potential_vehicle_to_be_hired HTTP {pv_resp.status_code}: {pv_resp.text[:200]}"

    potential_vehicle_id = pv_resp.json().get("potential_vehicle_id")
    if not potential_vehicle_id:
        return f"save_potential_vehicle missing potential_vehicle_id: {pv_resp.text[:200]}"

    # ── 4: Submit offline bid ──────────────────────────────────────────────────
    try:
        bid_resp = await client.post(
            f"{settings.RR_API_BASE}/submit_offline_bid_by_trip_owner",
            json={"potential_vehicle_id": potential_vehicle_id, "amount": booking_amount},
            headers=_json_header(token),
        )
    except Exception as exc:
        return f"POST /submit_offline_bid_by_trip_owner failed: {exc}"

    if bid_resp.status_code != 200:
        return f"POST /submit_offline_bid_by_trip_owner HTTP {bid_resp.status_code}: {bid_resp.text[:200]}"

    # ── 5: Award bidding ───────────────────────────────────────────────────────
    try:
        award_resp = await client.post(
            f"{settings.RR_API_BASE}/award_bidding",
            json={"potential_vehicle_id": potential_vehicle_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        return f"POST /award_bidding failed: {exc}"

    if award_resp.status_code != 200:
        return f"POST /award_bidding HTTP {award_resp.status_code}: {award_resp.text[:200]}"

    # ── 6: market_vehicles — only if vehicle_relation == "Market" ─────────────
    try:
        pv_get = await client.get(
            f"{settings.RR_API_BASE}/potential_vehicles/{potential_vehicle_id}",
            headers=_auth_header(token),
        )
        if pv_get.status_code == 200 and pv_get.json().get("vehicle_relation") == "Market":
            v_get = await client.get(
                f"{settings.RR_API_BASE}/vehicles/{rr_vehicle_id}",
                headers=_auth_header(token),
            )
            if v_get.status_code == 200:
                v_data = v_get.json()
                now = datetime.now(timezone.utc)
                mv_payload: dict = {
                    "vehicle_id":            rr_vehicle_id,
                    "owner_user_id":         str(v_data.get("created_by", "")),
                    "owner_company_id":      str(v_data.get("created_by_company", "")),
                    "requested_start_date":  now.strftime("%Y-%m-%dT%H:%M:%S"),
                    "requested_end_date":    (now + timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%S"),
                }
                if transporter_rr_company_id:
                    mv_payload["third_party_company_id"] = transporter_rr_company_id
                elif rr_user_id:
                    mv_payload["third_party_user_id"] = rr_user_id
                await client.post(
                    f"{settings.RR_API_BASE}/market_vehicles",
                    data=mv_payload,
                    headers=_auth_header(token),
                )
    except Exception as exc:
        logger.warning(f"[RR Sync] market_vehicles step failed (non-fatal): {exc}")

    # ── 7: Award vehicle ───────────────────────────────────────────────────────
    try:
        av_resp = await client.post(
            f"{settings.RR_API_BASE}/award_vehicle",
            json={"trip_id": rr_trip_id, "potential_vehicle_id": potential_vehicle_id},
            headers=_json_header(token),
        )
    except Exception as exc:
        return f"POST /award_vehicle failed: {exc}"

    if av_resp.status_code != 200:
        return f"POST /award_vehicle HTTP {av_resp.status_code}: {av_resp.text[:200]}"

    return None  # all steps succeeded


# ── Per-stage auto-sync entry point (fired on every stage submit) ────────────────

_STAGE_STATUS_FIELDS = {
    1: ("rr_s1_sync_status", "rr_s1_sync_error"),
    3: ("rr_s3_sync_status", "rr_s3_sync_error"),
    4: ("rr_s4_sync_status", "rr_s4_sync_error"),
    5: ("rr_s5_sync_status", "rr_s5_sync_error"),
}
_AUTH_REQUIRED_MSG = "RR login required — ask LP or RR Ops to sign in to RR"


async def sync_stage(trip_id: str, stage: int) -> None:
    """
    Background task fired right after a trip stage is submitted locally.
    Resolves (and silently refreshes) the trip's organization RR session,
    then pushes that stage's data to RR. Never raises — always safe to
    fire-and-forget from a request handler.
    """
    if not settings.RR_SYNC_ENABLED:
        return

    from app.database import SessionLocal
    from app.models.trip import Trip
    from app.models.company import Organization
    from app.services.rr_org_token_service import get_org_rr_token

    db = SessionLocal()
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            logger.warning(f"[RR Sync Stage {stage}] Trip {trip_id} not found")
            return

        org = db.query(Organization).filter(Organization.id == trip.organization_id).first()
        if not org:
            logger.warning(f"[RR Sync Stage {stage}] Organization not found for trip {trip.trip_number}")
            return

        token = await get_org_rr_token(org, db)
        if not token:
            if stage == 2:
                trip.rr_sync_status = "auth_required"
                trip.rr_sync_error = _AUTH_REQUIRED_MSG
            else:
                status_field, error_field = _STAGE_STATUS_FIELDS[stage]
                setattr(trip, status_field, "auth_required")
                setattr(trip, error_field, _AUTH_REQUIRED_MSG)
            db.commit()
            logger.info(f"[RR Sync Stage {stage}] Trip {trip.trip_number} — no RR session available, marked auth_required")
            return

        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
            if stage == 1:
                await _sync_stage1_docs(trip, client, token, db)
            elif stage == 2:
                await _sync_loading_slip(trip, client, token, db)
            elif stage == 3:
                await _sync_stage3(trip, client, token, db)
            elif stage == 4:
                await _sync_stage4_fuel_slip(trip, client, token, db)
            elif stage == 5:
                await _sync_stage5(trip, client, token, db)
    except Exception as exc:
        logger.exception(f"[RR Sync Stage {stage}] Unexpected error for trip {trip_id}: {exc}")
    finally:
        db.close()


async def sync_pending_stages_for_trip(trip_id: str) -> None:
    """
    Catch-up sweep: called right after a trip is successfully pushed to RR
    (POST /create_trip succeeds) so any stages submitted locally *before* that
    point — which could only mark themselves pending_trip_creation — get pushed now.
    Stage 1 (driver/vehicle docs) doesn't depend on the trip existing in RR, but
    re-running it here is harmless (identities are de-duped by _push_identities).
    """
    from app.database import SessionLocal
    from app.models.trip import Trip

    db = SessionLocal()
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            return
        current_stage = trip.current_stage or 0
    finally:
        db.close()

    for stage in (1, 2, 3, 4, 5):
        if stage <= current_stage:
            await sync_stage(trip_id, stage)


# ── Top-level entry point (sync button) ──────────────────────────────────────────

async def sync_all_to_rr(trip_id: str, rr_token: str | None = None) -> None:
    """
    Background task: sync ALL available trip data to RR in one shot.
    Called by the manual sync button on the trip screen.

    rr_token: LP's RR access token (from POST /auth/login). If None, falls back
              to the global token service (used by bulk sync).

    Sequence:
      1. If trip not yet in RR → auto-resolve IDs + pre-flight + POST /trips + POST /parcels
      2. Sync loading slip if not yet done
      3. Sync S3 data (bilty, weight receipt, material docs) if available and not yet synced
      4. Sync S5 POD if available and not yet synced
    """
    if not settings.RR_SYNC_ENABLED:
        return

    from app.database import SessionLocal
    from app.models.trip import Trip
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

            # ── Step 1: Trip must already exist in RR via complete-trip ───────
            if not trip.rr_parcel_id:
                logger.info(
                    f"[RR Sync All] Trip {trip.trip_number} not yet in RR — "
                    f"use Complete Trip button to push via POST /create_trip"
                )
                return

            # Steps 2-4 (loading slip, S3, S5) — not active yet.
            # Will be enabled in a future phase.

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


