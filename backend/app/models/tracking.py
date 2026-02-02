"""
GPS Tracking Models
Represents location tracking, geofence events, and route optimizations
"""

from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey, CheckConstraint, Index, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class DriverLocation(Base):
    """
    Driver Location model for GPS tracking.

    Stores real-time and historical location data for drivers.
    Table is partitioned by timestamp (monthly) for performance.
    """
    __tablename__ = "driver_locations"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # References
    driver_id = Column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Location Data
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)
    accuracy = Column(Float, nullable=True)  # meters
    altitude = Column(Float, nullable=True)  # meters
    speed = Column(Float, nullable=True)  # meters/second
    heading = Column(Float, nullable=True)  # degrees (0-360)

    # Device Information
    battery_level = Column(Integer, nullable=True)  # 0-100
    is_mock_location = Column(Boolean, nullable=False, default=False)

    # Timestamps
    timestamp = Column(DateTime(timezone=True), nullable=False)  # GPS timestamp
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    # Relationships
    driver = relationship("Driver", foreign_keys=[driver_id])
    organization = relationship("Organization")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            'latitude BETWEEN -90 AND 90',
            name='valid_latitude'
        ),
        CheckConstraint(
            'longitude BETWEEN -180 AND 180',
            name='valid_longitude'
        ),
        CheckConstraint(
            'battery_level IS NULL OR battery_level BETWEEN 0 AND 100',
            name='valid_battery_level'
        ),
        Index('idx_locations_driver_time', 'driver_id', 'timestamp'),
        Index('idx_locations_org_time', 'organization_id', 'timestamp'),
        Index('idx_locations_timestamp', 'timestamp'),
        # Note: This is a partitioned table, partitions created in migration
        {'postgresql_partition_by': 'RANGE (timestamp)'}
    )

    def __repr__(self):
        return f"<DriverLocation(id={self.id}, driver_id={self.driver_id}, lat={self.latitude}, lng={self.longitude}, timestamp={self.timestamp})>"


class GeofenceEvent(Base):
    """
    Geofence Event model.

    Stores events when drivers enter or exit defined geographic zones.
    """
    __tablename__ = "geofence_events"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # References
    driver_id = Column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    zone_id = Column(
        UUID(as_uuid=True),
        ForeignKey("zones.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    location_id = Column(
        UUID(as_uuid=True),
        nullable=True  # Reference to driver_locations, but nullable for flexibility
    )

    # Event Data
    event_type = Column(String(10), nullable=False)  # 'enter' or 'exit'
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)

    # Timestamps
    timestamp = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    # Relationships
    driver = relationship("Driver")
    zone = relationship("Zone")
    organization = relationship("Organization")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "event_type IN ('enter', 'exit')",
            name='check_event_type'
        ),
        CheckConstraint(
            'latitude BETWEEN -90 AND 90',
            name='check_valid_latitude'
        ),
        CheckConstraint(
            'longitude BETWEEN -180 AND 180',
            name='check_valid_longitude'
        ),
        Index('idx_geofence_driver_time', 'driver_id', 'timestamp'),
        Index('idx_geofence_zone_time', 'zone_id', 'timestamp'),
        Index('idx_geofence_org_time', 'organization_id', 'timestamp'),
    )

    def __repr__(self):
        return f"<GeofenceEvent(id={self.id}, driver_id={self.driver_id}, zone_id={self.zone_id}, type='{self.event_type}')>"


class RouteOptimization(Base):
    """
    Route Optimization model.

    Stores planned and optimized routes for drivers with multiple waypoints.
    """
    __tablename__ = "route_optimizations"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # References
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    created_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Route Information
    name = Column(String(255), nullable=False)

    # JSONB fields for flexible waypoint storage
    # waypoints format: [{"lat": float, "lng": float, "address": str, "order": int}, ...]
    waypoints = Column(JSONB, nullable=False)

    # optimized_route format: [{"lat": float, "lng": float, "address": str, "order": int}, ...]
    optimized_route = Column(JSONB, nullable=True)

    # Route Metrics
    total_distance = Column(Float, nullable=True)  # in kilometers
    estimated_duration = Column(Integer, nullable=True)  # in minutes

    # Status
    status = Column(
        String(20),
        nullable=False,
        default='draft',
        server_default='draft',
        index=True
    )

    # Timestamps
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    organization = relationship("Organization")
    creator = relationship("User", foreign_keys=[created_by])

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'active', 'completed')",
            name='check_status'
        ),
        Index('idx_routes_org', 'organization_id'),
        Index('idx_routes_created_by', 'created_by'),
        Index('idx_routes_status', 'status'),
    )

    def __repr__(self):
        return f"<RouteOptimization(id={self.id}, name='{self.name}', status='{self.status}')>"

    @property
    def waypoint_count(self) -> int:
        """Get the number of waypoints in the route"""
        if isinstance(self.waypoints, list):
            return len(self.waypoints)
        return 0

    @property
    def is_optimized(self) -> bool:
        """Check if the route has been optimized"""
        return self.optimized_route is not None
