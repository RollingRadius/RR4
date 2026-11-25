"""
RR Sync Service
Syncs RR4 trips one-way to RollingRadius (RR).

Single entry point: sync_all_to_rr(trip_id)
Called as a BackgroundTask from:
  - POST /api/rr/sync/trip/{id}  (LP dashboard sync sheet or TripStagesScreen AppBar)

Flow:
  1. Trip must already exist in RR (rr_parcel_id set via POST /api/rr/complete-trip/{id})
  2. Sync loading slip if not yet done
  3. Sync S3 data (e-way bill + weight receipt + material docs) if available
  4. Sync S5 POD if available

Note: Trip creation is now done via POST /api/rr/complete-trip/{id} which calls
POST /create_trip on RR web (3.7 branch — JWT bug fixed). The sync button only
pushes document stages (loading slip, S3, S5) after the trip is already in RR.
"""

import asyncio
import base64
import json
import logging
import mimetypes
import uuid
from datetime import datetime
from pathlib import Path

import httpx
from sqlalchemy import text

from app.config import settings
from app.core.document_map import OWNER
from app.core.rr_time import from_rr, to_rr
from app.services import rr_change_marks
from app.services import rr_follow_service   # a module: it imports this one back
from app.services.stage1_document_service import (link_owner_documents, resolve_owner, save_stage1_document,
                                                  stored_owner_document)
from app.services.stored_file_service import load_stored_file
from app.services.upload_storage import describe_upload

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


async def _read_upload(upload_url: str) -> tuple[bytes, str, str] | None:
    """(bytes, content type, file name) of an /uploads/... file, or None if it cannot be found.

    The database is the source. The disk is only a fallback while UPLOADS_FROM_DB is off, for files
    not copied into the database yet; once it is on, the disk is never read.
    """
    stored = await asyncio.to_thread(load_stored_file, upload_url)
    if stored is not None:
        return stored.content, stored.content_type, stored.file_name
    if settings.UPLOADS_FROM_DB:
        return None
    local_path = _local_path(upload_url)
    if not local_path.exists():
        return None
    return local_path.read_bytes(), mimetypes.guess_type(local_path.name)[0] or "application/octet-stream", local_path.name


async def _upload_file(upload_url: str, client: httpx.AsyncClient, token: str) -> str | None:
    """
    Upload a stored file (from the database) to RR /files endpoint.
    Returns the RR file ObjectId string, or None on any failure.
    """
    found = await _read_upload(upload_url)
    if found is None:
        logger.warning(f"[RR Sync] File not found: {upload_url}")
        return None
    content, mime_type, filename = found

    try:
        resp = await client.post(
            f"{settings.RR_API_BASE}/files",
            files={"file": (filename, content, mime_type)},
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


async def _parcel_bilty(rr_parcel_id: str, client: httpx.AsyncClient, token: str):
    """The bilty number RR's parcel holds (documents.bilty), '' when it has none, None when RR could not be read."""
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/parcels/{rr_parcel_id}", headers=_auth_header(token))
    except Exception as exc:
        logger.warning(f"[RR Sync] GET parcel {rr_parcel_id} for the bilty failed: {exc}")
        return None
    if resp.status_code != 200:
        return None
    return ((resp.json().get("documents") or {}).get("bilty")) or ""


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

async def _fetch_driver_identities_by_id(driver_rr_id: str, client: httpx.AsyncClient, token: str) -> list[dict] | None:
    """The driver's current identities[] from his own RR record (get_user_record_by_id), or None if unreadable."""
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/get_user_record_by_id", params={"record_id": driver_rr_id},
                                headers=_auth_header(token))
    except Exception as exc:
        logger.warning(f"[RR Sync] get_user_record_by_id {driver_rr_id} failed: {exc}")
        return None
    if resp.status_code != 200:
        return None
    data = resp.json()
    if str(data.get("_id") or driver_rr_id) != driver_rr_id:
        return None
    return list(data.get("identities") or [])


async def _fetch_driver_identities_via_vehicle(
    vehicle_rr_id: str | None, driver_rr_id: str, client: httpx.AsyncClient, token: str,
) -> list[dict] | None:
    """
    Read a driver's current identities[] via the vehicle they're assigned to.

    GET /users/<id> is restricted to the record's own owner and 404s for an
    LP/RR-ops session even with a correct id — but the driver's full user doc
    (including identities) comes back embedded on the vehicle via
    embedded={"crew.worker": 1}, which the vehicle's owning company *can*
    read. Returns None if it can't be determined (caller treats that as
    "unknown", not "empty", to avoid overwriting docs it never saw).
    """
    if not vehicle_rr_id:
        return None
    try:
        resp = await client.get(
            f"{settings.RR_API_BASE}/vehicles/{vehicle_rr_id}",
            params={"embedded": json.dumps({"crew.worker": 1})},
            headers=_auth_header(token),
        )
    except Exception as exc:
        logger.warning(f"[RR Sync] Fetch driver identities via vehicle failed: {exc}")
        return None
    if resp.status_code != 200:
        return None
    for member in resp.json().get("crew") or []:
        worker = member.get("worker")
        if isinstance(worker, dict) and str(worker.get("_id")) == driver_rr_id:
            return list(worker.get("identities") or [])
    return None


def _rebuild_positional_photos(
    photos: list[dict], front_id: str | None, back_id: str | None,
) -> list[dict]:
    """
    RR's own save_identities Flask handler — and several of its web UI table
    components — read a photo's side by ARRAY POSITION (photos[0] is always
    treated as Front, photos[1] as Back) instead of the "side" field on each
    entry. Filtering out the changed side and appending the replacement at
    the end (the previous approach here) breaks that positional invariant
    the instant only one side changes, causing RR to display Front/Back
    swapped. This rebuilds photos as a strict [Front, Back] positional list
    every time, keeping whichever side wasn't touched in its existing slot.
    A back with no front gets an empty Front slot first, so the back is never
    read as the front. Entries without a "side" are read by position, as RR does.
    """
    if photos and not any(p.get("side") for p in photos):
        photos = [{**p, "side": side} for p, side in zip(photos, ("Front", "Back"))]
    existing_front = next((p for p in photos if p.get("side") == "Front"), None)
    existing_back = next((p for p in photos if p.get("side") == "Back"), None)
    if front_id:
        existing_front = {"photo": front_id, "side": "Front"}
    if back_id:
        existing_back = {"photo": back_id, "side": "Back"}
    if existing_back is not None and existing_front is None:
        existing_front = {"photo": None, "side": "Front"}
    return [p for p in (existing_front, existing_back) if p is not None]


async def _push_driver_identities(
    entity,
    driver_rr_id: str,
    vehicle_rr_id: str | None,
    company_id: str | None,
    items: list[dict],
    client: httpx.AsyncClient,
    token: str,
    db,
    trip=None,
) -> tuple[bool, str | None]:
    """
    Push driver identity docs (DL/Aadhaar/PAN/Tax Declaration) via RR's
    POST /users/save_identities — the only way an LP/RR-ops session can write
    to a driver's user record, since GET/PATCH /users/<id> itself 404s (item
    access is restricted to the record's own owner; _push_identities' normal
    GET-then-PATCH flow only works for vehicles, not users).

    save_identities wholesale-replaces `identities[]` server-side (no merge),
    so we read the driver's current identities first via
    _fetch_driver_identities_via_vehicle and send back the full merged set.

    A side is (re)pushed whenever the trip's current local URL for that side
    differs from trip.rr_synced_doc_urls (what THIS trip last successfully
    pushed there) — covers both "RR never had this side" and "RR has a side
    but it's a stale/earlier photo", replacing RR's copy in the latter case
    instead of leaving it untouched.
    """
    synced_urls = dict((trip.rr_synced_doc_urls or {}) if trip is not None else {})

    def _front_key(it): return f"{it['id_name']}::front"
    def _back_key(it): return f"{it['id_name']}::back"

    def _needs(it):
        front_changed = bool(it["front_url"]) and synced_urls.get(_front_key(it)) != it["front_url"]
        back_changed = bool(it["back_url"]) and synced_urls.get(_back_key(it)) != it["back_url"]
        return front_changed or back_changed or bool(it.get("number"))

    to_push = [it for it in items if _needs(it)]
    if not to_push:
        return True, None  # everything already pushed for this driver

    # save_identities REPLACES the driver's whole identities list, so his current list must be known first.
    # Read it from his own record (works for the org's LP/RR-ops/CSR session), else via the vehicle's crew.
    # Unknown -> send nothing (fix 2026-11-14: the old empty-baseline fallback sent number-only entries that wiped
    # every photo RR held - it happened whenever the vehicle's current crew driver was not this trip's driver).
    existing = await _fetch_driver_identities_by_id(driver_rr_id, client, token)
    if existing is None:
        existing = await _fetch_driver_identities_via_vehicle(vehicle_rr_id, driver_rr_id, client, token)
    if existing is None:
        return False, "could not read the driver's current documents in RR - nothing sent (sync again)"

    existing_by_name: dict[str, int] = {}
    for idx, entry in enumerate(existing):
        name = entry.get("id_name")
        if name:
            existing_by_name[name] = idx

    local_updates: list[tuple[str, str]] = []
    synced_url_updates: dict[str, str] = {}
    sent_files: list[tuple[str, str]] = []   # (stored url, RR file id)
    pushed_number = False

    for it in to_push:
        need_front = bool(it["front_url"]) and synced_urls.get(_front_key(it)) != it["front_url"]
        need_back = bool(it["back_url"]) and synced_urls.get(_back_key(it)) != it["back_url"]
        idx = existing_by_name.get(it["id_name"])
        current = existing[idx] if idx is not None else None
        if need_front and _rr_holds_file(db, it["front_url"], _side_photo(current, "Front")):
            need_front = False   # RR already shows exactly this stored photo
        if need_back and _rr_holds_file(db, it["back_url"], _side_photo(current, "Back")):
            need_back = False

        front_id = back_id = None
        if need_front:
            front_id = await _upload_file(it["front_url"], client, token)
            if front_id:
                local_updates.append((it["front_attr"], front_id))
                synced_url_updates[_front_key(it)] = it["front_url"]
                sent_files.append((it["front_url"], front_id))
        if need_back:
            back_id = await _upload_file(it["back_url"], client, token)
            if back_id:
                if it["back_attr"]:
                    local_updates.append((it["back_attr"], back_id))
                synced_url_updates[_back_key(it)] = it["back_url"]
                sent_files.append((it["back_url"], back_id))

        if idx is not None:
            photos = _rebuild_positional_photos(
                existing[idx].get("photos") or [], front_id, back_id,
            )
            updated_entry = {**existing[idx], "photos": photos}
            if it.get("number") and existing[idx].get("number") != it["number"]:
                updated_entry["number"] = it["number"]
                pushed_number = True
            existing[idx] = updated_entry
            continue

        photos = _rebuild_positional_photos([], front_id, back_id)
        if photos or it.get("number"):
            new_entry = {"id_name": it["id_name"], "photos": photos}
            if it.get("number"):
                new_entry["number"] = it["number"]
                pushed_number = True
            existing.append(new_entry)

    if not local_updates and not pushed_number:
        return True, None  # nothing changed — nothing to save

    # RR's save_identities silently drops any identity entry carrying
    # expiry_date (server-side indentation bug in RR's own code) — none of
    # our driver doc types set one today, but strip defensively so a future
    # addition can't silently vanish instead of erroring loudly.
    clean_identities = [
        {k: v for k, v in entry.items() if k != "expiry_date"}
        for entry in existing
    ]

    body: dict = {"user_id": driver_rr_id, "identities": clean_identities}
    if company_id:
        body["company_id"] = company_id

    try:
        resp = await client.post(
            f"{settings.RR_API_BASE}/users/save_identities",
            json=body,
            headers=_json_header(token),
        )
    except Exception as exc:
        return False, f"POST save_identities exception: {exc}"
    if resp.status_code != 200:
        return False, f"POST save_identities HTTP {resp.status_code}: {resp.text[:400]}"

    for attr, rr_file_id in local_updates:
        setattr(entity, attr, rr_file_id)
    if trip is not None and synced_url_updates:
        trip.rr_synced_doc_urls = {**(trip.rr_synced_doc_urls or {}), **synced_url_updates}
    _mark_stored_as_sent(db, sent_files)
    db.commit()
    return True, None


