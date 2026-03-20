"""
Load Requirement Model
Represents cargo/load requirements posted by load_owner companies.
"""

from sqlalchemy import Column, String, Text, Date, Integer, TIMESTAMP, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class LoadRequirement(Base):
    __tablename__ = "load_requirements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    created_by = Column(UUID(as_uuid=True), nullable=True)

    entry_method = Column(String(10), nullable=False, default='manual')

    pickup_location = Column(Text, nullable=True)
    unload_location = Column(Text, nullable=True)
    material_type = Column(String(50), nullable=True)
    entry_date = Column(Date, nullable=True)
    truck_count = Column(Integer, nullable=False, default=1)

    capacity = Column(String(50), nullable=True)
    axel_type = Column(String(50), nullable=True)
    body_type = Column(String(50), nullable=True)
    floor_type = Column(String(50), nullable=True)

    status = Column(String(20), nullable=False, default='pending')
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
