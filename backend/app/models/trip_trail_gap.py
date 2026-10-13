"""
Trip Trail Gap Model
Caches the road route drawn across a "location was off" gap in a driver's
trail (last ping before the gap -> first ping after it), so a gap is routed
once and not on every trail view. See docs/tracking/gap_trail_design_2026-10.md.
"""

from sqlalchemy import Column, String, Integer, Float, ForeignKey, UniqueConstraint, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid

from app.database import Base


class TripTrailGap(Base):
    __tablename__ = "trip_trail_gaps"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True)
    # driver_locations is a partitioned table, so these are plain ids (no FK).
    from_ping_id = Column(UUID(as_uuid=True), nullable=False)
    to_ping_id = Column(UUID(as_uuid=True), nullable=False)

    route_points = Column(JSONB, nullable=True)  # [[lat, lng], ...]
    distance_km = Column(Float, nullable=True)
    provider = Column(String(20), nullable=False)
    mode = Column(String(20), nullable=False)
    status = Column(String(10), nullable=False)  # ok | pending
    attempts = Column(Integer, nullable=False, default=0)
    next_retry_at = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("trip_id", "from_ping_id", "to_ping_id", name="uq_trip_trail_gaps_pair"),
    )
