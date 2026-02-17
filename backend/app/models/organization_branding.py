"""
Organization Branding Model
Stores white-label branding configuration for organizations
"""

from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class OrganizationBranding(Base):
    """
    Organization Branding model.

    Stores white-label branding configuration including logo and color theme.
    Each organization can have one branding configuration.
    """
    __tablename__ = "organization_branding"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Key
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey('organizations.id', ondelete='CASCADE'),
        nullable=False,
        unique=True,
        index=True
    )

    # Logo Fields
    logo_url = Column(String(500), nullable=True)
    logo_filename = Column(String(255), nullable=True)
    logo_size_bytes = Column(Integer, nullable=True)
    logo_uploaded_at = Column(DateTime, nullable=True)

    # Color Fields (hex format: #RRGGBB)
    primary_color = Column(String(7), nullable=False, default='#1E40AF')
    primary_dark = Column(String(7), nullable=False, default='#1E3A8A')
    primary_light = Column(String(7), nullable=False, default='#3B82F6')
    secondary_color = Column(String(7), nullable=False, default='#06B6D4')
    accent_color = Column(String(7), nullable=False, default='#0EA5E9')
    background_primary = Column(String(7), nullable=False, default='#F8FAFC')
    background_secondary = Column(String(7), nullable=False, default='#FFFFFF')

    # Flexible Configuration (JSONB for future extensibility)
    theme_config = Column(JSONB, nullable=False, default={})

    # Audit Fields
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    created_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    updated_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)

    # Relationships
    organization = relationship("Organization", back_populates="branding")
    creator = relationship("User", foreign_keys=[created_by])
    updater = relationship("User", foreign_keys=[updated_by])

    def __repr__(self):
        return f"<OrganizationBranding(id={self.id}, org_id={self.organization_id}, primary={self.primary_color})>"

    def to_dict(self):
        """Convert branding to dictionary for API serialization"""
        return {
            "id": str(self.id),
            "organization_id": str(self.organization_id),
            "logo": {
                "url": self.logo_url,
                "filename": self.logo_filename,
                "size_bytes": self.logo_size_bytes,
                "uploaded_at": self.logo_uploaded_at.isoformat() if self.logo_uploaded_at else None
            } if self.logo_url else None,
            "colors": {
                "primary_color": self.primary_color,
                "primary_dark": self.primary_dark,
                "primary_light": self.primary_light,
                "secondary_color": self.secondary_color,
                "accent_color": self.accent_color,
                "background_primary": self.background_primary,
                "background_secondary": self.background_secondary
            },
            "theme_config": self.theme_config,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
