"""
RR Org Token Service
Persists and silently refreshes a per-organization RR access token, so background
stage-sync tasks (see rr_sync_service.sync_stage) can push to RR without a human
being logged in at the moment the sync runs.

Populated by: POST /api/rr/auth/login (LP or RR-ops signing in) — see rr_sync.py.
Consumed by:  rr_sync_service.sync_stage dispatcher, before every stage sync attempt.
"""

import logging
import uuid
from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy.orm import Session

from app.config import settings
from app.models.company import Organization

logger = logging.getLogger(__name__)

_TOKEN_LIFETIME_BUFFER = timedelta(minutes=2)   # matches rr_token_service.py's 15-min-token/2-min-buffer pattern
_TOKEN_ASSUMED_LIFETIME = timedelta(minutes=15)


async def get_org_rr_token(org: Organization, db: Session) -> str | None:
    """
    Return a valid RR access token for this org, refreshing it first if stale.
    Returns None if there's no stored session, or the refresh token has been
    revoked/expired — callers should treat that as "needs a human to log in again".
    """
    if not org.rr_refresh_token:
        return None

    await maybe_notify_rr_expiry(org, db)

    now = datetime.now(timezone.utc)
    if org.rr_access_token and org.rr_token_expires_at and org.rr_token_expires_at > now:
        return org.rr_access_token

    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
            resp = await client.post(
                f"{settings.RR_API_BASE}/persons/refresh",
                json={"refresh_token": org.rr_refresh_token},
            )
    except Exception as exc:
        logger.error(f"[RR Org Token] Refresh request failed for org {org.id}: {exc}")
        return None

    if resp.status_code != 200:
        logger.warning(
            f"[RR Org Token] Refresh rejected for org {org.id} ({resp.status_code}) — "
            f"clearing stored token, human re-login required"
        )
        org.rr_access_token = None
        org.rr_refresh_token = None
        org.rr_token_expires_at = None
        org.rr_session_expires_at = None
        org.rr_expiry_notified_at = None
        db.commit()
        return None

    data = resp.json()
    new_access_token = data.get("access_token") or data.get("token")
    if not new_access_token:
        logger.error(f"[RR Org Token] Refresh response missing token for org {org.id}: {resp.text[:200]}")
        return None

    org.rr_access_token = new_access_token
    # RR's /persons/refresh may or may not rotate the refresh token — keep the old one if absent.
    org.rr_refresh_token = data.get("refresh_token") or org.rr_refresh_token
    org.rr_token_expires_at = now + _TOKEN_ASSUMED_LIFETIME - _TOKEN_LIFETIME_BUFFER
    db.commit()

    logger.info(f"[RR Org Token] Refreshed access token for org {org.id}")
    return new_access_token


def store_org_rr_session(
    org: Organization,
    db: Session,
    access_token: str,
    refresh_token: str | None,
    updated_by_user_id,
) -> None:
    """Persist a freshly-obtained RR session (from POST /auth/login) onto the org."""
    now = datetime.now(timezone.utc)
    org.rr_access_token = access_token
    org.rr_refresh_token = refresh_token
    org.rr_token_expires_at = now + _TOKEN_ASSUMED_LIFETIME - _TOKEN_LIFETIME_BUFFER
    org.rr_token_updated_by = updated_by_user_id
    # RR's own refresh token has a fixed ~30-day lifetime that never renews
    # or rotates (confirmed by reading RR's REFRESH_TOKEN_EXPIRY_DAYS) — a
    # fresh login resets this clock, and clears any earlier "expiring soon"
    # notification flag so a new session gets its own fresh warning cycle.
    org.rr_session_expires_at = now + timedelta(days=30)
    org.rr_expiry_notified_at = None
    db.commit()


def is_rr_session_expiring_soon(org: Organization) -> bool:
    if not org.rr_session_expires_at:
        return False
    return datetime.now(timezone.utc) >= org.rr_session_expires_at - timedelta(days=1)


async def maybe_notify_rr_expiry(org: Organization, db: Session) -> None:
    """
    Fire an in-app + push notification to LP/RR-ops once per day while the
    org's RR session is within 1 day of its real ~30-day expiry, so nobody
    discovers pre-fill/sync silently stopped working only after the fact.
    Cheap no-op the vast majority of the time (two early-return checks).
    """
    if not org.rr_refresh_token or not is_rr_session_expiring_soon(org):
        return

    now = datetime.now(timezone.utc)
    if org.rr_expiry_notified_at and (now - org.rr_expiry_notified_at) < timedelta(hours=20):
        return  # already notified recently enough — avoid spamming on every call

    from app.models.user_organization import UserOrganization
    from app.models.role import Role
    from app.models.user import User
    from app.services import fcm_service
    from app.services.ws_manager import manager

    recipients = (
        db.query(User)
        .join(UserOrganization, UserOrganization.user_id == User.id)
        .join(Role, Role.id == UserOrganization.role_id)
        .filter(
            UserOrganization.organization_id == org.id,
            UserOrganization.status == "active",
            Role.role_key.in_(("logistic_partner", "lp_rr_operations")),
        )
        .all()
    )

    title = "RR Session Expiring Soon"
    body = "Your RR web connection expires within a day — reconnect to keep sync and pre-fill working."
    for user in recipients:
        if user.fcm_token:
            fcm_service.send_to_token(user.fcm_token, title, body, {"type": "rr_session_expiring"})

    try:
        await manager.send_to_org(str(org.id), {
            "type": "rr_session_expiring",
            "id": str(uuid.uuid4()),
            "title": title,
            "body": body,
            "is_read": False,
            "created_at": now.isoformat(),
        })
    except Exception:
        pass  # best-effort — known single-worker-process constraint on ws_manager

    org.rr_expiry_notified_at = now
    db.commit()
