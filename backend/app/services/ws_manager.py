"""
WebSocket Connection Manager
Tracks active WebSocket connections keyed by organisation ID for push notifications.
Supports role-aware broadcasting so notifications can target specific roles within an org.
"""

from typing import Dict, Set, Tuple
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        # org_id (str) → set of (role_key, WebSocket) tuples
        self._connections: Dict[str, Set[Tuple[str, WebSocket]]] = {}

    async def connect(self, org_id: str, role_key: str, ws: WebSocket) -> None:
        await ws.accept()
        self._connections.setdefault(org_id, set()).add((role_key, ws))

    def disconnect(self, org_id: str, ws: WebSocket) -> None:
        bucket = self._connections.get(org_id)
        if bucket:
            to_remove = {entry for entry in bucket if entry[1] == ws}
            bucket -= to_remove
            if not bucket:
                del self._connections[org_id]

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
