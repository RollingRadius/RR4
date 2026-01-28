"""
Zone Model
Represents custom drawn zones/areas with polygon coordinates
"""

from sqlalchemy import Column, String, Text, DateTime, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Zone(Base):
    """
    Zone model for custom drawn areas/regions.

    Stores polygon coordinates as GeoJSON-like structure.
    Can be used for service areas, delivery zones, parking areas, etc.
    """
    __tablename__ = "zones"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Zone Information
    name = Column(String(255), nullable=False)
    zone_type = Column(String(50), nullable=False, index=True)  # service_area, parking, restricted, delivery, custom
    description = Column(Text, nullable=True)

    # Polygon Coordinates (stored as JSONB)
    # Format: {"type": "Polygon", "coordinates": [[lat, lng], [lat, lng], ...]}
    coordinates = Column(JSONB, nullable=False)

    # Metadata
    color = Column(String(7), nullable=False, default='#3B82F6')  # Hex color for display
    fill_opacity = Column(String(4), nullable=False, default='0.3')  # Opacity 0.0 to 1.0
    stroke_width = Column(String(4), nullable=False, default='2')  # Border width in pixels

    # Status
    status = Column(String(20), nullable=False, default='active', index=True)

    # Audit Fields
    created_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    organization = relationship("Organization")
    creator = relationship("User")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "zone_type IN ('service_area', 'parking', 'restricted', 'delivery', 'geofence', 'custom')",
            name='check_zone_type'
        ),
        CheckConstraint(
            "status IN ('active', 'inactive', 'archived')",
            name='check_zone_status'
        ),
        CheckConstraint(
            "color ~ '^#[0-9A-Fa-f]{6}$'",
            name='check_color_format'
        ),
        Index('idx_zone_org_type', 'organization_id', 'zone_type'),
    )

    def __repr__(self):
        return f"<Zone(id={self.id}, name='{self.name}', type='{self.zone_type}')>"

    def get_coordinate_count(self) -> int:
        """Get number of coordinate points in the polygon"""
        if self.coordinates and 'coordinates' in self.coordinates:
            return len(self.coordinates['coordinates'])
        return 0

    def to_geojson(self) -> dict:
        """Convert zone to GeoJSON format"""
        return {
            "type": "Feature",
            "id": str(self.id),
            "properties": {
                "name": self.name,
                "zone_type": self.zone_type,
                "description": self.description,
                "color": self.color,
                "fill_opacity": self.fill_opacity,
                "stroke_width": self.stroke_width,
                "status": self.status,
                "created_at": self.created_at.isoformat() if self.created_at else None,
            },
            "geometry": self.coordinates
        }
