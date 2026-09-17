"""
Tracking Watchdog

Periodically checks ongoing trips for a stalled GPS trail (no new
driver_locations row in STALE_THRESHOLD) and alerts LP/RR-ops. See the
2026-09-16 incident (trip RR-05849): tracking silently stopped mid-trip
while the trip still showed as "ongoing" and driver_tracking_stopped was
still false — nobody except someone actively staring at the live map would
have noticed.

There's no scheduler in this codebase (see trips.py's _driver_has_open_trip
area / driver_link_service.py, both of which note this explicitly) — this
is run as a plain asyncio background task started once from main.py's
startup event, matching that existing "no scheduler" constraint rather than
introducing a new dependency (APScheduler/Celery) for one check.
"""

import asyncio
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import func

from app.database import SessionLocal
from app.models.trip import Trip
from app.models.tracking import DriverLocation
from app.models.notification import Notification
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.role import Role
from app.services import fcm_service
from app.services.ws_manager import manager

logger = logging.getLogger(__name__)

# A healthy trail gets a fix at least every ~60s (foreground) or ~30-60s
# (background service batch), so 5 minutes of silence is well past any
# normal gap (brief tunnel/indoor loss) without being trigger-happy.
STALE_THRESHOLD = timedelta(minutes=5)
CHECK_INTERVAL_SECONDS = 300

# Only LP/RR-ops are meant to see this — Notification.recipient_role only
# carries one role per row (see notifications.py's GET filter), so scoping
# to two roles means writing two rows, same as notify_lp's single-role
# pattern in trips.py.
_ALERT_ROLES = ('logistic_partner', 'lp_rr_operations')


async def run_forever() -> None:
    """Entry point started once from main.py's startup event."""
    while True:
        try:
            await check_stale_trails()
        except Exception:
            logger.exception("Tracking watchdog check failed")
        await asyncio.sleep(CHECK_INTERVAL_SECONDS)


async def check_stale_trails() -> None:
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        stale_cutoff = now - STALE_THRESHOLD

        # Same "actively tracked" definition as _driver_has_open_trip /
        # tracking_service._resolve_active_trip_id.
        trips = (
            db.query(Trip)
            .filter(
                Trip.status == 'ongoing',
                ~Trip.is_stage5_complete,
                ~Trip.driver_tracking_stopped,
                Trip.driver_id.isnot(None),
            )
            .all()
        )

        for trip in trips:
            last_ping = (
                db.query(func.max(DriverLocation.timestamp))
                .filter(DriverLocation.trip_id == trip.id)
                .scalar()
            )
            if last_ping is None:
                continue  # never tracked at all — not what this alert is for

            if last_ping.tzinfo is None:
                last_ping = last_ping.replace(tzinfo=timezone.utc)

            if last_ping >= stale_cutoff:
                # Fresh again — clear any earlier alert so a future stale
                # period gets its own notification instead of staying
                # permanently suppressed.
                if trip.driver_tracking_stale_alert_sent_at is not None:
                    trip.driver_tracking_stale_alert_sent_at = None
                    db.commit()
                continue

            if trip.driver_tracking_stale_alert_sent_at is not None:
                continue  # already alerted for this stale period

            await _notify_stale_trail(trip, last_ping, db)
            trip.driver_tracking_stale_alert_sent_at = now
            db.commit()
    finally:
        db.close()


async def _notify_stale_trail(trip: Trip, last_ping: datetime, db) -> None:
    minutes_stale = int((datetime.now(timezone.utc) - last_ping).total_seconds() // 60)
    title = "Driver's live trail has stopped"
    body = (
        f"Trip {trip.trip_number} ({trip.origin} → {trip.destination}) — "
        f"no location update for {minutes_stale} min. The driver's device may have "
        "lost GPS, been backgrounded, or gone offline."
    )

    for role_key in _ALERT_ROLES:
        notif = Notification(
            recipient_org_id=trip.organization_id,
            recipient_role=role_key,
            trip_id=trip.id,
            type="tracking_stale",
            title=title,
            body=body,
        )
        db.add(notif)
    db.commit()

    message = {
        "type": "tracking_stale",
        "trip_id": str(trip.id),
        "trip_number": trip.trip_number,
        "origin": trip.origin,
        "destination": trip.destination,
        "title": title,
        "body": body,
        "is_read": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    try:
        for role_key in _ALERT_ROLES:
            await manager.send_to_org_role(str(trip.organization_id), role_key, message)
    except Exception:
        pass  # best-effort — websocket delivery is never load-bearing

    recipients = (
        db.query(User)
        .join(UserOrganization, UserOrganization.user_id == User.id)
        .join(Role, Role.id == UserOrganization.role_id)
        .filter(
            UserOrganization.organization_id == trip.organization_id,
            UserOrganization.status == 'active',
            Role.role_key.in_(_ALERT_ROLES),
        )
        .all()
    )
    for user in recipients:
        if user.fcm_token:
            try:
                fcm_service.send_to_token(
                    user.fcm_token, title, body,
                    {"type": "tracking_stale", "trip_id": str(trip.id)},
                )
            except Exception:
                pass
