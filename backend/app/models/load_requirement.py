"""
Load Requirement Model
Represents cargo/load requirements posted by load_owner companies.
"""

from sqlalchemy import Column, String, Text, Date, Integer, Float, TIMESTAMP, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid

from app.database import Base


class LoadRequirement(Base):
    __tablename__ = "load_requirements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    entry_method = Column(String(10), nullable=False, default='manual')

    pickup_location = Column(Text, nullable=True)
    pickup_lat = Column(Float, nullable=True)
    pickup_lon = Column(Float, nullable=True)
    unload_location = Column(Text, nullable=True)
    unload_lat = Column(Float, nullable=True)
    unload_lon = Column(Float, nullable=True)
    material_type = Column(String(50), nullable=True)
    entry_date = Column(Date, nullable=True)
    truck_count = Column(Integer, nullable=False, default=1)

    capacity = Column(String(50), nullable=True)
    axel_type = Column(String(50), nullable=True)
    body_type = Column(String(50), nullable=True)
    floor_type = Column(String(50), nullable=True)

    # Which fleet management org is fulfilling this load (set on fulfill)
    fulfilling_org_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # If set, only these fleet-management orgs can see this load; null = visible to all
    target_org_ids = Column(JSONB, nullable=True)

    status = Column(String(20), nullable=False, default='pending')
    # Values: pending | matched | fulfilled | cancelled
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
