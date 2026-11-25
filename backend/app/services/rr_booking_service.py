"""Cancel booking / re-book / cancel trip (md/RR_BOOKING_CANCEL_RULES.md, user decisions 2026-11-20).

Each action is sent to RR at once (no separate sync) and our trip is changed only after RR accepted it:
- cancel booking: RR `cancel_vehicle_booking_by_trip_owner` {trip_id, cancel_remark}; refused for ever once a loaded
  weight / weight slip exists in RR or in our trip (same as RR web, whose Loading dialog cannot remove a weight);
- re-book: RR web's own booking order - truck offer -> offline price -> award -> driver on the truck's crew -> book;
- cancel trip: RR `cancel_trip_for_non_placement` (only when no truck is booked). Its reason is kept in our database
  only (user, 2026-11-20); the cancel-booking reason also goes to RR as cancel_remark.
On cancel booking the old truck, driver and owner leave the trip completely (papers, numbers, "already sent" marks,
cached RR file ids, Stage 2-3 truck checks, GPS link), so nothing of theirs can ever be sent to the next booking's
records (lesson of F10: owner papers went to the driver's record).
"""
import json
import logging

import httpx
import jwt

from app.config import settings
from app.core.document_map import UPLOAD_COLUMNS
from app.services import rr_change_marks

logger = logging.getLogger(__name__)

CSR_ROLES = {"CSR", "CSR Supervisor"}
BOOKING_CANCELLED = "booking_cancelled"
REBOOKED = "rebooked"
BOOKING_REASON_MAX = 500          # RR web's Cancel Booking box (maxlength 500)
TRIP_REASON_MAX = 1000            # our database only
WEIGHT_RECORDED_MSG = "The truck is loaded (weight recorded), so this booking can't be cancelled."

# Every "already sent" key of a Stage 1 document (driver, truck, owner) in trips.rr_synced_doc_urls.
STAGE1_SYNC_KEY_PREFIXES = (
    "Driving Licence::", "Aadhaar Card::", "Registration Certificate::", "PUC Certificate::",
    "Fitness Certificate::", "Permit::", "Insurance::", "Owner PAN::", "Owner Tax Declaration::", "Owner Cheque::",
)
# The trip's cached RR file ids of Stage 1 documents.
STAGE1_RR_FILE_ID_COLUMNS = (
    "rr_dl_file_id", "rr_dl_back_file_id", "rr_aadhaar_file_id", "rr_aadhaar_back_file_id", "rr_pan_file_id",
    "rr_tax_declaration_file_id", "rr_rc_file_id", "rr_rc_back_file_id", "rr_puc_file_id", "rr_fitness_file_id",
    "rr_permit_file_id", "rr_insurance_file_id",
)
STAGE1_NUMBER_COLUMNS = (
    "s1_driver_name", "s1_driver_phone", "s1_driving_license", "s1_aadhaar", "s1_rc_number", "s1_puc_number",
    "s1_fitness_number", "s1_permit_number", "s1_insurance_number", "s1_pan_number", "s1_tax_declaration_expiry",
)
# Stage 2 / 3 values that belong to the booked truck (user decision: the loading slip, e-way bill and invoice stay).
TRUCK_STAGE_COLUMNS = (
    "s2_specs_verified", "s2_docs_verified", "s2_driver_docs_valid", "s2_entry_permission", "s2_verified_at",
    "s2_dharam_kanta_loc", "s2_empty_weight_kg", "s2_empty_weight_unit",
    "s3_driver_parked", "s3_docs_submitted", "s3_security_verified", "s3_driver_exited_cabin", "s3_wheel_stoppers",
    "s3_safety_gear", "s3_vehicle_reach_datetime", "s3_empty_truck_weight_kg", "s3_empty_truck_weight_unit",
)
BOOKING_COLUMNS = ("rr_vehicle_id", "vehicle_number", "rr_driver_id", "driver_id", "transporter_rr_company_id",
                   "transporter_rr_user_id", "rr_booking_id")


# ── Checks ──────────────────────────────────────────────────────────────────────

