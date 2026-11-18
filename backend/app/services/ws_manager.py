"""
WebSocket Connection Manager
Tracks active WebSocket connections keyed by organisation ID for push notifications.
Supports role-aware broadcasting so notifications can target specific roles within an org.
Also remembers which user owns each connection, so all of one user's connections can be
closed at once when that user is removed from the company (security audit V-41).
"""

import logging
from typing import Dict, Optional, Set, Tuple

import anyio
from fastapi import WebSocket

logger = logging.getLogger(__name__)

# Close code sent to a client whose access ended (removed from the company, password changed, ...).
# 4001 = the same code the endpoint uses for a rejected token: the app (old and new APKs,
# notification_service.dart) treats it as final and does not keep reconnecting.
CLOSE_ACCESS_ENDED = 4001


class ConnectionManager:
    def __init__(self):
        # org_id (str) → set of (role_key, WebSocket) tuples
        self._connections: Dict[str, Set[Tuple[str, WebSocket]]] = {}
        # user_id (str) → set of (org_id/conn key, WebSocket) the user has open
        self._by_user: Dict[str, Set[Tuple[str, WebSocket]]] = {}

    async def connect(self, org_id: str, role_key: str, ws: WebSocket, user_id: Optional[str] = None) -> None:
        await ws.accept()
        self._connections.setdefault(org_id, set()).add((role_key, ws))
        if user_id:
            self._by_user.setdefault(user_id, set()).add((org_id, ws))

    def disconnect(self, org_id: str, ws: WebSocket) -> None:
        bucket = self._connections.get(org_id)
        if bucket:
            to_remove = {entry for entry in bucket if entry[1] == ws}
            bucket -= to_remove
            if not bucket:
                del self._connections[org_id]
        for user_id in [u for u, socks in self._by_user.items() if (org_id, ws) in socks]:
            self._by_user[user_id].discard((org_id, ws))
            if not self._by_user[user_id]:
                del self._by_user[user_id]

    async def close_user(self, user_id: str) -> int:
        """Stop every live connection of one user right away (removed from the company, V-41).
        They are taken out of the broadcast lists first, so nothing more is sent to them.
        Returns how many connections were closed."""
        entries = list(self._by_user.pop(str(user_id), set()))
        for org_id, ws in entries:
            self.disconnect(org_id, ws)
        for _org_id, ws in entries:
            try:
                await ws.close(code=CLOSE_ACCESS_ENDED)
            except Exception:
                pass   # already gone
        return len(entries)

    def close_user_from_sync(self, user_id: str) -> None:
        """close_user for sync (threadpool) endpoints. Best effort: if there is no event loop to
        hand it to (e.g. a script or a test), the periodic re-check in the WebSocket endpoint
        still closes the connections within a few minutes."""
        try:
            anyio.from_thread.run(self.close_user, str(user_id))
        except Exception as exc:
            logger.info(f"close_user_from_sync skipped ({type(exc).__name__}); periodic re-check will close it")

    async def send_to_org(self, org_id: str, message: dict) -> None:
        """Push a JSON message to ALL connected clients of an organisation (all roles)."""
        bucket = set(self._connections.get(org_id, set()))
        dead: Set[Tuple[str, WebSocket]] = set()
        for role_key, ws in bucket:
            try:
                await ws.send_json(message)
            except Exception:
                dead.add((role_key, ws))
        for entry in dead:
            self._connections.get(org_id, set()).discard(entry)

    async def send_to_org_role(self, org_id: str, role_key: str, message: dict) -> None:
        """Push a JSON message only to connected clients of an org with a specific role."""
        bucket = set(self._connections.get(org_id, set()))
        dead: Set[Tuple[str, WebSocket]] = set()
        for rk, ws in bucket:
            if rk == role_key:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead.add((rk, ws))
        for entry in dead:
            self._connections.get(org_id, set()).discard(entry)

    def connected_count(self, org_id: str) -> int:
        return len(self._connections.get(org_id, set()))


# Singleton — imported by the notifications router and the trips endpoints
manager = ConnectionManager()
