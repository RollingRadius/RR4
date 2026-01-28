"""
User-Organization Mapping Model
Links users to organizations with roles
"""

from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class UserOrganization(Base):
    """
    User-Organization mapping with role assignment.

    Links users to organizations and assigns roles:
    - Join existing company → Pending User role, status='pending'
    - Create new company → Owner role, status='active'
    - Skip company → Independent User role, organization_id=NULL, status='active'
    """
    __tablename__ = "user_organizations"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Keys
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id', ondelete='CASCADE'), nullable=True, index=True)
    role_id = Column(UUID(as_uuid=True), ForeignKey('roles.id'), nullable=False)

    # Status
    status = Column(String(20), nullable=False, default='pending')  # 'pending', 'active', 'inactive'

    # Approval Tracking
    joined_at = Column(DateTime, nullable=False, server_default=func.now())
    approved_at = Column(DateTime, nullable=True)
    approved_by = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)

    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="organizations")
    organization = relationship("Organization", back_populates="user_organizations")
    role = relationship("Role", back_populates="user_organizations")
    approver = relationship("User", foreign_keys=[approved_by])

    # Constraints
    __table_args__ = (
        UniqueConstraint('user_id', 'organization_id', name='unique_user_org'),
    )

    def __repr__(self):
        return f"<UserOrganization(user_id={self.user_id}, org_id={self.organization_id}, role_id={self.role_id})>"

    def is_active(self) -> bool:
        """Check if user-organization relationship is active"""
        return self.status == 'active'

    def is_pending(self) -> bool:
        """Check if user is pending approval"""
        return self.status == 'pending'