def token_roles(token: str | None) -> list[str]:
    """The roles inside an RR access token (RR's JWT 'roles' claim). Read only - RR checks the signature itself."""
    if not token:
        return []
    try:
        claims = jwt.decode(token, options={"verify_signature": False})
    except Exception:
        return []
    roles = claims.get("roles") or []
    return [str(r) for r in roles] if isinstance(roles, list) else []


def is_csr_token(token: str | None) -> bool:
    return bool(CSR_ROLES & set(token_roles(token)))


def weight_recorded_locally(trip) -> bool:
    """Our trip holds a loaded weight or a loaded-weight slip (synced or not)."""
    return bool(trip.s3_loaded_truck_weight_kg or trip.s3_loaded_weight_slip_url)


def weight_recorded_in_rr(parcels: list[dict]) -> bool:
    """RR web's rule (vehicles.component.ts checkBookingCancelableOrNot): any parcel with a weight slip
    (documents.weight_receipt present at all) or an actual kanta weight value."""
    for p in parcels or []:
        if (p.get("documents") or {}).get("weight_receipt") is not None:
            return True
        if (p.get("actual_kanta_weight") or {}).get("weight"):
            return True
    return False


def rr_message(resp) -> str:
    """RR's own refusal text."""
    try:
        body = resp.json()
    except Exception:
        return (resp.text or "")[:300]
    if isinstance(body, dict):
        msg = body.get("statusText") or (body.get("_error") or {}).get("message") or body.get("_issues")
        if msg:
            return msg if isinstance(msg, str) else json.dumps(msg)[:300]
    return (resp.text or "")[:300]


# ── RR reads ────────────────────────────────────────────────────────────────────

def _hdr(token: str, json_body: bool = False) -> dict:
    h = {"Authorization": f"Bearer {token}"}
    if json_body:
        h["Content-Type"] = "application/json"
    return h


async def rr_parcels(client: httpx.AsyncClient, token: str, rr_trip_id: str) -> list[dict] | None:
    """All parcels of the RR trip (None when RR cannot be read)."""
    resp = await client.get(f"{settings.RR_API_BASE}/parcels", headers=_hdr(token),
                            params={"where": json.dumps({"trip_id": rr_trip_id}), "max_results": 50})
    if resp.status_code != 200:
        return None
    return resp.json().get("_items", [])


async def rr_booked_offer(client: httpx.AsyncClient, token: str, rr_trip_id: str) -> tuple[bool, dict | None]:
    """(could read, the trip's Booked truck offer or None)."""
    resp = await client.get(f"{settings.RR_API_BASE}/potential_vehicles", headers=_hdr(token),
                            params={"where": json.dumps({"trip_id": rr_trip_id, "vehicle_status": "Booked"}),
                                    "max_results": 1})
    if resp.status_code != 200:
        return False, None
    items = resp.json().get("_items", [])
    return True, (items[0] if items else None)


async def booking_guard(trip, client: httpx.AsyncClient, token: str) -> str | None:
    """Why this trip must not be synced now, or None. Stops the sync (nothing sent) when the trip or its booking is
    cancelled, or when RR's booked truck is not the trip's truck any more (booking changed / cancelled in RR web)."""
    if trip.status == "cancelled":
        return "Trip is cancelled - nothing is synced."
    if trip.booking_status == BOOKING_CANCELLED:
        return "The truck booking was cancelled - book another truck first."
    if not (trip.rr_trip_id and trip.rr_vehicle_id):
        return None
    try:
        ok, offer = await rr_booked_offer(client, token, trip.rr_trip_id)
    except Exception as exc:
        return f"Could not check the booking in RR ({str(exc)[:120]}) - nothing sent."
    if not ok:
        return "Could not check the booking in RR - nothing sent."
    if offer is None:
        return "The truck booking was cancelled in RR web - nothing sent. Book another truck from the app."
    if str(offer.get("vehicle") or "") != str(trip.rr_vehicle_id):
        return "The booked truck was changed in RR web - nothing sent. Cancel and re-book from the app."
    return None


