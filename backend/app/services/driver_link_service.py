"""Links a trip's RR-side driver to a local RR4 Driver account by phone.

RR4's own trip-creation flow only ever captures the RR-side driver as
rr_driver_id (RR's Mongo ObjectId) — it never sets Trip.driver_id, the
local FK RR4's own GPS-tracking lookup depends on. This module bridges
that gap: given the RR driver's id, fetch their phone from RR, match it
against a local Driver by normalized phone, and link the trip.
"""

import logging

import httpx
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.config import settings
from app.models.driver import Driver
from app.models.trip import Trip
from app.services import fcm_service
from app.utils.phone import normalize_phone

logger = logging.getLogger(__name__)


def _notify_driver_assigned(driver: Driver, trip: Trip) -> None:
    """Best-effort push to the driver's own device — never raises, a failure
    here must not affect trip creation/reassignment."""
    try:
        token = driver.user.fcm_token if driver.user else None
        if token:
            fcm_service.send_to_token(
                token,
                "New trip assigned",
                f"You've been assigned Trip {trip.trip_number} — open RR4 and "
                f"enable location to be tracked.",
                {"type": "trip_assigned", "trip_id": str(trip.id)},
            )
    except Exception:
        logger.warning(f"[Driver Link] Failed to notify driver {driver.id} of assignment", exc_info=True)


def _driver_has_other_open_trip(db: Session, driver_id, exclude_trip_id) -> bool:
    """True if `driver_id` already has another ongoing, not-yet-stage-5-complete
    trip besides `exclude_trip_id`. Mirrors the same rule enforced in
    app/api/v1/trips.py's create/update endpoints (duplicated in miniature here
    rather than imported, to avoid a service→router dependency)."""
    return db.query(Trip).filter(
        Trip.driver_id == driver_id,
        Trip.status == 'ongoing',
        ~Trip.is_stage5_complete,
        Trip.id != exclude_trip_id,
    ).first() is not None


def find_driver_by_phone(db: Session, phone: str) -> Driver | None:
    """Normalize `phone` and match against the expression index on
    drivers.phone (see alembic/versions/090_add_driver_phone_index.py —
    the SQL expression below must stay textually identical to that index)."""
    norm = normalize_phone(phone)
    if not norm:
        return None
    return (
        db.query(Driver)
        .filter(
            func.right(func.regexp_replace(Driver.phone, r"[^0-9]", "", "g"), 10) == norm
        )
        .first()
    )


async def resolve_local_driver(rr_driver_id: str, rr_token: str, db: Session) -> tuple[bool, Driver | None]:
    """Pure lookup (no Trip mutation): fetch the RR driver's phone from RR and
    match it to a local Driver by phone. Returns (lookup_succeeded, driver).

    lookup_succeeded=False means the RR call itself failed/errored — a
    transient condition callers must NOT treat as "no local account" (see
    link_driver_to_trip). lookup_succeeded=True with driver=None means a
    genuine, confirmed "no local RR4 account for this phone" result.
    """
    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=10) as client:
            # Plain GET /users/{id} 404s for a non-owner RR session (RR's
            # auth_field restricted-resource mechanism — see the identical
            # note on get_prefill() in rr_sync.py, which hits the exact same
            # wall and uses this same endpoint instead) — LP/RR-ops looking
            # up a driver they don't own is exactly this codebase's normal
            # case, so this is not an edge case.
            resp = await client.get(
                f"{settings.RR_API_BASE}/get_user_record_by_id",
                params={"record_id": rr_driver_id},
                headers={"Authorization": f"Bearer {rr_token}"},
            )
    except Exception:
        logger.warning(f"[Driver Link] Phone lookup failed for rr_driver_id={rr_driver_id}", exc_info=True)
        return False, None

    if resp.status_code != 200:
        logger.warning(
            f"[Driver Link] get_user_record_by_id HTTP {resp.status_code} for "
            f"rr_driver_id={rr_driver_id}"
        )
        return False, None

    phone = (resp.json().get("phone") or {}).get("number")
    return True, (find_driver_by_phone(db, phone) if phone else None)


async def link_driver_to_trip(trip: Trip, rr_driver_id: str, rr_token: str, db: Session) -> None:
    """Best-effort: resolve the RR driver to a local Driver (see
    resolve_local_driver) and set trip.driver_id — but ONLY on a genuine,
    successful RR lookup. A transient RR failure (network error, non-200 —
    e.g. a Stage-0 retry hitting a flaky response) must leave any existing
    link untouched rather than wiping a previously-correct match; only a
    real "looked it up, no local driver has this phone" result clears
    trip.driver_id (the full-replace behavior a genuine reassignment needs).
    Never raises — callers must not have trip creation or reassignment fail
    because of this.
    """
    lookup_ok, matched = await resolve_local_driver(rr_driver_id, rr_token, db)
    if not lookup_ok:
        logger.warning(f"[Driver Link] Trip {trip.trip_number} — leaving trip.driver_id untouched")
        return

    if matched and _driver_has_other_open_trip(db, matched.id, trip.id):
        # Don't silently steal a driver from a trip they're still open on —
        # treat this the same as "no local match" rather than raising, since
        # this whole flow is best-effort by design (see docstring above).
        logger.warning(
            f"[Driver Link] Trip {trip.trip_number} — matched local driver "
            f"{matched.id} already has another open trip, not linking"
        )
        matched = None

    previous_driver_id = trip.driver_id
    trip.driver_id = matched.id if matched else None
    db.commit()
    if matched:
        logger.info(f"[Driver Link] Trip {trip.trip_number} linked to local driver {matched.id}")
        # Only notify on a genuine new assignment — link_driver_to_trip also
        # runs on idempotent Stage-0 retries, which must not re-spam a driver
        # already correctly linked to this trip.
        if matched.id != previous_driver_id:
            _notify_driver_assigned(matched, trip)
    else:
        logger.info(f"[Driver Link] Trip {trip.trip_number} — no local driver matched rr_driver_id={rr_driver_id}")