def _mark_stored_as_sent(db, sent_files: list[tuple[str, str]]) -> None:
    """Record on each stored document which RR file it became (RR holds exactly these bytes), so another trip
    that shows the same stored document does not send it again."""
    for url, rr_file_id in sent_files:
        for table in ("driver_documents", "vehicle_documents", "owner_documents", "trip_documents"):
            db.execute(text(f"UPDATE {table} SET rr_file_id = :f, rr_synced_sha256 = sha256 WHERE url_path = :u"),
                       {"f": rr_file_id, "u": url})


def _side_photo(entry: dict | None, side: str):
    """RR's current photo id on one side ("Front"/"Back") of an identity entry; an unlabelled first photo is the front."""
    photos = (entry or {}).get("photos") or []
    for p in photos:
        if p.get("side") == side:
            return p.get("photo")
    if side == "Front" and photos and not any(p.get("side") for p in photos):
        return photos[0].get("photo")
    return None


def _rr_holds_file(db, url: str | None, rr_photo_id) -> bool:
    """True when RR's current photo (rr_photo_id) is exactly the stored document at `url`: the sync sent these bytes
    before (rr_file_id recorded by _mark_stored_as_sent, not replaced since). Such a photo is not sent again."""
    if not (url and rr_photo_id):
        return False
    result = db.execute(text(
        "SELECT 1 FROM (SELECT url_path, rr_file_id, rr_synced_sha256, sha256 FROM driver_documents UNION ALL "
        "SELECT url_path, rr_file_id, rr_synced_sha256, sha256 FROM vehicle_documents UNION ALL "
        "SELECT url_path, rr_file_id, rr_synced_sha256, sha256 FROM owner_documents) d "
        "WHERE url_path = :u AND rr_file_id = :f AND rr_synced_sha256 = sha256"), {"u": url, "f": str(rr_photo_id)})
    return bool(result is not None and result.first())


# Trip columns of each Stage 1 identity document: (front photo, back photo or None, number).
_ITEM_COLUMNS = {
    "Driving Licence": ("s1_driving_license_url", "s1_driving_license_back_url", "s1_driving_license"),
    "Aadhaar Card": ("s1_aadhaar_url", "s1_aadhaar_back_url", "s1_aadhaar"),
    "Registration Certificate": ("s1_rc", "s1_rc_back", "s1_rc_number"),
    "PUC Certificate": ("s1_pollution", None, "s1_puc_number"),
    "Fitness Certificate": ("s1_fitness", None, "s1_fitness_number"),
    "Permit": ("s1_permit", None, "s1_permit_number"),
}


def _only_changed_items(trip, items: list[dict], synced_before: bool) -> list[dict]:
    """The identity items with every part (front, back, number) that did not change since the last successful Stage 1
    sync left out (rr_change_marks). Before a first successful sync every part goes, as before."""
    if not synced_before:
        return items
    out = []
    for it in items:
        front, back, number = _ITEM_COLUMNS[it["id_name"]]
        g = dict(it)
        if not rr_change_marks.should_send(trip, front, True):
            g["front_url"] = None
        if back is None or not rr_change_marks.should_send(trip, back, True):
            g["back_url"] = None
        if not rr_change_marks.should_send(trip, number, True):
            g["number"] = None
        out.append(g)
    return out


async def _rr_file_for(url: str, client: httpx.AsyncClient, token: str, db) -> tuple[str | None, bool]:
    """(RR file id, is_new) for a Stage 2-5 file. When RR already holds exactly these bytes (sent before and not
    replaced since: rr_synced_sha256 = sha256 on the stored row) its RR file id is reused and nothing is uploaded;
    otherwise the file is uploaded now (None when that fails). F6: files go to RR only when new or changed. The
    caller marks a new file as sent (_mark_stored_as_sent) once RR has saved it."""
    row = db.execute(text("SELECT rr_file_id FROM trip_documents WHERE url_path = :u AND rr_file_id IS NOT NULL "
                          "AND rr_synced_sha256 = sha256"), {"u": url}).first()
    if row is not None:
        return row[0], False
    return await _upload_file(url, client, token), True


async def _push_identities(
    entity,
    entity_collection: str,
    rr_id: str,
    items: list[dict],
    client: httpx.AsyncClient,
    token: str,
    db,
    trip=None,
) -> tuple[bool, str | None]:
    """
    Push identity docs into `identities[]` on a `users`/`vehicles` RR record,
    tracking each doc's RR file id locally (on `entity`) for reference.

    A side is (re)pushed whenever the trip's current local URL for that side
    differs from trip.rr_synced_doc_urls (what THIS trip last successfully
    pushed there) — covers both "RR has no entry yet" and "RR has a side but
    it's a stale/earlier photo", replacing RR's existing side in the latter
    case instead of leaving it untouched, so re-running sync always
    converges RR to match what's currently on the trip.

    items: list of {id_name, front_url, back_url, front_attr, back_attr}
    front_attr/back_attr are column names on `entity` that cache the RR file id.
    Returns (success, error_message).
    """
    synced_urls = dict((trip.rr_synced_doc_urls or {}) if trip is not None else {})

    def _front_key(it): return f"{it['id_name']}::front"
    def _back_key(it): return f"{it['id_name']}::back"

    def _needs(it):
        front_changed = bool(it["front_url"]) and synced_urls.get(_front_key(it)) != it["front_url"]
        back_changed = bool(it["back_url"]) and synced_urls.get(_back_key(it)) != it["back_url"]
        return front_changed or back_changed or bool(it.get("number"))

    to_push = [it for it in items if _needs(it)]
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
    identities = list(data.get("identities") or [])
    existing_by_name: dict[str, int] = {}
    for idx, entry in enumerate(identities):
        name = entry.get("id_name")
        if name:
            existing_by_name[name] = idx

    new_entries = []
    patches: dict[int, list[dict]] = {}  # index into `identities` -> full replacement photos list
    number_patches: dict[int, str] = {}  # index into `identities` -> new number value
    local_updates: list[tuple[str, str]] = []  # (attr, rr_file_id)
    synced_url_updates: dict[str, str] = {}
    sent_files: list[tuple[str, str]] = []   # (stored url, RR file id)

    for it in to_push:
        need_front = bool(it["front_url"]) and synced_urls.get(_front_key(it)) != it["front_url"]
        need_back = bool(it["back_url"]) and synced_urls.get(_back_key(it)) != it["back_url"]
        idx = existing_by_name.get(it["id_name"])
        current = identities[idx] if idx is not None else None
        if need_front and _rr_holds_file(db, it["front_url"], _side_photo(current, "Front")):
            need_front = False   # RR already shows exactly this stored photo
        if need_back and _rr_holds_file(db, it["back_url"], _side_photo(current, "Back")):
            need_back = False

        front_id = back_id = None
        if need_front:
            front_id = await _upload_file(it["front_url"], client, token)
            if front_id:
                local_updates.append((it["front_attr"], front_id))
                synced_url_updates[_front_key(it)] = it["front_url"]
                sent_files.append((it["front_url"], front_id))
        if need_back:
            back_id = await _upload_file(it["back_url"], client, token)
            if back_id:
                if it["back_attr"]:
                    local_updates.append((it["back_attr"], back_id))
                synced_url_updates[_back_key(it)] = it["back_url"]
                sent_files.append((it["back_url"], back_id))

        if idx is not None:
            if front_id or back_id:
                patches[idx] = _rebuild_positional_photos(
                    identities[idx].get("photos") or [], front_id, back_id,
                )
            if it.get("number") and identities[idx].get("number") != it["number"]:
                number_patches[idx] = it["number"]
            continue

        # RR has no entry for this id_name at all — push a fresh one.
        photos = _rebuild_positional_photos([], front_id, back_id)
        if photos or it.get("number"):
            new_entry = {"id_name": it["id_name"], "photos": photos}
            if it.get("number"):
                new_entry["number"] = it["number"]
            new_entries.append(new_entry)

    if not new_entries and not patches and not number_patches:
        return True, None

    for idx, photos in patches.items():
        identities[idx] = {**identities[idx], "photos": photos}
    for idx, number in number_patches.items():
        identities[idx] = {**identities[idx], "number": number}

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
    if trip is not None and synced_url_updates:
        trip.rr_synced_doc_urls = {**(trip.rr_synced_doc_urls or {}), **synced_url_updates}
    _mark_stored_as_sent(db, sent_files)
    db.commit()
    return True, None


