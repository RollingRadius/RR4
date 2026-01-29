"""
Role Model
Represents user roles in the system
"""

from sqlalchemy import Column, String, Text, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Role(Base):
    """
    Role model for role-based access control.

    System roles (Owner, Pending User, Independent User) cannot be modified or deleted.
    Additional roles can be added for fleet management features in future phases.
    """
    __tablename__ = "roles"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Role Information
    role_name = Column(String(100), unique=True, nullable=False)
    role_key = Column(String(50), unique=True, nullable=False)  # 'owner', 'pending_user', etc.
    description = Column(Text, nullable=True)

    # System Role Flag
    is_system_role = Column(Boolean, nullable=False, default=False)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user_organizations = relationship(
        "UserOrganization",
        foreign_keys="[UserOrganization.role_id]",
        back_populates="role"
    )
    capabilities = relationship(
        "RoleCapability",
        back_populates="role",
        cascade="all, delete-orphan"
    )
    custom_role = relationship(
        "CustomRole",
        back_populates="role",
        uselist=False,
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<Role(id={self.id}, name='{self.role_name}', key='{self.role_key}')>"

    def is_owner(self) -> bool:
        """Check if this is the Owner role"""
        return self.role_key == 'owner'

    def is_pending_user(self) -> bool:
        """Check if this is the Pending User role"""
        return self.role_key == 'pending_user'

    def is_independent_user(self) -> bool:
        """Check if this is the Independent User role"""
        return self.role_key == 'independent_user'

    def is_custom_role(self) -> bool:
        """Check if this is a custom role"""
        return self.custom_role is not None

    def to_dict(self):
        """Convert role to dictionary"""
        return {
            "id": str(self.id),
            "role_name": self.role_name,
            "role_key": self.role_key,
            "description": self.description,
            "is_system_role": self.is_system_role,
            "is_custom_role": self.is_custom_role(),
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
