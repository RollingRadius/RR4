"""
KPI and KPIHistory models for fleet management.
Tracks Key Performance Indicators with historical trends.
"""

from sqlalchemy import Column, String, Text, DateTime, Numeric, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class KPI(Base):
    """
    KPI model for defining Key Performance Indicators.

    Stores KPI configuration and calculation logic.
    """
    __tablename__ = "kpis"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # KPI Details
    kpi_name = Column(String(255), nullable=False)
    kpi_code = Column(String(50), nullable=False, index=True)  # Unique code for programmatic access
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=False, index=True)  # fleet, financial, maintenance, etc.

    # Calculation Configuration
    calculation_config = Column(JSONB, nullable=False)
    # Example calculation_config:
    # {
    #   "metric": "average_fuel_cost_per_km",
    #   "formula": "total_fuel_expense / total_km_driven",
    #   "data_sources": ["expenses", "vehicles"],
    #   "filters": {"category": "fuel", "status": "paid"},
    #   "aggregation": "avg|sum|count|min|max"
    # }

    # Target Values (optional)
    target_value = Column(Numeric(12, 2), nullable=True)
    min_threshold = Column(Numeric(12, 2), nullable=True)
    max_threshold = Column(Numeric(12, 2), nullable=True)

    # Display Configuration
    display_config = Column(JSONB, nullable=True)
    # Example display_config:
    # {
    #   "format": "currency|percentage|number",
    #   "precision": 2,
    #   "prefix": "$",
    #   "suffix": "/km"
    # }

    # Current Value (cached)
    current_value = Column(Numeric(12, 2), nullable=True)
    last_calculated_at = Column(DateTime, nullable=True)

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
    history = relationship(
        "KPIHistory",
        back_populates="kpi",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        Index('idx_kpi_org_code', 'organization_id', 'kpi_code', unique=True),
        Index('idx_kpi_category_active', 'category', 'is_active'),
    )

    def __repr__(self):
        return f"<KPI(id={self.id}, name='{self.kpi_name}', code='{self.kpi_code}', value={self.current_value})>"

    @property
    def is_above_target(self) -> bool:
        """Check if current value is above target"""
        if self.current_value is not None and self.target_value is not None:
            return self.current_value > self.target_value
        return False

    @property
    def is_below_min(self) -> bool:
        """Check if current value is below minimum threshold"""
        if self.current_value is not None and self.min_threshold is not None:
            return self.current_value < self.min_threshold
        return False

    @property
    def is_above_max(self) -> bool:
        """Check if current value is above maximum threshold"""
        if self.current_value is not None and self.max_threshold is not None:
            return self.current_value > self.max_threshold
        return False


class KPIHistory(Base):
    """
    KPIHistory model for tracking KPI values over time.

    Stores historical KPI values for trend analysis.
    """
    __tablename__ = "kpi_history"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # KPI Reference
    kpi_id = Column(
        UUID(as_uuid=True),
        ForeignKey("kpis.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Historical Value
    value = Column(Numeric(12, 2), nullable=False)
    calculated_at = Column(DateTime, nullable=False, server_default=func.now(), index=True)

    # Calculation Metadata
    calculation_details = Column(JSONB, nullable=True)
    # Example calculation_details:
    # {
    #   "data_points": 150,
    #   "date_range": {"from": "2024-01-01", "to": "2024-01-31"},
    #   "filters_applied": {...}
    # }

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    kpi = relationship("KPI", back_populates="history")

    # Constraints
    __table_args__ = (
        Index('idx_kpi_history_kpi_date', 'kpi_id', 'calculated_at'),
    )

    def __repr__(self):
        return f"<KPIHistory(id={self.id}, kpi_id={self.kpi_id}, value={self.value}, calculated_at={self.calculated_at})>"