async def _push_vehicle_insurance(
    entity,
    vehicle_rr_id: str,
    policy_number: str | None,
    front_url: str | None,
    client: httpx.AsyncClient,
    token: str,
    db,
    trip=None,
) -> tuple[bool, str | None]:
    """
    Push vehicle insurance (policy_number + photo) via PATCH /vehicles/{id}.

    Insurance is its own top-level RR field (`vehicles.insurance`), not part
    of `identities[]` — RR web itself patches both together in a single
    combined PATCH call to avoid a stale-etag race between two sequential
    PATCHes. We instead do our own independent GET-then-PATCH, which is
    equally safe here since this always runs sequentially (never
    concurrently) with the identities push right before it in
    _sync_stage1_docs — each call fetches its own fresh etag immediately
    before its own PATCH, so there's no window for staleness.

    Always starts from the vehicle's CURRENT insurance dict before
    overwriting policy_number/photos — Eve's PATCH replaces a nested dict
    wholesale, so skipping this would wipe expiry_date/currency/
    insured_by_company/main_declared_value if RR already had them set.
    """
    synced_urls = dict((trip.rr_synced_doc_urls or {}) if trip is not None else {})
    needs_photo = bool(front_url) and synced_urls.get("Insurance::front") != front_url
    if not needs_photo and not policy_number:
        return True, None  # nothing to push

    try:
        get_resp = await client.get(
            f"{settings.RR_API_BASE}/vehicles/{vehicle_rr_id}", headers=_auth_header(token)
        )
    except Exception as exc:
        return False, f"GET vehicles exception: {exc}"
    if get_resp.status_code != 200:
        return False, f"GET vehicles HTTP {get_resp.status_code}: {get_resp.text[:300]}"

    data = get_resp.json()
    etag = data.get("_etag")
    current = dict(data.get("insurance") or {})

    if needs_photo and _rr_holds_file(db, front_url, _side_photo(current, "Front")):
        needs_photo = False   # RR already shows exactly this stored photo
    needs_number = bool(policy_number) and current.get("policy_number") != policy_number
    if not needs_photo and not needs_number:
        return True, None  # RR already matches what we have — nothing changed

    new_file_id: str | None = None
    if needs_photo:
        photo_id = await _upload_file(front_url, client, token)
        if photo_id:
            photos = [p for p in (current.get("photos") or []) if p.get("side") != "Front"]
            photos.append({"photo": photo_id, "side": "Front"})
            current["photos"] = photos
            new_file_id = photo_id
    if needs_number:
        current["policy_number"] = policy_number

    # RR's insurance schema requires `expiry_date` present (nullable is ok)
    # and `currency` (has a default) — ensure both present so a brand-new
    # insurance record doesn't fail validation.
    current.setdefault("expiry_date", None)
    current.setdefault("currency", "INR")

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/vehicles/{vehicle_rr_id}",
            json={"insurance": current},
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        return False, f"PATCH vehicles (insurance) exception: {exc}"
    if patch_resp.status_code not in (200, 201):
        return False, f"PATCH vehicles (insurance) HTTP {patch_resp.status_code}: {patch_resp.text[:300]}"

    if new_file_id:
        entity.rr_insurance_file_id = new_file_id
    if trip is not None and new_file_id:
        trip.rr_synced_doc_urls = {**(trip.rr_synced_doc_urls or {}), "Insurance::front": front_url}
    db.commit()
    return True, None


def driver_doc_items(trip) -> list[dict]:
    """Shared by _sync_stage1_docs and the identity-status/override endpoints."""
    return [
        {"id_name": "Driving Licence", "front_url": trip.s1_driving_license_url,
         "back_url": trip.s1_driving_license_back_url,
         "front_attr": "rr_dl_file_id", "back_attr": "rr_dl_back_file_id",
         "number": trip.s1_driving_license},
        {"id_name": "Aadhaar Card", "front_url": trip.s1_aadhaar_url,
         "back_url": trip.s1_aadhaar_back_url,
         "front_attr": "rr_aadhaar_file_id", "back_attr": "rr_aadhaar_back_file_id",
         "number": trip.s1_aadhaar},
    ]


# ── Truck owner's documents (Stage 1 "Owner Documents") ──────────────────────────
# RR keeps the truck owner's PAN and tax declaration on the vehicle OWNER of the trip's booking (RR's own
# post_enroute_details): the owner company (company documents "PAN", "Tax Declaration Slip") or, for an
# individual owner, that person (user documents "PAN Card", "Tax Declaration Slip") - a driver who owns the truck
# is that person. RR4's fallback provider (RR's own LP company) is never treated as the owner.
RR_DEFAULT_VEHICLE_PROVIDER = "62d66794e54f47829a886a1d"


def owner_doc_items(trip, owner_kind: str) -> list[dict]:
    """The truck owner's documents of a trip, named as RR names them for a company or for a person.
    `key` is this trip's "already sent" key (kept apart from the old driver-side keys, so documents that went to
    the driver before are sent to the right owner on the next sync)."""
    expiry = trip.s1_tax_declaration_expiry
    return [
        {"id_name": "PAN" if owner_kind == "company" else "PAN Card", "key": "Owner PAN",
         "front_url": trip.s1_pan, "front_attr": "rr_pan_file_id", "back_url": None, "back_attr": None,
         "number": (trip.s1_pan_number or "").strip().upper() or None, "expiry": None},
        {"id_name": "Tax Declaration Slip", "key": "Owner Tax Declaration",
         "front_url": trip.s1_tax_declaration, "front_attr": "rr_tax_declaration_file_id", "back_url": None, "back_attr": None,
         "number": None,
         # RR keeps expiry_date as a UTC date-time "%Y-%m-%dT%H:%M:%S"; RR web shows it in India time (app/core/rr_time).
         "expiry": to_rr(expiry)},
    ]


def owner_item_pending(item: dict, synced: dict, owner_kind: str) -> dict:
    """What of one owner document this trip still has to send: {"photo", "number", "expiry"} flags.
    The photo goes when it is new; the number / valid-till date also go alone when they changed. A person owner's
    date is never sent (RR's save_identities drops identities that carry one), so it is never pending."""
    if not item["front_url"]:
        return {"photo": False, "number": False, "expiry": False}
    key = item["key"]
    return {
        "photo": synced.get(f"{key}::front") != item["front_url"],
        "number": bool(item["number"]) and synced.get(f"{key}::number") != item["number"],
        "expiry": owner_kind == "company" and bool(item["expiry"]) and synced.get(f"{key}::expiry") != item["expiry"],
    }


async def find_vehicle_owner(trip, client: httpx.AsyncClient, token: str) -> tuple[str, str] | None:
    """The truck owner of the trip's booking as RR keeps it: ("company", id) or ("user", id); None when unknown."""
    if trip.rr_trip_id:
        try:
            resp = await client.get(
                f"{settings.RR_API_BASE}/potential_vehicles", headers=_auth_header(token),
                params={"where": json.dumps({"trip_id": trip.rr_trip_id, "vehicle_status": "Booked"}), "max_results": 1},
            )
            items = resp.json().get("_items", []) if resp.status_code == 200 else []
        except Exception as exc:
            logger.warning(f"[RR Owner] booking lookup failed for {trip.trip_number}: {exc}")
            items = []
        if items:
            company = str(items[0].get("vehicle_owner_company_id") or "")
            if company and company != RR_DEFAULT_VEHICLE_PROVIDER:
                return ("company", company)
            user = str(items[0].get("vehicle_owner_user_id") or "")
            if user:
                return ("user", user)
            if company:
                return None   # RR's own fallback provider: the real truck owner is unknown
    if trip.transporter_rr_company_id and trip.transporter_rr_company_id != RR_DEFAULT_VEHICLE_PROVIDER:
        return ("company", trip.transporter_rr_company_id)
    if getattr(trip, "transporter_rr_user_id", None):
        return ("user", trip.transporter_rr_user_id)      # an owner person with no company
    return None


async def fetch_owner_identities(owner: tuple[str, str], client: httpx.AsyncClient, token: str):
    """(the owner's current documents in RR, the company's _etag or None), or None when they cannot be read."""
    kind, owner_id = owner
    try:
        if kind == "company":
            resp = await client.get(f"{settings.RR_API_BASE}/companies/{owner_id}", headers=_auth_header(token))
        else:
            resp = await client.get(f"{settings.RR_API_BASE}/get_user_record_by_id", params={"record_id": owner_id},
                                    headers=_auth_header(token))
    except Exception as exc:
        logger.warning(f"[RR Owner] reading {kind} {owner_id} failed: {exc}")
        return None
    if resp.status_code != 200:
        logger.warning(f"[RR Owner] reading {kind} {owner_id}: HTTP {resp.status_code}")
        return None
    data = resp.json()
    return list(data.get("identities") or []), data.get("_etag")


_OWNER_ITEM_COLUMNS = {   # owner document key -> (photo column, number column, valid-till column)
    "Owner PAN": ("s1_pan", "s1_pan_number", None),
    "Owner Tax Declaration": ("s1_tax_declaration", None, "s1_tax_declaration_expiry"),
}


