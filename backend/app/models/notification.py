"""
Notification Model
Persisted push notifications sent to load-owner organisations.
"""

from sqlalchemy import Column, String, Boolean, TIMESTAMP, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id                = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    recipient_org_id  = Column(UUID(as_uuid=True), nullable=True,  index=True)
    recipient_user_id = Column(UUID(as_uuid=True), nullable=True,  index=True)
    recipient_role    = Column(String(50),  nullable=True)   # NULL = visible to all org roles
    trip_id           = Column(UUID(as_uuid=True), nullable=True,  index=True)
    type              = Column(String(50),  nullable=False)
    title             = Column(String(200), nullable=False)
    body              = Column(Text,        nullable=False)
    is_read           = Column(Boolean,     nullable=False, default=False)
    created_at        = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    def to_dict(self) -> dict:
        return {
            "id":       str(self.id),
            "trip_id":  str(self.trip_id) if self.trip_id else None,
            "type":     self.type,
            "title":    self.title,
            "body":     self.body,
            "is_read":  self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
