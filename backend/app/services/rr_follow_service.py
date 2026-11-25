"""Our trips follow RR web's booking facts (md/RR_TWO_WAY_SYNC_PLAN.md "SCOPE UPDATE", user 2026-11-24).

Compared - only what our app has, booking level: trip cancelled, booking cancelled, another truck / owner booked,
driver changed. Parcel and paper edits stay one-way (app -> RR) as before; RR-only fields are never read.
- A change found in RR is applied with the app's own code (cancel booking / re-book / reassign / cancel trip), so the
  old driver's, truck's and owner's papers always leave the trip (lesson of F10).
- Each change is written to trip_booking_events (no user = "RR web") and stamps trips.rr_web_changed_at.
- RR unreachable or no RR login -> nothing changes, tried again next time, no error to the user.
Triggers: before every sync (inside the sync's claim), trip opened, dashboard refresh, background check
(settings.RR_FOLLOW_INTERVAL_MINUTES). RR prod has no Redis cache, so its values are current; on RR test a truck or
company edited in the last 10 minutes can be stale (md/RR_CACHED_DRIVER_BOOKING_BUG.md).
"""
import asyncio
import json
import logging
from datetime import datetime, timezone

import httpx

from app import database
from app.config import settings
from app.models import trip_booking_event as ev
from app.models.company import Organization
from app.models.load_requirement import LoadRequirement
from app.models.trip import Trip
# modules, not names: rr_sync_service imports this module back, and tests patch these modules
from app.services import driver_link_service, rr_org_token_service, rr_pull_service, rr_sync_service
from app.services import rr_booking_service as bs
from app.services import stage1_document_service

logger = logging.getLogger(__name__)

TRIP_CANCELLED = "trip_cancelled"
BOOKING_CANCELLED = "booking_cancelled"
REBOOKED = "rebooked"
DRIVER_CHANGED = "driver_changed"
FIELDS_UPDATED = "fields_updated"          # papers / stage fields / uploads pulled (rr_pull_service)
RR_TRIP_CANCELLED_STAGE = "Trip Cancelled"
NOT_FOLLOWED_STATUSES = ("cancelled", "completed")
BATCH = 50

_TITLES = {
    TRIP_CANCELLED: ("Trip cancelled on RR web", "Trip {n} was cancelled on RR web."),
    BOOKING_CANCELLED: ("Booking cancelled on RR web", "Trip {n}: the truck booking was cancelled on RR web."),
    REBOOKED: ("Truck booked on RR web", "Trip {n}: another truck was booked on RR web."),
    DRIVER_CHANGED: ("Driver changed on RR web", "Trip {n}: the driver was changed on RR web."),
    FIELDS_UPDATED: ("Updated on RR web", "Trip {n}: details or documents were updated on RR web."),
}


