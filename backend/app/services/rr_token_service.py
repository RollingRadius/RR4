"""
RR Token Service
Manages the RR API access token via refresh token rotation.

On startup: loads RR_REFRESH_TOKEN from config.
Background task: calls POST /persons/refresh every 10 minutes to keep
access_token alive (RR token expires in 15 min — 5-min safety buffer).
Retries once after 60s if refresh fails. All RR API calls must go through get_access_token().
"""

import asyncio
import logging
from datetime import datetime

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

# ── In-memory token state ─────────────────────────────────────────────────────
_access_token: str | None = None
_last_refreshed: datetime | None = None
_refresh_task: asyncio.Task | None = None

_REFRESH_INTERVAL_SECONDS = 10 * 60  # 10 minutes — 5-min buffer before 15-min RR token expiry


def get_access_token() -> str | None:
    """Return the current RR access token. None if not yet obtained or sync disabled."""
    return _access_token


async def _do_refresh() -> bool:
    """Call RR /persons/refresh and store the new access_token. Returns True on success."""
    global _access_token, _last_refreshed

    if not settings.RR_REFRESH_TOKEN:
        logger.warning("RR_REFRESH_TOKEN not set — cannot refresh RR access token")
        return False

    try:
        async with httpx.AsyncClient(verify=settings.RR_SSL_VERIFY, timeout=15) as client:
            resp = await client.post(
                f"{settings.RR_API_BASE}/persons/refresh",
                json={"refresh_token": settings.RR_REFRESH_TOKEN},
            )
            resp.raise_for_status()
            data = resp.json()
            _access_token = data.get("access_token") or data.get("token")
            _last_refreshed = datetime.utcnow()
            logger.info("RR access token refreshed successfully")
            return True
    except Exception as exc:
        logger.error(f"RR token refresh failed: {exc}")
        return False


async def _refresh_loop():
    """Background loop — refresh every 10 minutes with retry on failure."""
    # Initial refresh on startup
    await _do_refresh()

    while True:
        await asyncio.sleep(_REFRESH_INTERVAL_SECONDS)
        success = await _do_refresh()
        if not success:
            # Retry once after 60s rather than waiting another full interval
            logger.warning("RR token refresh failed — retrying in 60s")
            await asyncio.sleep(60)
            await _do_refresh()


def start_token_refresh():
    """Schedule the background refresh loop. Call once from app startup."""
    global _refresh_task
    if not settings.RR_SYNC_ENABLED:
        logger.info("RR sync disabled (RR_SYNC_ENABLED=false) — token refresh skipped")
        return
    _refresh_task = asyncio.create_task(_refresh_loop())
    logger.info("RR token refresh background task started (interval: 10 min, retry on failure: 60s)")


def stop_token_refresh():
    """Cancel the background task. Call from app shutdown."""
    global _refresh_task
    if _refresh_task and not _refresh_task.done():
        _refresh_task.cancel()
        _refresh_task = None
