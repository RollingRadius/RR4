"""
Notifications API
- WebSocket endpoint: GET /ws/notifications?token=JWT
  Load-owner clients connect here to receive real-time push notifications.
- REST endpoints under /api prefix (included via app.include_router with prefix=""):
    GET  /api/notifications           – list notifications for current user's org
    PATCH /api/notifications/{id}/read – mark one notification as read
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.notification import Notification
from app.services.ws_manager import manager

router = APIRouter()


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _get_user_from_token(token: str, db: Session):
    """Resolve JWT token to (User, UserOrganization) or (None, None)."""
    from app.core.security import decode_access_token
    payload = decode_access_token(token)
    if not payload:
        return None, None
    user_id = payload.get("sub")
    if not user_id:
        return None, None
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.can_login():
        return None, None
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == user.id,
        UserOrganization.status == "active",
    ).first()
    return user, user_org


def _current_user_org(current_user: User, db: Session) -> UserOrganization:
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()
    if not user_org:
        raise HTTPException(status_code=403, detail="No active organisation")
    return user_org


# ─── WebSocket endpoint ───────────────────────────────────────────────────────

@router.websocket("/ws/notifications")
async def notifications_ws(
    websocket: WebSocket,
    token: str = Query(...),
    db: Session = Depends(get_db),
):
    """
    Load-owner clients connect with their JWT to receive real-time notifications.
    The connection is keyed by the user's organisation ID so all users in the
    same org receive the same broadcasts.
    """
    _, user_org = _get_user_from_token(token, db)
    if not user_org:
        await websocket.close(code=4001)
        return

    org_id = str(user_org.organization_id)
    await manager.connect(org_id, websocket)
    try:
        while True:
            # Keep-alive: accept (and discard) any text from the client
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(org_id, websocket)
    except Exception:
        manager.disconnect(org_id, websocket)


# ─── REST endpoints ───────────────────────────────────────────────────────────

@router.get("/api/notifications")
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the 50 most-recent notifications for the current user's org."""
    user_org = _current_user_org(current_user, db)
    notifs = (
        db.query(Notification)
        .filter(Notification.recipient_org_id == user_org.organization_id)
        .order_by(Notification.created_at.desc())
        .limit(50)
        .all()
    )
    unread = sum(1 for n in notifs if not n.is_read)
    return {
        "notifications": [n.to_dict() for n in notifs],
        "unread_count": unread,
    }


@router.patch("/api/notifications/{notif_id}/read")
def mark_notification_read(
    notif_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_org = _current_user_org(current_user, db)
    notif = db.query(Notification).filter(Notification.id == notif_id).first()
    if not notif or str(notif.recipient_org_id) != str(user_org.organization_id):
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    return {"success": True}


@router.patch("/api/notifications/read-all")
def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user_org = _current_user_org(current_user, db)
    db.query(Notification).filter(
        Notification.recipient_org_id == user_org.organization_id,
        Notification.is_read == False,  # noqa: E712
    ).update({"is_read": True})
    db.commit()
    return {"success": True}