# ── Our side ────────────────────────────────────────────────────────────────────

def reset_trip_after_booking_cancel(trip) -> None:
    """The old truck, driver and owner leave the trip completely (md/RR_BOOKING_CANCEL_RULES.md 9.3). Stored
    documents stay under their own driver / truck / owner; only the trip's links, numbers and "already sent" state
    go. The loading slip, e-way bill and invoice stay. The caller commits."""
    for col in BOOKING_COLUMNS:
        setattr(trip, col, None)
    for c in UPLOAD_COLUMNS:
        if c.stage == 1:
            setattr(trip, c.column, None)
    for col in STAGE1_NUMBER_COLUMNS + STAGE1_RR_FILE_ID_COLUMNS + TRUCK_STAGE_COLUMNS:
        setattr(trip, col, None)
    synced = {k: v for k, v in (trip.rr_synced_doc_urls or {}).items()
              if not k.startswith(STAGE1_SYNC_KEY_PREFIXES) and k != rr_change_marks.S1_PARTS_OK_KEY}
    stage1 = set(rr_change_marks.STAGE_COLUMNS.get(1, ()))
    changed = [c for c in synced.get(rr_change_marks.CHANGED_KEY, []) if c not in stage1]
    if changed:
        synced[rr_change_marks.CHANGED_KEY] = changed
    else:
        synced.pop(rr_change_marks.CHANGED_KEY, None)
    trip.rr_synced_doc_urls = synced
    trip.s1_submitted_at = None
    for col in ("s1_submitted_by", "s2_submitted_by", "s3_submitted_by", "s1_claimed_by", "s1_claimed_at",
                "s2_claimed_by", "s2_claimed_at", "s3_claimed_by", "s3_claimed_at"):
        if hasattr(trip, col):
            setattr(trip, col, None)
    trip.rr_s1_sync_status = "not_synced"
    trip.rr_s1_sync_error = None
    trip.rr_s1_synced_at = None
    trip.current_stage = 0
    trip.booking_status = BOOKING_CANCELLED


def apply_rebooking(trip, *, rr_vehicle_id: str, vehicle_number: str | None, rr_driver_id: str,
                    owner_rr_company_id: str | None, booking_id: str | None, booking_amount,
                    owner_rr_user_id: str | None = None) -> None:
    """The new booking on our trip. Stage 1 starts empty (pre-filled from RR web on the Stage 1 screen) and is
    'not synced', so its first sync sends everything - to the NEW driver / truck / booking owner only. The caller
    commits, then links the driver (GPS) and collects the new owner's papers."""
    trip.rr_vehicle_id = rr_vehicle_id
    trip.vehicle_number = vehicle_number
    trip.rr_driver_id = rr_driver_id
    trip.transporter_rr_company_id = owner_rr_company_id
    trip.transporter_rr_user_id = None if owner_rr_company_id else owner_rr_user_id   # an owner person, no company
    trip.rr_booking_id = booking_id
    if booking_amount is not None:
        trip.booking_amount = booking_amount
    # 'rebooked' (not NULL): booked again, and the trip keeps the mark that it has had a cancel - the app then loads
    # the Cancellations list only for trips with a booking_status (user, 2026-11-21). Every guard compares with
    # BOOKING_CANCELLED only, so a re-booked trip works like any booked trip.
    trip.booking_status = REBOOKED
    trip.rr_s1_sync_status = "not_synced"


# ── RR writes ───────────────────────────────────────────────────────────────────

async def cancel_booking_in_rr(client, token, rr_trip_id: str, reason: str) -> tuple[bool, str]:
    resp = await client.post(f"{settings.RR_API_BASE}/cancel_vehicle_booking_by_trip_owner",
                             headers=_hdr(token, True), json={"trip_id": rr_trip_id, "cancel_remark": reason})
    return resp.status_code == 200, rr_message(resp)


