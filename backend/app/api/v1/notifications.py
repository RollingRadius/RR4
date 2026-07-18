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

from app.database import get_db, SessionLocal
from app.dependencies import get_current_user
from app.models.user import User
from app.models.role import Role
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


def _current_user_org(current_user: User, db: Session) -> UserOrganization | None:
    return db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == "active",
    ).first()


# ─── WebSocket endpoint ───────────────────────────────────────────────────────

@router.websocket("/ws/notifications")
async def notifications_ws(
    websocket: WebSocket,
    token: str = Query(...),
):
    """
    Clients connect with their JWT to receive real-time notifications.
    Org-based users are keyed by org_id; transporters (no org) are keyed by user:{user_id}.
    """
    db = SessionLocal()
    try:
        user, user_org = _get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001)
            return

        if user_org:
            conn_key = str(user_org.organization_id)
            role = db.query(Role).filter(Role.id == user_org.role_id).first()
            role_key = role.role_key if role else 'unknown'
        else:
            # Transporter or user without org — key by user id
            conn_key = f"user:{str(user.id)}"
            role_key = 'transporter'
    finally:
        db.close()

    await manager.connect(conn_key, role_key, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(conn_key, websocket)
    except Exception:
        manager.disconnect(conn_key, websocket)


# ─── REST endpoints ───────────────────────────────────────────────────────────

@router.get("/api/notifications")
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the 50 most-recent notifications visible to the current user's role."""
    user_org = _current_user_org(current_user, db)

    if user_org:
        role = db.query(Role).filter(Role.id == user_org.role_id).first()
        role_key = role.role_key if role else ''
        notifs = (
            db.query(Notification)
            .filter(
                Notification.recipient_org_id == user_org.organization_id,
                (Notification.recipient_role == None) | (Notification.recipient_role == role_key),
            )
            .order_by(Notification.created_at.desc())
            .limit(50)
            .all()
        )
    else:
        # Transporter / user without org — return user-targeted notifications only
        notifs = (
            db.query(Notification)
            .filter(Notification.recipient_user_id == current_user.id)
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
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    # Allow if org-based match OR user-based match
    org_match = user_org and notif.recipient_org_id and str(notif.recipient_org_id) == str(user_org.organization_id)
    user_match = notif.recipient_user_id and str(notif.recipient_user_id) == str(current_user.id)
    if not org_match and not user_match:
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
    if user_org:
        db.query(Notification).filter(
            Notification.recipient_org_id == user_org.organization_id,
            Notification.is_read == False,  # noqa: E712
        ).update({"is_read": True})
    else:
        db.query(Notification).filter(
            Notification.recipient_user_id == current_user.id,
            Notification.is_read == False,  # noqa: E712
        ).update({"is_read": True})
    db.commit()
    return {"success": True}


@router.delete("/api/notifications/{notif_id}")
def delete_notification(
    notif_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a single notification. Idempotent — returns success even if already gone."""
    user_org = _current_user_org(current_user, db)
    notif = db.query(Notification).filter(Notification.id == notif_id).first()
    if not notif:
        return {"success": True}  # already deleted — idempotent
    org_match = user_org and notif.recipient_org_id and str(notif.recipient_org_id) == str(user_org.organization_id)
    user_match = notif.recipient_user_id and str(notif.recipient_user_id) == str(current_user.id)
    if not org_match and not user_match:
        raise HTTPException(status_code=403, detail="Not your notification")
    db.delete(notif)
    db.commit()
    return {"success": True}


@router.delete("/api/notifications")
def clear_all_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete all notifications for the current user."""
    user_org = _current_user_org(current_user, db)
    if user_org:
        db.query(Notification).filter(
            Notification.recipient_org_id == user_org.organization_id
        ).delete()
    else:
        db.query(Notification).filter(
            Notification.recipient_user_id == current_user.id
        ).delete()
    db.commit()
    return {"success": True}