async def _push_owner_documents(trip, client: httpx.AsyncClient, token: str, db, send=None) -> tuple[bool, str | None]:
    """Send the truck owner's PAN / tax declaration to the owner of the trip's booking in RR (see above).

    Only a document this trip has not sent yet goes. The owner's current documents are read first and the new
    photo is merged in (RR replaces the whole list), so nothing else of his is lost; when they cannot be read,
    nothing is sent."""
    if not (trip.s1_pan or trip.s1_tax_declaration):
        return True, None
    owner = await find_vehicle_owner(trip, client, token)
    if owner is None:
        return False, "truck owner not known in RR (no owner on the booking) - owner documents not sent"
    kind, owner_id = owner
    synced = dict(trip.rr_synced_doc_urls or {})
    to_push = []
    for it in owner_doc_items(trip, kind):
        pending = owner_item_pending(it, synced, kind)
        if send is not None:   # after a first successful sync: only what changed and was saved since
            photo_col, number_col, expiry_col = _OWNER_ITEM_COLUMNS[it["key"]]
            pending = {"photo": pending["photo"] and send(photo_col),
                       "number": pending["number"] and bool(number_col) and send(number_col),
                       "expiry": pending["expiry"] and bool(expiry_col) and send(expiry_col)}
        if any(pending.values()):
            to_push.append((it, pending))
    if not to_push:
        return True, None
    current = await fetch_owner_identities(owner, client, token)
    if current is None:
        return False, f"could not read the truck owner's ({kind}) documents in RR - nothing sent"
    identities, etag = current

    sent_files: list[tuple[str, str]] = []
    for n, (it, pending) in enumerate(to_push):
        idx = next((i for i, e in enumerate(identities) if e.get("id_name") == it["id_name"]), None)
        entry = dict(identities[idx]) if idx is not None else {"id_name": it["id_name"]}
        if pending["photo"] and _rr_holds_file(db, it["front_url"], _side_photo(entry, "Front")):
            # RR already shows exactly this stored photo: nothing to upload, and its valid-till date stays (P7)
            pending = {**pending, "photo": False}
            to_push[n] = (it, pending)
        if it["key"] == "Owner PAN" and not (it["number"] or entry.get("number")):
            # RR refuses a PAN without its number: nothing is sent until Stage 1 has it.
            return False, "truck owner's PAN number is missing - add it in Stage 1, then sync again"
        if pending["photo"]:
            file_id = await _upload_file(it["front_url"], client, token)
            if not file_id:
                return False, f"{it['key']} upload to RR failed"
            entry["photos"] = _rebuild_positional_photos(entry.get("photos") or [], file_id, None)
            if it["key"] == "Owner Tax Declaration" and not it["expiry"]:
                # A new slip without a known valid-till date never keeps the old slip's date.
                entry.pop("expiry_date", None)
            sent_files.append((it["front_url"], file_id))
        if it["number"] and (send is None or pending["number"] or not entry.get("number")):
            entry["number"] = it["number"]
        if it["expiry"] and kind == "company" and (send is None or pending["expiry"]):
            entry["expiry_date"] = it["expiry"]
        if idx is None:
            identities.append(entry)
        else:
            identities[idx] = entry

    try:
        if kind == "company":
            resp = await client.patch(f"{settings.RR_API_BASE}/companies/{owner_id}", json={"identities": identities},
                                      headers={**_json_header(token), "If-Match": etag})
        else:
            clean = [{k: v for k, v in e.items() if k != "expiry_date"} for e in identities]
            resp = await client.post(f"{settings.RR_API_BASE}/users/save_identities",
                                     json={"user_id": owner_id, "identities": clean}, headers=_json_header(token))
    except Exception as exc:
        return False, f"saving the truck owner's documents failed: {exc}"
    if resp.status_code not in (200, 201):
        return False, f"saving the truck owner's ({kind}) documents: HTTP {resp.status_code}: {resp.text[:300]}"

    sent_by_url = dict(sent_files)
    for it, pending in to_push:
        if pending["photo"]:
            synced[f"{it['key']}::front"] = it["front_url"]
            setattr(trip, it["front_attr"], sent_by_url[it["front_url"]])
        if it["number"]:
            synced[f"{it['key']}::number"] = it["number"]
        if it["expiry"] and kind == "company":
            synced[f"{it['key']}::expiry"] = it["expiry"]
    trip.rr_synced_doc_urls = synced
    _mark_stored_as_sent(db, sent_files)
    db.commit()
    return True, None


async def fetch_owner_primary_bank(owner: tuple[str, str], client: httpx.AsyncClient, token: str):
    """(readable, record) of the truck owner's PRIMARY bank record in RR (banking_details: created_by_company for a
    company, created_by for a person). record is None when he has none; readable is False when RR could not be read."""
    kind, owner_id = owner
    where = {"created_by_company" if kind == "company" else "created_by": owner_id, "primary": True}
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/banking_details", headers=_auth_header(token),
                                params={"where": json.dumps(where), "max_results": 1})
    except Exception as exc:
        logger.warning(f"[RR Owner] bank lookup failed for {kind} {owner_id}: {exc}")
        return False, None
    if resp.status_code != 200:
        logger.warning(f"[RR Owner] bank lookup HTTP {resp.status_code} for {kind} {owner_id}")
        return False, None
    items = resp.json().get("_items") or []
    return True, (items[0] if items else None)


async def _push_owner_cheque(trip, client: httpx.AsyncClient, token: str, db) -> tuple[bool, str | None]:
    """Send the truck owner's cancelled cheque where RR web keeps it: the photo (account_identity) of the booking
    owner's PRIMARY bank record. Only a cheque this trip has not sent yet goes. When the owner has no bank record in
    RR nothing is created (user, 2026-11-13: RR's payments use the primary record and need its account number)."""
    url = trip.s1_cancelled_cheque
    synced = dict(trip.rr_synced_doc_urls or {})
    if not url or synced.get("Owner Cheque::front") == url:
        return True, None
    owner = await find_vehicle_owner(trip, client, token)
    if owner is None:
        return False, "truck owner not known in RR (no owner on the booking) - cheque not sent"
    readable, bank = await fetch_owner_primary_bank(owner, client, token)
    if not readable:
        return False, "could not read the truck owner's bank account in RR - cheque not sent"
    if bank is None:
        return False, "truck owner has no bank account in RR - add it in RR web, then sync again (cheque not sent)"
    if _rr_holds_file(db, url, bank.get("account_identity")):
        return True, None   # RR's primary bank record already shows exactly this stored cheque
    file_id = await _upload_file(url, client, token)
    if not file_id:
        return False, "Owner Cheque upload to RR failed"
    try:
        resp = await client.patch(f"{settings.RR_API_BASE}/banking_details/{bank['_id']}",
                                  json={"account_identity": file_id},
                                  headers={**_json_header(token), "If-Match": bank.get("_etag", "")})
    except Exception as exc:
        return False, f"saving the truck owner's cheque failed: {exc}"
    if resp.status_code not in (200, 201):
        return False, f"saving the truck owner's cheque: HTTP {resp.status_code}: {resp.text[:300]}"
    synced["Owner Cheque::front"] = url
    trip.rr_synced_doc_urls = synced
    _mark_stored_as_sent(db, [(url, file_id)])
    db.commit()
    return True, None


# The truck owner's documents a new trip takes from RR: (RR id_name, trip column, file prefix)
_OWNER_PHOTO_SLOTS = (
    ("PAN", "s1_pan", "pan"),
    ("Tax Declaration Slip", "s1_tax_declaration", "tax_decl"),
)


async def pull_owner_documents(db, trip, client: httpx.AsyncClient, token: str, *,
                               user, role_key: str, org_id) -> None:
    """Collect the truck owner's PAN (photo + number), tax declaration (photo + valid-till date) and cancelled cheque
    (photo of his primary bank record) from RR into our store, as RR web keeps them on the booking owner company
    (+ New Trip / Confirm Booking). A document we already store for him is not collected (ours stays, changes made
    in Stage 1 go to RR on the manual sync); one we do not have gets RR's copy, marked as already in RR. The trip
    then shows his stored documents. Company owners only; the booking owner must be the company our owner
    documents are stored under (else nothing is collected). The caller commits."""
    owner = await find_vehicle_owner(trip, client, token)
    if owner is None or owner[0] != "company":
        return
    if resolve_owner(db, trip, OWNER) != ("rr_company", owner[1]):
        logger.warning(f"[Collect Owner] {trip.trip_number}: booking owner {owner[1]} is not the trip's owner "
                       f"company {trip.transporter_rr_company_id} - nothing collected")
        return
    wanted = []
    for id_name, column, prefix in _OWNER_PHOTO_SLOTS:
        if stored_owner_document(db, trip, column) is None:
            wanted.append((id_name, column, prefix))
    cheque_wanted = stored_owner_document(db, trip, "s1_cancelled_cheque") is None
    if wanted:
        current = await fetch_owner_identities(owner, client, token)
        by_name = {e.get("id_name"): e for e in ((current[0] if current else None) or [])}
        for id_name, column, prefix in wanted:
            entry = by_name.get(id_name) or {}
            photos = [p for p in (entry.get("photos") or []) if p.get("photo")]
            photo = next((p for p in photos if (p.get("side") or "Front") == "Front"), photos[0] if photos else None)
            if not photo:
                continue
            if column == "s1_pan" and entry.get("number") and not trip.s1_pan_number:
                trip.s1_pan_number = str(entry["number"]).strip().upper()[:10]
            if column == "s1_tax_declaration" and entry.get("expiry_date") and not trip.s1_tax_declaration_expiry:
                # the full UTC date-time (taking only its first 10 characters gave the day before for times picked
                # before 05:30 AM India time)
                trip.s1_tax_declaration_expiry = from_rr(entry["expiry_date"])
            await _store_owner_rr_file(db, trip, client, token, str(photo["photo"]), column, prefix,
                                       user=user, role_key=role_key, org_id=org_id)
    if cheque_wanted:
        readable, bank = await fetch_owner_primary_bank(owner, client, token)
        if bank and bank.get("account_identity"):
            await _store_owner_rr_file(db, trip, client, token, str(bank["account_identity"]), "s1_cancelled_cheque",
                                       "cheque", user=user, role_key=role_key, org_id=org_id)
    db.flush()   # the app's sessions do not autoflush: the lookups below must see the rows stored here
    link_owner_documents(db, trip)