def _hdr(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def followed(trip) -> bool:
    return bool(trip.rr_trip_id) and trip.status not in NOT_FOLLOWED_STATUSES


def _crew_driver(rr_trip: dict) -> str | None:
    for member in rr_trip.get("crew") or []:
        if member.get("position", "Driver") == "Driver" and member.get("worker"):
            return str(member["worker"])
    return None


async def read_rr_states(client: httpx.AsyncClient, token: str, rr_trip_ids: list[str]) -> dict | None:
    """{rr_trip_id: {"stage", "driver", "offer"}} for the trips RR has (offer = its Booked truck offer or None),
    or None when RR could not be read (then nothing is changed)."""
    base, states = settings.RR_API_BASE, {}
    ids = list(dict.fromkeys(i for i in rr_trip_ids if i))
    for start in range(0, len(ids), BATCH):
        chunk = ids[start:start + BATCH]
        trips = await client.get(f"{base}/trips", headers=_hdr(token), params={
            "where": json.dumps({"_id": {"$in": chunk}}),
            "projection": json.dumps({"trip_stage": 1, "crew": 1, "booked_vehicle": 1}),
            "max_results": len(chunk)})
        offers = await client.get(f"{base}/potential_vehicles", headers=_hdr(token), params={
            "where": json.dumps({"trip_id": {"$in": chunk}, "vehicle_status": "Booked"}),
            "projection": json.dumps({"trip_id": 1, "vehicle": 1, "vehicle_owner_company_id": 1,
                                    "vehicle_owner_user_id": 1, "booking_id": 1,
                                      "last_bid": 1, "vehicle_status": 1}),
            "max_results": len(chunk) * 2})
        if trips.status_code != 200 or offers.status_code != 200:
            logger.info(f"[RR Follow] RR read failed (trips {trips.status_code}, offers {offers.status_code})")
            return None
        booked = {str(o.get("trip_id")): o for o in offers.json().get("_items", [])}
        for t in trips.json().get("_items", []):
            tid = str(t.get("_id"))
            states[tid] = {"stage": t.get("trip_stage"), "driver": _crew_driver(t), "offer": booked.get(tid)}
    return states


def what_changed(trip, state: dict | None) -> str | None:
    """The booking fact RR web changed on this trip, or None. Pure."""
    if not followed(trip) or not state:
        return None
    if state.get("stage") == RR_TRIP_CANCELLED_STAGE:
        return TRIP_CANCELLED
    offer = state.get("offer")
    if offer is None:
        if trip.rr_vehicle_id and trip.booking_status != bs.BOOKING_CANCELLED:
            return BOOKING_CANCELLED
        return None
    if trip.booking_status == bs.BOOKING_CANCELLED or str(offer.get("vehicle") or "") != str(trip.rr_vehicle_id or ""):
        return REBOOKED
    driver = state.get("driver")
    if driver and driver != str(trip.rr_driver_id or ""):
        return DRIVER_CHANGED
    return None


async def _vehicle_number(client, token: str, rr_vehicle_id: str) -> str | None:
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/vehicles/{rr_vehicle_id}", headers=_hdr(token))
        if resp.status_code == 200:
            for ident in resp.json().get("identities") or []:
                if ident.get("id_name") == "Registration Certificate" and ident.get("number"):
                    return str(ident["number"]).replace(" ", "")[:30]
    except Exception:
        pass
    return None


async def _user_name(client, token: str, rr_user_id: str | None) -> str | None:
    if not rr_user_id:
        return None
    try:
        resp = await client.get(f"{settings.RR_API_BASE}/users/{rr_user_id}", headers=_hdr(token))
        if resp.status_code == 200:
            return (resp.json().get("name") or "")[:100] or None
    except Exception:
        pass
    return None


def _cancel_linked_load(trip, db) -> None:
    if getattr(trip, "load_requirement_id", None):
        linked = db.query(LoadRequirement).filter(LoadRequirement.id == trip.load_requirement_id,
                                                  LoadRequirement.status == "assigned").first()
        if linked:
            linked.status = "cancelled"


async def apply_change(db, trip, kind: str, state: dict, client, token: str) -> None:
    """Apply one RR web change to our trip with the app's own code, write its history row, commit."""
    # Lazy on purpose (the one exception): the API module imports rr_sync_service by name, so importing it here at
    # load time breaks start-up whenever rr_sync_service is loaded first.
    from app.api.v1.rr_sync import _unlink_driver

    old = dict(old_rr_vehicle_id=trip.rr_vehicle_id, old_vehicle_number=trip.vehicle_number,
               old_rr_driver_id=trip.rr_driver_id, old_driver_name=trip.s1_driver_name,
               old_owner_rr_company_id=trip.transporter_rr_company_id, old_owner_rr_user_id=trip.transporter_rr_user_id)
    booked_here = bool(trip.rr_vehicle_id) and trip.booking_status != bs.BOOKING_CANCELLED
    new_driver = state.get("driver")
    relink_driver = None

    if kind == BOOKING_CANCELLED:
        row = ev.TripBookingEvent(event=ev.RR_WEB_BOOKING_CANCELLED, rr_booking_id=trip.rr_booking_id,
                                  booking_amount=trip.booking_amount, **old)
        _unlink_driver(trip, db)
        bs.reset_trip_after_booking_cancel(trip)
    elif kind == TRIP_CANCELLED:
        row = ev.TripBookingEvent(event=ev.RR_WEB_TRIP_CANCELLED, rr_booking_id=trip.rr_booking_id,
                                  **(old if booked_here else {}))
        if booked_here:
            _unlink_driver(trip, db)
            bs.reset_trip_after_booking_cancel(trip)
        trip.status = "cancelled"
        _cancel_linked_load(trip, db)
    elif kind == REBOOKED:
        offer = state["offer"]
        vehicle = str(offer.get("vehicle"))
        owner = str(offer.get("vehicle_owner_company_id") or "") or None
        owner_user = None if owner else (str(offer.get("vehicle_owner_user_id") or "") or None)   # a person owner
        booking_id = str(offer["booking_id"]) if offer.get("booking_id") else None
        number = await _vehicle_number(client, token, vehicle)
        row = ev.TripBookingEvent(event=ev.RR_WEB_REBOOKED, rr_booking_id=booking_id, new_rr_vehicle_id=vehicle,
                                  new_vehicle_number=number, new_rr_driver_id=new_driver,
                                  new_driver_name=await _user_name(client, token, new_driver),
                                  new_owner_rr_company_id=owner, new_owner_rr_user_id=owner_user,
                                  booking_amount=offer.get("last_bid"),
                                  **(old if booked_here else {}))
        if booked_here:                      # the old truck, driver and owner leave first
            _unlink_driver(trip, db)
            bs.reset_trip_after_booking_cancel(trip)
        bs.apply_rebooking(trip, rr_vehicle_id=vehicle, vehicle_number=number, rr_driver_id=new_driver,
                           owner_rr_company_id=owner, owner_rr_user_id=owner_user, booking_id=booking_id,
                           booking_amount=offer.get("last_bid"))
        relink_driver = new_driver
    elif kind == DRIVER_CHANGED:
        row = ev.TripBookingEvent(event=ev.RR_WEB_DRIVER_CHANGED, old_rr_driver_id=trip.rr_driver_id,
                                  old_driver_name=trip.s1_driver_name, new_rr_driver_id=new_driver,
                                  new_driver_name=await _user_name(client, token, new_driver))
        # as the app's Reassign: the old driver's papers and cached RR file ids leave the trip
        trip.rr_driver_id = new_driver
        trip.rr_dl_file_id = trip.rr_dl_back_file_id = None
        trip.rr_aadhaar_file_id = trip.rr_aadhaar_back_file_id = None
        stage1_document_service.clear_driver_documents(trip)
        relink_driver = new_driver
    else:
        return

    row.trip_id = trip.id
    row.rr_trip_id = trip.rr_trip_id
    row.created_by = None
    trip.rr_web_changed_at = datetime.now(timezone.utc)
    db.add(row)
    db.commit()
    if relink_driver:
        try:
            await driver_link_service.link_driver_to_trip(trip, relink_driver, token, db)
        except Exception:
            logger.exception(f"[RR Follow] driver link failed for {trip.trip_number}")
    logger.info(f"[RR Follow] {trip.trip_number}: followed RR web ({kind})")


async def follow_trips(db, trips: list, client, token: str, *, claim: bool = True) -> list[tuple]:
    """Read RR for these trips and apply what RR web changed. Returns [(trip, kind)]. Never raises.
    claim=False only for a caller that already holds the trip's sync claim (the sync itself)."""
    applied: list[tuple] = []
    try:
        mine = [t for t in trips if followed(t)]
        if not mine or not token:
            return applied
        states = await read_rr_states(client, token, [t.rr_trip_id for t in mine])
        if states is None:
            return applied
        for trip in mine:
            state = states.get(str(trip.rr_trip_id))
            if not what_changed(trip, state):
                continue
            if claim and not rr_sync_service._claim_trip_sync(db, trip.id):
                continue                     # a sync of this trip is running; it follows RR itself first
            try:
                db.refresh(trip)
                kind = what_changed(trip, state)
                if kind:
                    await apply_change(db, trip, kind, state, client, token)
                    applied.append((trip, kind))
            except Exception:
                db.rollback()
                logger.exception(f"[RR Follow] could not apply the RR web change to {trip.trip_number}")
            finally:
                if claim:
                    rr_sync_service._release_trip_sync(db, trip.id)
    except Exception:
        logger.exception("[RR Follow] reading RR failed - nothing changed")
        try:
            db.rollback()
        except Exception:
            pass
    # Then the papers and every stage field / upload RR web changed (rr_pull_service, plan section 10).
    try:
        for trip, _cols in await rr_pull_service.pull_trips(db, [t for t in trips if followed(t)], client, token, claim=claim):
            applied.append((trip, FIELDS_UPDATED))
    except Exception:
        logger.exception("[RR Follow] pulling RR web's field changes failed - nothing more changed")
    for trip, kind in applied:
        try:
            from app.api.v1.rr_sync import _notify_booking_change   # lazy on purpose, see apply_change
            title, body = _TITLES[kind]
            await _notify_booking_change(trip, title, body.format(n=trip.trip_number))
        except Exception:
            pass
    return applied


async def follow_org_trips(db, org, trips: list) -> list[tuple]:
    """With the organisation's RR login (none / expired -> nothing)."""
    try:
        token = await rr_org_token_service.get_org_rr_token(org, db)
    except Exception:
        return []
    if not token:
        return []
    async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=30) as client:
        return await follow_trips(db, trips, client, token)


async def follow_all_orgs() -> int:
    """Background check: every organisation with an RR login, its open RR trips. Returns how many changes applied."""
    db = database.SessionLocal()
    total = 0
    try:
        for org in db.query(Organization).filter(Organization.rr_refresh_token.isnot(None)).all():
            trips = db.query(Trip).filter(Trip.organization_id == org.id, Trip.rr_trip_id.isnot(None),
                                          Trip.status.notin_(NOT_FOLLOWED_STATUSES)).all()
            if trips:
                total += len(await follow_org_trips(db, org, trips))
    finally:
        db.close()
    return total


async def run_forever() -> None:
    """Started once from main.py's startup event (same single-worker assumption as tracking_watchdog)."""
    minutes = settings.RR_FOLLOW_INTERVAL_MINUTES
    if minutes <= 0 or not settings.RR_SYNC_ENABLED:
        return
    await asyncio.sleep(60)
    while True:
        try:
            changed = await follow_all_orgs()
            if changed:
                logger.info(f"[RR Follow] background check applied {changed} RR web change(s)")
        except Exception:
            logger.exception("[RR Follow] background check failed")
        await asyncio.sleep(minutes * 60)
