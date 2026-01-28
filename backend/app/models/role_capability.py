"""
Role Capability Mapping Model
"""
from sqlalchemy import Column, String, JSON, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.database import Base


class RoleCapability(Base):
    """
    Maps capabilities to roles (both predefined and custom).
    Defines what access level each role has for each capability.
    """
    __tablename__ = "role_capabilities"
    __table_args__ = (
        UniqueConstraint('role_id', 'capability_key', name='unique_role_capability'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_id = Column(UUID(as_uuid=True), ForeignKey('roles.id', ondelete='CASCADE'), nullable=False, index=True)
    capability_key = Column(String(100), ForeignKey('capabilities.capability_key', ondelete='CASCADE'), nullable=False, index=True)
    access_level = Column(String(20), nullable=False)  # none, view, limited, full
    constraints = Column(JSON, nullable=True)  # Additional constraints (region, time, etc.)
    granted_at = Column(DateTime, default=datetime.utcnow)
    granted_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)

    # Relationships
    role = relationship("Role", back_populates="capabilities")
    capability = relationship("Capability")
    granted_by_user = relationship("User", foreign_keys=[granted_by])

    def __repr__(self):
        return f"<RoleCapability role={self.role_id} capability={self.capability_key} level={self.access_level}>"

    def to_dict(self):
        return {
            "id": str(self.id),
            "role_id": str(self.role_id),
            "capability_key": self.capability_key,
            "access_level": self.access_level,
            "constraints": self.constraints,
            "granted_at": self.granted_at.isoformat() if self.granted_at else None,
            "granted_by": str(self.granted_by) if self.granted_by else None
        }