async def _store_owner_rr_file(db, trip, client, token, file_id: str, column: str, prefix: str, *,
                               user, role_key: str, org_id) -> None:
    got = await _download_rr_file(file_id, client, token)
    if got is None:
        return
    content, content_type, file_name = got
    upload = describe_upload(content, file_name, content_type)
    ext = Path(file_name).suffix or mimetypes.guess_extension(content_type) or ".jpg"
    url = f"/uploads/trips/{trip.id}/{prefix}_{uuid.uuid4().hex}{ext}"
    save_stage1_document(db, trip=trip, column=column, url_path=url, file_name=Path(url).name, upload=upload,
                         user=user, role_key=role_key, org_id=org_id, uploaded_via="rr_sync", rr_file_id=file_id)


async def _download_rr_file(file_id: str, client: httpx.AsyncClient, token: str):
    """(bytes, content type, file name) of an RR file (GET /files/{id}, base64 media), or None."""
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/files/{file_id}", headers=_auth_header(token))
    except Exception as exc:
        logger.warning(f"[RR Pull] GET /files/{file_id} exception: {exc}")
        return None
    if resp.status_code != 200:
        logger.warning(f"[RR Pull] GET /files/{file_id} HTTP {resp.status_code}")
        return None
    data = resp.json()
    file_obj = data.get("file")
    inner = file_obj if isinstance(file_obj, dict) else {}
    encoded = inner.get("file") if inner else file_obj
    if not encoded:
        return None
    try:
        content = base64.b64decode(encoded)
    except Exception:
        return None
    content_type = inner.get("content_type") or data.get("content_type") or "application/octet-stream"
    file_name = inner.get("filename") or data.get("file_name") or "rr_file"
    return content, content_type, file_name


def vehicle_doc_items(trip) -> list[dict]:
    """Shared by _sync_stage1_docs and the identity-status/override endpoints."""
    return [
        # RC is the only one of these 4 that RR web itself supports a back
        # side for — PUC/Fitness/Permit are front-only even there.
        {"id_name": "Registration Certificate", "front_url": trip.s1_rc,
         "back_url": trip.s1_rc_back,
         "front_attr": "rr_rc_file_id", "back_attr": "rr_rc_back_file_id",
         "number": trip.s1_rc_number},
        {"id_name": "PUC Certificate", "front_url": trip.s1_pollution, "back_url": None,
         "front_attr": "rr_puc_file_id", "back_attr": None,
         "number": trip.s1_puc_number},
        {"id_name": "Fitness Certificate", "front_url": trip.s1_fitness, "back_url": None,
         "front_attr": "rr_fitness_file_id", "back_attr": None,
         "number": trip.s1_fitness_number},
        {"id_name": "Permit", "front_url": trip.s1_permit, "back_url": None,
         "front_attr": "rr_permit_file_id", "back_attr": None,
         "number": trip.s1_permit_number},
    ]


async def _override_identity(
    entity, entity_collection: str, rr_id: str, item: dict,
    client: httpx.AsyncClient, token: str, db,
) -> tuple[bool, str | None]:
    """
    Explicit human action (LP/RR-ops tapping "Override" after previewing what RR
    already has): removes any existing identities[] entries for item['id_name']
    and replaces them with a fresh upload of our copy — unlike _push_identities'
    automatic skip-on-conflict behavior, this always writes.
    """
    if not item["front_url"]:
        return False, "No local document to upload for this doc type"

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
    # RR's current entry for this document: its other details (expiry date etc.) are kept, only the photos and - when
    # we have one - the number are replaced with ours (2026-11-20: the override used to write photos only and erased
    # the number, leaving RR with neither RR's nor our number).
    current = next((i for i in (data.get("identities") or []) if i.get("id_name") == item["id_name"]), {})
    identities = [i for i in (data.get("identities") or []) if i.get("id_name") != item["id_name"]]

    front_id = await _upload_file(item["front_url"], client, token)
    if not front_id:
        return False, "Front photo upload to RR failed"
    photos = [{"photo": front_id, "side": "Front"}]

    back_id = None
    if item["back_url"]:
        back_id = await _upload_file(item["back_url"], client, token)
        if back_id:
            photos.append({"photo": back_id, "side": "Back"})

    entry = {k: v for k, v in current.items() if k not in ("photos", "_id")}
    entry.update({"id_name": item["id_name"], "photos": photos})
    if item.get("number"):
        entry["number"] = item["number"]
    identities.append(entry)

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/{entity_collection}/{rr_id}",
            json={"identities": identities},
            headers={**_json_header(token), "If-Match": etag},
        )
    except Exception as exc:
        return False, f"PATCH {entity_collection} exception: {exc}"
    if patch_resp.status_code not in (200, 201):
        return False, f"PATCH {entity_collection} HTTP {patch_resp.status_code}: {patch_resp.text[:300]}"

    setattr(entity, item["front_attr"], front_id)
    if item["back_attr"] and back_id:
        setattr(entity, item["back_attr"], back_id)
    db.commit()
    return True, None


async def _sync_stage1_docs(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Push driver KYC docs (DL, Aadhaar) to users.identities[], vehicle compliance
    docs (RC, PUC, fitness, permit) to vehicles.identities[], and the truck owner's
    PAN / tax declaration to the vehicle owner of the booking (_push_owner_documents).
    Insurance and cancelled cheque have no RR field and are never pushed — same for
    the boolean checklist fields elsewhere in Stage 1-4, which have no RR equivalent.

    Trips created via the RR vehicle/driver picker (the current, and only, trip
    creation flow) set trip.rr_vehicle_id/rr_driver_id directly and never have a
    local Driver/Vehicle row — a local row is preferred when present (its cache
    columns are shared across all of that driver/vehicle's trips), falling back
    to pushing straight to RR using the picker id with the trip itself as the
    cache entity (trip.rr_dl_file_id etc., added alongside rr_vehicle_id/
    rr_driver_id for exactly this).
    """
    from app.models.vehicle import Vehicle
    from app.models.driver import Driver

    if not (trip.vehicle_id or trip.driver_id or trip.rr_vehicle_id or trip.rr_driver_id):
        return  # nothing assigned to this trip yet — leave as not_synced

    await _try_resolve_rr_ids(trip, client, token, db)

    vehicle = db.query(Vehicle).filter(Vehicle.id == trip.vehicle_id).first() if trip.vehicle_id else None
    driver  = db.query(Driver).filter(Driver.id == trip.driver_id).first()   if trip.driver_id  else None

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

    errors: list[str] = []
    attempted = False
    accepted: list[str] = []          # the Stage 1 parts RR accepted in this sync (rr_change_marks.S1_PARTS)
    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks). Per PART (driver / truck /
    # insurance / owner / cheque): a part that reached RR once sends only its changes, even when another part failed
    # (fc11 2026-11-25: a failed cheque kept the whole stage "never synced", so every sync sent all our older values
    # back over RR web's later changes).
    def part_synced(part):
        return rr_change_marks.s1_part_synced(trip, part)

    def part_send(part):
        return (lambda col: rr_change_marks.should_send(trip, col, True)) if part_synced(part) else None

    if driver_entity is not None:
        attempted = True
        ok, err = await _push_driver_identities(
            driver_entity, driver_rr_id, vehicle_rr_id, trip.transporter_rr_company_id,
            _only_changed_items(trip, driver_doc_items(trip), part_synced("driver")), client, token, db, trip,
        )
        if not ok:
            errors.append(f"Driver docs: {err}")
        else:
            accepted.append("driver")
    elif trip.driver_id:
        errors.append("Driver not found in RR — driver must exist in RR web first")

    if vehicle_entity is not None:
        attempted = True
        ok, err = await _push_identities(vehicle_entity, "vehicles", vehicle_rr_id,
                                          _only_changed_items(trip, vehicle_doc_items(trip), part_synced("vehicle")),
                                          client, token, db, trip)
        if not ok:
            errors.append(f"Vehicle docs: {err}")
        else:
            accepted.append("vehicle")

        send_ins = part_send("insurance")
        ok, err = await _push_vehicle_insurance(
            vehicle_entity, vehicle_rr_id,
            trip.s1_insurance_number if send_ins is None or send_ins("s1_insurance_number") else None,
            trip.s1_insurance if send_ins is None or send_ins("s1_insurance") else None,
            client, token, db, trip,
        )
        if not ok:
            errors.append(f"Insurance: {err}")
        else:
            accepted.append("insurance")
    elif trip.vehicle_id:
        errors.append("Vehicle not found in RR — vehicle must exist in RR web first")

    if trip.s1_pan or trip.s1_tax_declaration:
        attempted = True
        ok, err = await _push_owner_documents(trip, client, token, db, send=part_send("owner"))
        if not ok:
            errors.append(f"Owner docs: {err}")
        else:
            accepted.append("owner")

    if trip.s1_cancelled_cheque:
        attempted = True
        send_chq = part_send("cheque")
        if send_chq is None or send_chq("s1_cancelled_cheque"):
            ok, err = await _push_owner_cheque(trip, client, token, db)
            if not ok:
                errors.append(f"Owner cheque: {err}")
            else:
                accepted.append("cheque")
        else:
            accepted.append("cheque")   # nothing changed since RR took it

    if not attempted and not errors:
        return  # neither vehicle nor driver resolvable yet — nothing to do

    # The parts RR accepted are recorded and their marks cleared even when another part failed.
    rr_change_marks.mark_s1_parts_ok(trip, accepted)
    if errors:
        trip.rr_s1_sync_status = "failed"
        trip.rr_s1_sync_error = "; ".join(errors)[:800]
    else:
        trip.rr_s1_sync_status = "synced"
        trip.rr_s1_synced_at = datetime.utcnow()
        trip.rr_s1_sync_error = None
        rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[1])
    db.commit()
    logger.info(f"[RR Sync S1] Trip {trip.trip_number} stage1 doc sync: status={trip.rr_s1_sync_status}")


# ── Stage 2: Loading slip ─────────────────────────────────────────────────────

async def _sync_loading_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Upload loading slip to RR /files then POST /post_loading_slip.
    Writes to rr_s2_sync_status (dedicated) — NOT just the legacy rr_sync_status,
    which stages 3/5 also write to and would otherwise stomp this stage's own
    result once they run afterward in the same sync batch.
    """
    if not trip.s2_loading_slip_url:
        return

    if not trip.rr_trip_id:
        logger.info(f"[RR Sync] Trip {trip.trip_number} has no rr_trip_id yet — pending trip creation")
        trip.rr_s2_sync_status = "pending_trip_creation"
        db.commit()
        return

    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks). Files copied from the disk have no
    # RR file id yet, so F6 alone would send them again although RR has them.
    if not rr_change_marks.should_send(trip, "s2_loading_slip_url", trip.rr_s2_sync_status == "synced"):
        return

    rr_file_id, is_new = await _rr_file_for(trip.s2_loading_slip_url, client, token, db)
    if not rr_file_id:
        trip.rr_s2_sync_status = "failed"
        trip.rr_s2_sync_error = "Loading slip file upload to RR failed"
        db.commit()
        return
    if not is_new:
        # RR already holds this exact slip: nothing to send (F6)
        trip.rr_s2_sync_status = "synced"
        trip.rr_s2_sync_error = None
        rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[2])
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
        trip.rr_s2_sync_status = "failed"
        trip.rr_s2_sync_error = f"post_loading_slip exception: {exc}"[:500]
        db.commit()
        return

    if resp.status_code in (200, 201):
        trip.rr_sync_status = "loading_slip_synced"
        trip.rr_synced_at = datetime.utcnow()
        trip.rr_sync_error = None
        trip.rr_s2_sync_status = "synced"
        trip.rr_s2_synced_at = datetime.utcnow()
        trip.rr_s2_sync_error = None
        rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[2])
        _mark_stored_as_sent(db, [(trip.s2_loading_slip_url, rr_file_id)])
        db.commit()
        logger.info(
            f"[RR Sync] Trip {trip.trip_number} loading slip synced (rr_file_id={rr_file_id})"
        )
    else:
        logger.error(
            f"[RR Sync] post_loading_slip failed ({resp.status_code}): {resp.text[:300]}"
        )
        trip.rr_s2_sync_status = "failed"
        trip.rr_s2_sync_error = f"HTTP {resp.status_code}: {resp.text[:400]}"
        db.commit()