async def book_truck_in_rr(client, token, *, rr_trip_id: str, rr_vehicle_id: str, owner_rr_company_id: str | None,
                           rr_driver_id: str, booking_amount: float,
                           owner_rr_user_id: str | None = None) -> tuple[bool, str, str | None]:
    """RR web's booking order (tracked 2026-11-20). Returns (booked, message, potential_vehicle_id). The owner is a
    company (participant_company_id) or a person with no company (participant_user_id), as RR web books them."""
    from datetime import datetime, timezone
    base = settings.RR_API_BASE
    participant = ({"participant_company_id": owner_rr_company_id} if owner_rr_company_id
                   else {"participant_user_id": owner_rr_user_id})
    r = await client.post(f"{base}/v2/save_potential_vehicle_to_be_hired", headers=_hdr(token, True),
                          json={"vehicle_id": rr_vehicle_id, "trip_id": rr_trip_id, **participant})
    pv = r.json().get("potential_vehicle_id") if r.status_code == 200 else None
    old_bid = None
    if not pv and "booking is canceled" in rr_message(r).lower():
        # The same truck again: RR refuses a new offer and RR web re-awards the old cancelled one instead
        # (md/RR_WEB_TEST_WALKTHROUGH F8 / F32 - RR then books with no live purchase order; MIGHT CHANGE, to discuss
        # with the RR web team, user 2026-11-24).
        pv, old_bid = await _cancelled_offer_of_truck(client, token, rr_trip_id, rr_vehicle_id)
    if not pv:
        return False, f"Adding the truck to the trip failed: {rr_message(r)}", None
    steps = (
        ("Saving the booking amount", "submit_offline_bid_by_trip_owner", {"potential_vehicle_id": pv, "amount": booking_amount}),
        ("Awarding the truck", "award_bidding", {"potential_vehicle_id": pv}),
        ("Adding the driver to the truck", "add_vehicle_crew", {"potential_vehicle_id": pv, "crew": [{
            "worker": rr_driver_id, "position": "Driver",
            "assigned_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")}]}),
        ("Booking the truck", "award_vehicle", {"trip_id": rr_trip_id, "potential_vehicle_id": pv}),
    )
    for label, path, body in steps:
        if path == "submit_offline_bid_by_trip_owner" and old_bid is not None and float(old_bid) == float(booking_amount):
            continue   # re-awarding the old offer at its own price: RR refuses the same bid again (RR web skips it too)
        r = await client.post(f"{base}/{path}", headers=_hdr(token, True), json=body)
        if r.status_code != 200:
            return False, f"{label} failed: {rr_message(r)}", pv
    return True, rr_message(r), pv


async def _cancelled_offer_of_truck(client, token, rr_trip_id: str, rr_vehicle_id: str):
    """(offer id, its last bid) of the trip's offer for this truck whose booking the trip owner cancelled (RR web's
    re-award path), or (None, None)."""
    resp = await client.get(f"{settings.RR_API_BASE}/potential_vehicles", headers=_hdr(token), params={
        "where": json.dumps({"trip_id": rr_trip_id, "vehicle": rr_vehicle_id,
                             "vehicle_status": "Booking Canceled By Trip Owner"}), "max_results": 1})
    if resp.status_code != 200:
        return None, None
    items = resp.json().get("_items", [])
    return (str(items[0]["_id"]), items[0].get("last_bid")) if items else (None, None)


async def rr_booking_id(client, token, rr_trip_id: str) -> str | None:
    """The RR trip's booking id after a booking (booked_vehicle.booking_id), or None."""
    resp = await client.get(f"{settings.RR_API_BASE}/trips/{rr_trip_id}", headers=_hdr(token))
    if resp.status_code != 200:
        return None
    bid = (resp.json().get("booked_vehicle") or {}).get("booking_id")
    return str(bid) if bid else None


async def cancel_trip_in_rr(client, token, rr_trip_id: str) -> tuple[bool, str]:
    """RR's trip cancel (no reason field; ours stays in our database)."""
    resp = await client.get(f"{settings.RR_API_BASE}/cancel_trip_for_non_placement", headers=_hdr(token),
                            params={"trip_id": rr_trip_id})
    return resp.status_code == 200, rr_message(resp)
