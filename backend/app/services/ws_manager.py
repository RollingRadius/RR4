"""
WebSocket Connection Manager
Tracks active WebSocket connections keyed by organisation ID for push notifications.
"""

from typing import Dict, Set
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        # org_id (str) → set of live WebSocket connections
        self._connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, org_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._connections.setdefault(org_id, set()).add(ws)

    def disconnect(self, org_id: str, ws: WebSocket) -> None:
        bucket = self._connections.get(org_id)
        if bucket:
            bucket.discard(ws)
            if not bucket:
                del self._connections[org_id]

    async def send_to_org(self, org_id: str, message: dict) -> None:
        """Push a JSON message to all connected clients of an organisation."""
        bucket = set(self._connections.get(org_id, set()))  # copy to avoid mutation
        dead: Set[WebSocket] = set()
        for ws in bucket:
            try:
                await ws.send_json(message)
            except Exception:
                dead.add(ws)
        for ws in dead:
            self.disconnect(org_id, ws)

    def connected_count(self, org_id: str) -> int:
        return len(self._connections.get(org_id, set()))


# Singleton — imported by the notifications router and the trips stage-4 endpoint
manager = ConnectionManager()