# ── Stage 3: Bilty + weight receipt + material docs ───────────────────────────

async def _sync_stage3(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    PATCH the RR parcel with Stage 3 documents:
      - documents.eway_bill           — number + issue/expiry date + photo
      - documents.weight_receipt     — loaded weight kg + slip photo
      - documents.consignor_invoice  — first 2 material doc photos + invoice number
      - loading.truck_reach_datetime / loading.start_datetime
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
    new_files: list[tuple[str, str]] = []   # uploaded now; marked as sent once RR saved the parcel
    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks; RR merges nested fields on PATCH).
    synced_before = trip.rr_s3_sync_status == "synced"
    send = lambda col: rr_change_marks.should_send(trip, col, synced_before)   # noqa: E731
    weight_changed = send("s3_loaded_truck_weight_kg") or send("s3_loaded_truck_weight_unit")

    async def rr_file(url):
        file_id, is_new = await _rr_file_for(url, client, token, db)
        if file_id and is_new:
            new_files.append((url, file_id))
        return file_id

    # ── E-way bill ────────────────────────────────────────────────────────────
    # documents.eway_bill on RR's parcels resource — confirmed via RR's own
    # source (settings.py) and its Angular upload-ewaybill component's PATCH shape.
    eway_bill: dict = {}
    if trip.s3_eway_bill_number and send("s3_eway_bill_number"):
        eway_bill["number"] = trip.s3_eway_bill_number
    if trip.s3_eway_bill_url and send("s3_eway_bill_url"):
        rr_eway_id = await rr_file(trip.s3_eway_bill_url)
        if rr_eway_id:
            eway_bill["photos"] = [{"photo": rr_eway_id, "side": "Front"}]
    if trip.s3_eway_bill_issue_date and send("s3_eway_bill_issue_date"):
        eway_bill["issue_date"] = trip.s3_eway_bill_issue_date.strftime("%Y-%m-%dT%H:%M:%S")
    if trip.s3_eway_bill_expiry_date and send("s3_eway_bill_expiry_date"):
        eway_bill["expiry_date"] = trip.s3_eway_bill_expiry_date.strftime("%Y-%m-%dT%H:%M:%S")
    if eway_bill:
        documents["eway_bill"] = eway_bill

    # ── Weight receipt ────────────────────────────────────────────────────────
    weight_receipt: dict = {}
    if trip.s3_loaded_truck_weight_kg and weight_changed:
        try:
            weight_receipt["truck_weight_after_loading"] = float(trip.s3_loaded_truck_weight_kg)
        except (ValueError, TypeError):
            pass
    if trip.s3_loaded_weight_slip_url and send("s3_loaded_weight_slip_url"):
        rr_slip_id = await rr_file(trip.s3_loaded_weight_slip_url)
        if rr_slip_id:
            weight_receipt["photos"] = [{"photo": rr_slip_id, "side": "Front"}]
    if weight_receipt:
        documents["weight_receipt"] = weight_receipt

    # ── Consignor invoice (material docs + invoice number) ──────────────────────
    # RR's schema allows up to 2 photos here, but RR's own web UI only ever
    # reads/writes index 0 (parcel-documents.component.ts) — so only the first
    # doc is actually used on RR's side. We mirror that with a single doc.
    consignor_invoice: dict = {}
    if trip.s3_material_doc_urls and send("s3_material_doc_urls"):
        try:
            mat_urls = (
                json.loads(trip.s3_material_doc_urls)
                if isinstance(trip.s3_material_doc_urls, str)
                else trip.s3_material_doc_urls
            )
        except Exception:
            mat_urls = []
        photos = []
        for url in mat_urls[:1]:
            rr_file_id = await rr_file(url)
            if rr_file_id:
                photos.append({"photo": rr_file_id, "side": "Front"})
        if photos:
            consignor_invoice["photos"] = photos
    if trip.s3_invoice_number and send("s3_invoice_number"):
        consignor_invoice["number"] = trip.s3_invoice_number.upper()
    if consignor_invoice:
        documents["consignor_invoice"] = consignor_invoice

    # ── Loading reach/start datetimes ───────────────────────────────────────────
    loading: dict = {}
    if trip.s3_vehicle_reach_datetime and send("s3_vehicle_reach_datetime"):
        loading["truck_reach_datetime"] = trip.s3_vehicle_reach_datetime.strftime("%Y-%m-%dT%H:%M:%S")
    if trip.s3_loading_start_datetime and send("s3_loading_start_datetime"):
        loading["start_datetime"] = trip.s3_loading_start_datetime.strftime("%Y-%m-%dT%H:%M:%S")

    # ── Actual Dharam Kanta weight ────────────────────────────────────────────
    # RR's "Actual Dharam Kanta Weight" on the web UI is the top-level
    # parcels.actual_kanta_weight field — NOT documents.weight_receipt above
    # (that's just the receipt photo's metadata). Mirrors our loaded truck weight.
    actual_kanta_weight = None
    if trip.s3_loaded_truck_weight_kg and weight_changed:
        try:
            unit_map = {"tons": "TONNES", "kg": "KILOGRAMS"}
            actual_kanta_weight = {
                "weight": float(trip.s3_loaded_truck_weight_kg),
                "weight_unit": unit_map.get((trip.s3_loaded_truck_weight_unit or "kg").lower(), "KILOGRAMS"),
            }
        except (ValueError, TypeError):
            pass

    # ── Real invoice value (entered once the actual invoice is uploaded,
    # replacing the placeholder sent at trip creation) ──────────────────────
    if trip.s3_actual_invoice_value and send("s3_actual_invoice_value"):
        patch_body_cost = float(trip.s3_actual_invoice_value)
    else:
        patch_body_cost = None

    # ── PATCH parcel ──────────────────────────────────────────────────────────
    patch_body: dict = {}
    if actual_kanta_weight:
        patch_body["actual_kanta_weight"] = actual_kanta_weight
    if documents:
        patch_body["documents"] = documents
    if loading:
        patch_body["loading"] = loading
    if patch_body_cost is not None:
        patch_body["cost"] = patch_body_cost
    if not patch_body:
        logger.info(f"[RR Sync S3] Trip {trip.trip_number} — no S3 data to sync, skipping")
        return

    try:
        patch_resp = await client.patch(
            f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
            json=patch_body,
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
    rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[3])
    _mark_stored_as_sent(db, new_files)
    db.commit()
    logger.info(
        f"[RR Sync S3] Trip {trip.trip_number} Stage 3 synced → parcel {trip.rr_parcel_id}"
    )


# ── Stage 4: Fuel/diesel receipt ───────────────────────────────────────────────

