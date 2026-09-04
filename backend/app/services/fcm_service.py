"""
Firebase Cloud Messaging Service
Sends push notifications to devices via FCM.
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)

# firebase-admin is optional — gracefully skip if not installed
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    from app.config import settings

    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)

    _fcm_available = True
except Exception as e:
    logger.warning(f'Firebase Admin SDK not available: {e}')
    _fcm_available = False


def send_to_token(
    token: str,
    title: str,
    body: str,
    data: Optional[dict] = None
) -> bool:
    """Send notification to a specific device via FCM token."""
    if not _fcm_available:
        logger.warning('FCM not available — skipping token notification')
        return False
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(message)
        logger.info(f'FCM sent to token ...{token[-10:]}')
        return True
    except Exception as e:
        logger.error(f'FCM send_to_token failed: {e}')
        return False


def send_data_only(token: str, data: dict) -> bool:
    """Send a silent, data-only push — no visible notification banner. Used to
    nudge an already-installed app to immediately re-check state (e.g. its
    trip list) instead of waiting for its next periodic poll. A `notification`
    block would show a banner and isn't wanted here."""
    if not _fcm_available:
        logger.warning('FCM not available — skipping data-only notification')
        return False
    try:
        message = messaging.Message(
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(message)
        logger.info(f'FCM data-only sent to token ...{token[-10:]}')
        return True
    except Exception as e:
        logger.error(f'FCM send_data_only failed: {e}')
        return False


def send_to_org_users(
    org_id,
    title: str,
    body: str,
    data: Optional[dict] = None,
    db=None,
) -> int:
    """Send FCM notification to all active users in an org that have an FCM token.
    Returns the number of tokens successfully targeted."""
    if db is None or not _fcm_available:
        return 0
    try:
        from app.models.user_organization import UserOrganization
        from app.models.user import User
        users = (
            db.query(User)
            .join(UserOrganization, UserOrganization.user_id == User.id)
            .filter(
                UserOrganization.organization_id == org_id,
                UserOrganization.status == 'active',
                User.fcm_token.isnot(None),
            )
            .all()
        )
        count = 0
        for user in users:
            if user.fcm_token and send_to_token(user.fcm_token, title, body, data):
                count += 1
        return count
    except Exception as e:
        logger.error(f'FCM send_to_org_users failed: {e}')
        return 0


def send_to_topic(
    topic: str,
    title: str,
    body: str,
    data: Optional[dict] = None
) -> bool:
    """Send notification to all devices subscribed to a topic."""
    if not _fcm_available:
        logger.warning(f'FCM not available — skipping topic notification: {topic}')
        return False
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            topic=topic,
        )
        messaging.send(message)
        return True
    except Exception as e:
        logger.error(f'FCM send_to_topic failed: {e}')
        return False


# ── Topic constants (must match Flutter FcmService) ──────────────────────────
TOPIC_ALL_USERS     = 'all_users'
TOPIC_LOAD_OWNERS   = 'load_owners'
TOPIC_FLEET_MANAGERS = 'fleet_managers'
TOPIC_DRIVERS       = 'drivers'
TOPIC_LP_WORKERS    = 'lp_workers'
TOPIC_LO_WORKERS    = 'lo_workers'
