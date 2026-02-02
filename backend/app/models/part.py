"""
Part and PartUsage models for fleet management.
Tracks parts inventory and usage in maintenance.
"""

from sqlalchemy import Column, String, Text, DateTime, Integer, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from decimal import Decimal
import uuid

from app.database import Base


class Part(Base):
    """
    Part model for inventory management.

    Tracks parts with stock levels and costs.
    """
    __tablename__ = "parts"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Part Identification
    part_number = Column(String(50), nullable=False, index=True)
    part_name = Column(String(255), nullable=False)
    category = Column(String(50), nullable=False, index=True)

    # Description
    description = Column(Text, nullable=True)
    manufacturer = Column(String(255), nullable=True)
    model_compatibility = Column(Text, nullable=True)  # Which vehicle models this fits

    # Stock Information
    quantity_in_stock = Column(Integer, nullable=False, default=0)
    minimum_stock_level = Column(Integer, nullable=False, default=0)
    reorder_quantity = Column(Integer, nullable=False, default=0)

    # Unit of Measurement
    unit = Column(String(20), nullable=False, default='piece')  # piece, liter, kg, etc.

    # Cost Information
    unit_cost = Column(Numeric(12, 2), nullable=False)
    selling_price = Column(Numeric(12, 2), nullable=True)

    # Location
    location = Column(String(255), nullable=True)  # Warehouse location

    # Status
    is_active = Column(String(20), nullable=False, default='active')

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
    creator = relationship("User", foreign_keys=[created_by])
    usage_records = relationship(
        "PartUsage",
        back_populates="part",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "category IN ('engine', 'transmission', 'brake', 'suspension', 'electrical', 'tire', 'body', 'fluid', 'other')",
            name='check_part_category'
        ),
        CheckConstraint(
            "quantity_in_stock >= 0",
            name='check_part_quantity_positive'
        ),
        CheckConstraint(
            "minimum_stock_level >= 0",
            name='check_part_min_stock_positive'
        ),
        CheckConstraint(
            "reorder_quantity >= 0",
            name='check_part_reorder_positive'
        ),
        CheckConstraint(
            "unit_cost >= 0",
            name='check_part_cost_positive'
        ),
        CheckConstraint(
            "selling_price IS NULL OR selling_price >= 0",
            name='check_part_price_positive'
        ),
        Index('idx_part_org_number', 'organization_id', 'part_number', unique=True),
        Index('idx_part_category_active', 'category', 'is_active'),
    )

    def __repr__(self):
        return f"<Part(id={self.id}, number='{self.part_number}', name='{self.part_name}', stock={self.quantity_in_stock})>"

    @property
    def is_low_stock(self) -> bool:
        """Check if part stock is below minimum level"""
        return self.quantity_in_stock <= self.minimum_stock_level

    @property
    def stock_value(self) -> Decimal:
        """Calculate total value of stock"""
        return Decimal(str(self.quantity_in_stock)) * self.unit_cost

    def needs_reorder(self) -> bool:
        """Check if part needs to be reordered"""
        return self.is_low_stock and self.is_active == 'active'


class PartUsage(Base):
    """
    PartUsage model for tracking part consumption.

    Links parts to work orders and vehicles.
    """
    __tablename__ = "part_usage"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Part Reference
    part_id = Column(
        UUID(as_uuid=True),
        ForeignKey("parts.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Work Order Reference
    work_order_id = Column(
        UUID(as_uuid=True),
        ForeignKey("work_orders.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Vehicle Reference
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Usage Details
    quantity_used = Column(Numeric(10, 2), nullable=False)
    unit_cost_at_usage = Column(Numeric(12, 2), nullable=False)  # Cost at time of usage
    total_cost = Column(Numeric(12, 2), nullable=False)

    # Usage Information
    usage_date = Column(DateTime, nullable=False, server_default=func.now())
    notes = Column(Text, nullable=True)

    # Audit Fields
    recorded_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    part = relationship("Part", back_populates="usage_records")
    work_order = relationship("WorkOrder")
    vehicle = relationship("Vehicle")
    recorder = relationship("User")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "quantity_used > 0",
            name='check_usage_quantity_positive'
        ),
        CheckConstraint(
            "unit_cost_at_usage >= 0",
            name='check_usage_cost_positive'
        ),
        CheckConstraint(
            "total_cost >= 0",
            name='check_usage_total_positive'
        ),
        Index('idx_part_usage_work_order', 'work_order_id'),
        Index('idx_part_usage_vehicle', 'vehicle_id'),
        Index('idx_part_usage_date', 'usage_date'),
    )

    def __repr__(self):
        return f"<PartUsage(id={self.id}, part_id={self.part_id}, work_order_id={self.work_order_id}, quantity={self.quantity_used})>"