async def _sync_stage4_fuel_slip(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    Independent pushes for Stage 4:
      - fuel_slip photo   → POST /post_loading_slip (trip_documents, "Fuel Slip")
      - loading.end_datetime (vehicle exit) → PATCH /parcels/{id} (needs its own
        etag fetch — different RR endpoint from post_loading_slip entirely)
      - bilty number      → GET /get_and_update_bilty_number (RR's own dedicated,
        idempotency-guarded assignment endpoint — NOT a raw PATCH, matches RR's
        own web UI, which uses this same endpoint from its "Generate Bilty" dialog)
      - manual bilty photo → PATCH /parcels/{id}, documents.manual_bilty.photos[]
        (note the photo key is "manual_photo", not "photo" like every other doc type)
    Each part runs independently of the others being present.
    """
    if (
        not trip.s4_diesel_receipt_url
        and not trip.s4_vehicle_exit_datetime
        and not trip.s4_bilty_number
        and not trip.s4_bilty_url
    ):
        return

    errors: list[str] = []
    attempted = False
    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks). Files copied from the disk have no
    # RR file id yet, so F6 alone would send them again although RR has them.
    s4_synced_before = trip.rr_s4_sync_status == "synced"

    # ── Fuel slip photo ──────────────────────────────────────────────────────────
    if trip.s4_diesel_receipt_url and rr_change_marks.should_send(trip, "s4_diesel_receipt_url", s4_synced_before):
        attempted = True
        if not trip.rr_trip_id:
            trip.rr_s4_sync_status = "pending_trip_creation"
            db.commit()
            return
        rr_file_id, is_new = await _rr_file_for(trip.s4_diesel_receipt_url, client, token, db)
        if not rr_file_id:
            errors.append("Diesel receipt file upload to RR failed")
        elif not is_new:
            pass   # RR already holds this exact fuel slip: nothing to send (F6)
        else:
            try:
                resp = await client.post(
                    f"{settings.RR_API_BASE}/post_loading_slip",
                    json={"trip_id": trip.rr_trip_id, "fuel_slip": rr_file_id},
                    headers=_json_header(token),
                )
            except Exception as exc:
                errors.append(f"post_loading_slip exception: {exc}")
            else:
                if resp.status_code not in (200, 201):
                    errors.append(f"post_loading_slip HTTP {resp.status_code}: {resp.text[:300]}")
                else:
                    _mark_stored_as_sent(db, [(trip.s4_diesel_receipt_url, rr_file_id)])
                    logger.info(f"[RR Sync S4] Trip {trip.trip_number} fuel slip synced (rr_file_id={rr_file_id})")

    # ── Vehicle exit datetime (loading.end_datetime) ─────────────────────────────
    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks).
    if trip.s4_vehicle_exit_datetime and rr_change_marks.should_send(trip, "s4_vehicle_exit_datetime",
                                                                     trip.rr_s4_sync_status == "synced"):
        attempted = True
        if not trip.rr_parcel_id:
            trip.rr_s4_sync_status = "pending_trip_creation"
            db.commit()
            return
        etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
        if not etag:
            errors.append("Could not fetch parcel etag from RR for loading.end_datetime")
        else:
            try:
                patch_resp = await client.patch(
                    f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
                    json={"loading": {"end_datetime": trip.s4_vehicle_exit_datetime.strftime("%Y-%m-%dT%H:%M:%S")}},
                    headers={**_json_header(token), "If-Match": etag},
                )
            except Exception as exc:
                errors.append(f"PATCH parcel (loading.end_datetime) exception: {exc}")
            else:
                if patch_resp.status_code not in (200, 201):
                    errors.append(f"PATCH parcel (loading.end_datetime) HTTP {patch_resp.status_code}: {patch_resp.text[:300]}")
                else:
                    trip.rr_parcel_etag = patch_resp.json().get("_etag", etag)
                    logger.info(f"[RR Sync S4] Trip {trip.trip_number} loading.end_datetime synced")

    # ── Bilty number (RR's own dedicated, idempotency-guarded endpoint) ──────────
    if trip.s4_bilty_number:
        attempted = True
        if not trip.rr_parcel_id:
            trip.rr_s4_sync_status = "pending_trip_creation"
            db.commit()
            return
        params = {"parcel_id": trip.rr_parcel_id, "bilty_number": trip.s4_bilty_number}
        if trip.s4_bilty_date:
            params["bilty_date"] = trip.s4_bilty_date.strftime("%Y-%m-%dT%H:%M:%S")
        try:
            bilty_resp = await client.get(
                f"{settings.RR_API_BASE}/get_and_update_bilty_number",
                params=params,
                headers=_auth_header(token),
            )
        except Exception as exc:
            errors.append(f"get_and_update_bilty_number exception: {exc}")
        else:
            if bilty_resp.status_code in (200, 201):
                trip.s4_bilty_synced = True
                logger.info(f"[RR Sync S4] Trip {trip.trip_number} bilty number synced")
            elif bilty_resp.status_code == 400 and "already exists" in bilty_resp.text.lower():
                # RR says "already exists" both when THIS parcel already has its bilty (a re-sync) and when the
                # number is used by ANOTHER parcel of the company. Only RR's parcel tells them apart: synced (and
                # locked) only when the parcel really holds our number (fix 2026-11-14 - before, a number taken by
                # another trip was marked synced and locked while RR's parcel had no bilty at all).
                rr_bilty = await _parcel_bilty(trip.rr_parcel_id, client, token)
                if rr_bilty is not None and str(rr_bilty) == str(trip.s4_bilty_number):
                    trip.s4_bilty_synced = True
                    logger.info(f"[RR Sync S4] Trip {trip.trip_number} bilty number already set on RR — treating as synced")
                elif rr_bilty is None:
                    errors.append("RR says the bilty number already exists; could not read RR's parcel to confirm - sync again")
                elif rr_bilty:
                    errors.append(f"RR already holds bilty number {rr_bilty} for this trip (ours: {trip.s4_bilty_number})")
                else:
                    errors.append(f"Bilty number {trip.s4_bilty_number} is already used by another trip of this "
                                  f"company in RR - enter a different bilty number")
            else:
                errors.append(f"get_and_update_bilty_number HTTP {bilty_resp.status_code}: {bilty_resp.text[:300]}")

    # ── Manual bilty photo ────────────────────────────────────────────────────────
    if trip.s4_bilty_url and rr_change_marks.should_send(trip, "s4_bilty_url", s4_synced_before):
        attempted = True
        if not trip.rr_parcel_id:
            trip.rr_s4_sync_status = "pending_trip_creation"
            db.commit()
            return
        rr_bilty_photo_id, is_new = await _rr_file_for(trip.s4_bilty_url, client, token, db)
        if not rr_bilty_photo_id:
            errors.append("Manual bilty photo upload to RR failed")
        elif not is_new:
            pass   # RR already holds this exact bilty photo: nothing to send (F6)
        else:
            etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
            if not etag:
                errors.append("Could not fetch parcel etag from RR for manual_bilty photo")
            else:
                try:
                    patch_resp = await client.patch(
                        f"{settings.RR_API_BASE}/parcels/{trip.rr_parcel_id}",
                        json={"documents": {"manual_bilty": {"photos": [{"manual_photo": rr_bilty_photo_id, "side": "Front"}]}}},
                        headers={**_json_header(token), "If-Match": etag},
                    )
                except Exception as exc:
                    errors.append(f"PATCH parcel (manual_bilty) exception: {exc}")
                else:
                    if patch_resp.status_code not in (200, 201):
                        errors.append(f"PATCH parcel (manual_bilty) HTTP {patch_resp.status_code}: {patch_resp.text[:300]}")
                    else:
                        trip.rr_parcel_etag = patch_resp.json().get("_etag", etag)
                        _mark_stored_as_sent(db, [(trip.s4_bilty_url, rr_bilty_photo_id)])
                        logger.info(f"[RR Sync S4] Trip {trip.trip_number} manual bilty photo synced")

    if not attempted:
        return

    if errors:
        trip.rr_s4_sync_status = "failed"
        trip.rr_s4_sync_error = "; ".join(errors)[:800]
    else:
        trip.rr_s4_sync_status = "synced"
        trip.rr_s4_synced_at = datetime.utcnow()
        trip.rr_s4_sync_error = None
        rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[4])
    db.commit()


# ── Stage 5: POD ──────────────────────────────────────────────────────────────

async def _sync_stage5(trip, client: httpx.AsyncClient, token: str, db) -> None:
    """
    PATCH the RR parcel with:
      - documents.pod.{datetime, photos}  — POD photo (no "side" key — matches
        rr_kanpur's verified shape, unlike weight_receipt/consignor_invoice which do use it)
      - unloading.halting_charge          — halting charge, NOT under documents
      - unloading.truck_reach_datetime / start_datetime / end_datetime
    """
    if not trip.rr_parcel_id:
        logger.info(f"[RR Sync S5] Trip {trip.trip_number} has no rr_parcel_id yet — pending trip creation")
        trip.rr_s5_sync_status = "pending_trip_creation"
        db.commit()
        return

    has_unloading_times = (
        trip.s5_vehicle_reach_datetime or trip.s5_unloading_start_datetime or trip.s5_unloading_end_datetime
    )
    if not trip.s5_pod_url and trip.s5_halting_charge is None and not has_unloading_times:
        return

    etag = await _fetch_parcel_etag(trip.rr_parcel_id, client, token)
    if not etag:
        logger.error(f"[RR Sync S5] Cannot fetch parcel etag for trip {trip.trip_number}")
        trip.rr_s5_sync_status = "failed"
        trip.rr_s5_sync_error = "Could not fetch parcel etag from RR"
        db.commit()
        return

    patch_body: dict = {}
    # Changed and saved -> sent; saved but not changed -> not sent (rr_change_marks; RR merges nested fields on PATCH).
    synced_before = trip.rr_s5_sync_status == "synced"
    send = lambda col: rr_change_marks.should_send(trip, col, synced_before)   # noqa: E731
    rr_pod_id, pod_is_new = None, False

    if trip.s5_pod_url and send("s5_pod_url"):
        rr_pod_id, pod_is_new = await _rr_file_for(trip.s5_pod_url, client, token, db)
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

    unloading: dict = {}
    if trip.s5_halting_charge is not None and send("s5_halting_charge"):
        unloading["halting_charge"] = float(trip.s5_halting_charge)
        # As RR web's unloading dialog saves a typed amount (user, 2026-11-24). Off for 0: RR's verify asks for an
        # amount whenever the override is on.
        unloading["halting_override"] = unloading["halting_charge"] > 0
    if trip.s5_vehicle_reach_datetime and send("s5_vehicle_reach_datetime"):
        unloading["truck_reach_datetime"] = trip.s5_vehicle_reach_datetime.strftime("%Y-%m-%dT%H:%M:%S")
    if trip.s5_unloading_start_datetime and send("s5_unloading_start_datetime"):
        unloading["start_datetime"] = trip.s5_unloading_start_datetime.strftime("%Y-%m-%dT%H:%M:%S")
    if trip.s5_unloading_end_datetime and send("s5_unloading_end_datetime"):
        unloading["end_datetime"] = trip.s5_unloading_end_datetime.strftime("%Y-%m-%dT%H:%M:%S")
    if unloading:
        patch_body["unloading"] = unloading

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
        rr_change_marks.clear(trip, rr_change_marks.STAGE_COLUMNS[5])
        if trip.s5_pod_url and pod_is_new:
            _mark_stored_as_sent(db, [(trip.s5_pod_url, rr_pod_id)])
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
    2: ("rr_s2_sync_status", "rr_s2_sync_error"),
    3: ("rr_s3_sync_status", "rr_s3_sync_error"),
    4: ("rr_s4_sync_status", "rr_s4_sync_error"),
    5: ("rr_s5_sync_status", "rr_s5_sync_error"),
}
_AUTH_REQUIRED_MSG = "RR login required — ask LP or RR Ops to sign in to RR"

# ── One sync per trip at a time (migration 112) ─────────────────────────────────
# Two syncs of the same trip at once both PATCHed RR's parcel and RR refused one (412), leaving a failed stage although
# RR had the data. A sync claims the trip with one short UPDATE (no DB connection held during RR calls); another sync
# of the same trip waits for it. The claim expires by itself (a crashed sync cannot block the trip).
SYNC_LOCK_MINUTES = 10
SYNC_LOCK_WAIT_SECONDS = 240
SYNC_BUSY_MSG = "Another sync of this trip is still running - press Sync again in a minute."


def _claim_trip_sync(db, trip_id) -> bool:
    row = db.execute(text(
        "UPDATE trips SET rr_sync_lock_until = now() + make_interval(mins => :m) "
        "WHERE id = :id AND (rr_sync_lock_until IS NULL OR rr_sync_lock_until < now()) RETURNING id"),
        {"id": str(trip_id), "m": SYNC_LOCK_MINUTES}).first()
    db.commit()
    return row is not None


def _release_trip_sync(db, trip_id) -> None:
    try:
        db.rollback()
        db.execute(text("UPDATE trips SET rr_sync_lock_until = NULL WHERE id = :id"), {"id": str(trip_id)})
        db.commit()
    except Exception:
        logger.exception(f"[RR Sync] could not release the sync claim of trip {trip_id} (expires by itself)")


async def _wait_and_claim_trip_sync(db, trip_id) -> bool:
    """True once this sync owns the trip; False when another sync kept it for SYNC_LOCK_WAIT_SECONDS."""
    waited = 0
    while not _claim_trip_sync(db, trip_id):
        if waited >= SYNC_LOCK_WAIT_SECONDS:
            return False
        await asyncio.sleep(2)
        waited += 2
    return True


# ── Plain-language sync errors ──────────────────────────────────────────────────
# Technical failures (RR unreachable, RR's etag / concurrency refusals, RR server errors) are shown in words a user can
# act on; RR's own business messages (e.g. a bilty number already used) are kept as they are.
RR_UNREACHABLE_MSG = "RR server could not be reached - nothing more was sent. Press Sync again in a few minutes."
RR_CHANGED_MSG = "The trip was changed in RR at the same moment - press Sync again."
RR_SERVER_ERROR_MSG = "RR server had an error - press Sync again later. If it keeps failing, tell the RR team."


def friendly_sync_error(err: str | None) -> str | None:
    if not err:
        return err
    low = err.lower()
    if any(s in low for s in ("could not fetch parcel etag", "all connection attempts failed", "connecterror",
                              "connection refused", "timed out", "timeout", "could not reach rr",
                              "name or service not known", "temporarily unavailable")):
        return RR_UNREACHABLE_MSG
    if "http 412" in low or "etags don't match" in low or "etag" in low and "match" in low:
        return RR_CHANGED_MSG
    if any(f"http {c}" in low for c in (500, 502, 503, 504)):
        return RR_SERVER_ERROR_MSG
    if "http 401" in low:
        return _AUTH_REQUIRED_MSG
    return err


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
    claimed = False
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
            status_field, error_field = _STAGE_STATUS_FIELDS[stage]
            setattr(trip, status_field, "auth_required")
            setattr(trip, error_field, _AUTH_REQUIRED_MSG)
            db.commit()
            logger.info(f"[RR Sync Stage {stage}] Trip {trip.trip_number} — no RR session available, marked auth_required")
            return

        status_field, error_field = _STAGE_STATUS_FIELDS[stage]
        if not await _wait_and_claim_trip_sync(db, trip.id):
            setattr(trip, status_field, "failed")
            setattr(trip, error_field, SYNC_BUSY_MSG)
            db.commit()
            return
        claimed = True
        db.refresh(trip)   # what the previous sync of this trip left (its "already sent" marks)
        # No RR trip (its creation failed) or a cancelled trip: send nothing - Stage 1 papers used to reach the driver /
        # truck / owner records even without an RR trip (user, 2026-11-25). For every role and every caller.
        stop = ("Trip cancelled - nothing is synced to RR web" if trip.status == "cancelled"
                else "Trip creation failed on RR web - nothing is synced" if not trip.rr_trip_id else None)
        if stop:
            setattr(trip, status_field, "failed")
            setattr(trip, error_field, stop)
            db.commit()
            logger.info(f"[RR Sync Stage {stage}] Trip {trip.trip_number} not synced: {stop}")
            return
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
            # RR web's changes were taken once when Sync was pressed (/api/rr/sync/retry - user 2026-11-25: one check per
            # press, not one more per stage). The light guard below still stops a send onto a changed / cancelled booking.
            # Never send anything for a cancelled trip / booking, or when RR's booked truck is not ours any more
            # (booking changed in RR web) - papers would land on the wrong records (md/RR_BOOKING_CANCEL_RULES.md).
            from app.services.rr_booking_service import booking_guard
            blocked = await booking_guard(trip, client, token)
            if blocked:
                setattr(trip, status_field, "failed")
                setattr(trip, error_field, blocked)
                db.commit()
                logger.info(f"[RR Sync Stage {stage}] Trip {trip.trip_number} not synced: {blocked}")
                return
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
        raw = getattr(trip, error_field)
        nice = friendly_sync_error(raw)
        if nice != raw:
            logger.info(f"[RR Sync Stage {stage}] Trip {trip.trip_number} error shown as plain text; was: {raw}")
            setattr(trip, error_field, nice)
            db.commit()
    except Exception as exc:
        logger.exception(f"[RR Sync Stage {stage}] Unexpected error for trip {trip_id}: {exc}")
    finally:
        if claimed:
            _release_trip_sync(db, trip_id)
        db.close()


# ── Top-level entry point (sync button) ──────────────────────────────────────────

async def sync_all_to_rr(trip_id: str, rr_token: str | None = None) -> None:
    """
    Background task: sync ALL available trip data to RR in one shot.
    Called by the manual sync button on the trip screen.

    rr_token: LP/RR-ops's RR access token (from POST /auth/login, or the org's
              auto-refreshing session via rr_org_token_service). Required —
              the sync fails gracefully (rr_sync_status='failed') if omitted.

    Sequence: trip must already be in RR (via Complete Trip); then re-runs every
    stage's sync function (S1 docs, S2 loading slip, S3 docs+loading times,
    S4 fuel slip+exit time, S5 POD+unloading times) — each is a no-op if that
    stage has nothing new to push.
    """
    if not settings.RR_SYNC_ENABLED:
        return

    from app.database import SessionLocal
    from app.models.trip import Trip
    from app.models.company import Organization

    db = SessionLocal()
    claimed = False
    try:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            logger.warning(f"[RR Sync All] Trip {trip_id} not found")
            return

        token = rr_token
        if not token:
            trip.rr_sync_status = "failed"
            trip.rr_sync_error = (
                "RR access token not available — an LP/RR-ops user with an active RR session must trigger this sync"
            )
            db.commit()
            logger.error(f"[RR Sync All] No RR token for trip {trip.trip_number}")
            return

        if not await _wait_and_claim_trip_sync(db, trip.id):
            trip.rr_sync_status = "failed"
            trip.rr_sync_error = SYNC_BUSY_MSG
            db.commit()
            return
        claimed = True
        db.refresh(trip)

        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:

            # ── Trip must already exist in RR via complete-trip ────────────────
            if not trip.rr_parcel_id:
                logger.info(
                    f"[RR Sync All] Trip {trip.trip_number} not yet in RR — "
                    f"use Complete Trip button to push via POST /create_trip"
                )
                return

            await rr_follow_service.follow_trips(db, [trip], client, token, claim=False)
            db.refresh(trip)
            from app.services.rr_booking_service import booking_guard
            blocked = await booking_guard(trip, client, token)
            if blocked:
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = blocked
                db.commit()
                logger.info(f"[RR Sync All] Trip {trip.trip_number} not synced: {blocked}")
                return

            await _sync_stage1_docs(trip, client, token, db)
            await _sync_loading_slip(trip, client, token, db)
            await _sync_stage3(trip, client, token, db)
            await _sync_stage4_fuel_slip(trip, client, token, db)
            await _sync_stage5(trip, client, token, db)
        changed = False
        for _, error_field in _STAGE_STATUS_FIELDS.values():
            raw = getattr(trip, error_field)
            nice = friendly_sync_error(raw)
            if nice != raw:
                setattr(trip, error_field, nice)
                changed = True
        if changed:
            db.commit()

    except Exception as exc:
        logger.exception(f"[RR Sync All] Unexpected error for trip {trip_id}: {exc}")
        try:
            trip = db.query(Trip).filter(Trip.id == trip_id).first()
            if trip:
                trip.rr_sync_status = "failed"
                trip.rr_sync_error = friendly_sync_error(f"Unexpected error: {str(exc)[:400]}")
                db.commit()
        except Exception:
            pass
    finally:
        if claimed:
            _release_trip_sync(db, trip_id)
        db.close()


