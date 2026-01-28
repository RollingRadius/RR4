"""
Audit Log Model
Comprehensive audit trail for all system activities
"""

from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class AuditLog(Base):
    """
    Audit Log model.

    Tracks all significant system activities:
    - User signup, login, logout
    - Email verification
    - Password/username recovery
    - Company creation, joining
    - Account lockout/unlock
    - Failed authentication attempts

    Provides complete audit trail for compliance and security monitoring.
    """
    __tablename__ = "audit_logs"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Keys (nullable for system-level events)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True, index=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'), nullable=True, index=True)

    # Event Information
    action = Column(String(100), nullable=False, index=True)  # 'user_signup', 'user_login', etc.
    entity_type = Column(String(50), nullable=True)  # 'user', 'company', 'role', etc.
    entity_id = Column(UUID(as_uuid=True), nullable=True)

    # Additional Details (flexible JSON storage)
    details = Column(JSONB, nullable=True)

    # Request Metadata
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    organization = relationship("Organization", foreign_keys=[organization_id])

    def __repr__(self):
        return f"<AuditLog(action='{self.action}', user_id={self.user_id}, created_at={self.created_at})>"

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": str(self.id),
            "user_id": str(self.user_id) if self.user_id else None,
            "organization_id": str(self.organization_id) if self.organization_id else None,
            "action": self.action,
            "entity_type": self.entity_type,
            "entity_id": str(self.entity_id) if self.entity_id else None,
            "details": self.details,
            "ip_address": self.ip_address,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
