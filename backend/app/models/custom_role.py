"""
Custom Role Model
"""
from sqlalchemy import Column, String, Text, Boolean, JSON, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.database import Base


class CustomRole(Base):
    """
    Custom roles created by administrators.
    Can be created from templates or from scratch.
    """
    __tablename__ = "custom_roles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_id = Column(UUID(as_uuid=True), ForeignKey('roles.id', ondelete='CASCADE'), unique=True, nullable=False)
    template_sources = Column(ARRAY(String), nullable=True)  # IDs of templates used
    is_template = Column(Boolean, default=False)  # Can this be reused as template?
    template_name = Column(String(100), nullable=True)  # If saved as template
    template_description = Column(Text, nullable=True)
    customizations = Column(JSON, nullable=True)  # Track custom changes from templates
    created_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    role = relationship("Role", back_populates="custom_role")
    created_by_user = relationship("User", foreign_keys=[created_by])

    def __repr__(self):
        return f"<CustomRole role_id={self.role_id}>"

    def to_dict(self):
        return {
            "id": str(self.id),
            "role_id": str(self.role_id),
            "template_sources": self.template_sources,
            "is_template": self.is_template,
            "template_name": self.template_name,
            "template_description": self.template_description,
            "customizations": self.customizations,
            "created_by": str(self.created_by) if self.created_by else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
