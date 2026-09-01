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
from app.utils.phone import normalize_phone

logger = logging.getLogger(__name__)


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


async def link_driver_to_trip(trip: Trip, rr_driver_id: str, rr_token: str, db: Session) -> None:
    """Best-effort: fetch the RR driver's phone, match to a local Driver,
    and set trip.driver_id — but ONLY on a genuine, successful RR lookup
    (200 + a resolvable phone). A transient RR failure (network error,
    non-200 — e.g. a Stage-0 retry hitting a flaky response) must leave
    any existing link untouched rather than wiping a previously-correct
    match; only a real "looked it up, no local driver has this phone"
    result clears trip.driver_id (the full-replace behavior a genuine
    reassignment needs). Never raises — callers must not have trip
    creation or reassignment fail because of this.
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
        return

    if resp.status_code != 200:
        logger.warning(
            f"[Driver Link] get_user_record_by_id HTTP {resp.status_code} for "
            f"rr_driver_id={rr_driver_id} — leaving trip.driver_id untouched"
        )
        return

    phone = (resp.json().get("phone") or {}).get("number")
    matched = find_driver_by_phone(db, phone) if phone else None

    trip.driver_id = matched.id if matched else None
    db.commit()
    if matched:
        logger.info(f"[Driver Link] Trip {trip.trip_number} linked to local driver {matched.id}")
    else:
        logger.info(f"[Driver Link] Trip {trip.trip_number} — no local driver matched rr_driver_id={rr_driver_id}")
