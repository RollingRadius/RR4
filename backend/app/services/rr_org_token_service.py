"""
RR Org Token Service
Persists and silently refreshes a per-organization RR access token, so background
stage-sync tasks (see rr_sync_service.sync_stage) can push to RR without a human
being logged in at the moment the sync runs.

Populated by: POST /api/rr/auth/login (LP or RR-ops signing in) — see rr_sync.py.
Consumed by:  rr_sync_service.sync_stage dispatcher, before every stage sync attempt.
"""

import logging
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
    db.commit()
