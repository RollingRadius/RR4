"""
Budget model for fleet management.
Tracks budgets for expense categories with spend monitoring.
"""

from sqlalchemy import Column, String, Date, DateTime, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from decimal import Decimal
import uuid

from app.database import Base


class Budget(Base):
    """
    Budget model for expense tracking and monitoring.

    Tracks allocated budgets by category and period with automatic spend updates.
    """
    __tablename__ = "budgets"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Budget Details
    name = Column(String(255), nullable=False)
    category = Column(String(50), nullable=False, index=True)
    period = Column(String(20), nullable=False, index=True)  # monthly, quarterly, yearly

    # Date Range
    start_date = Column(Date, nullable=False, index=True)
    end_date = Column(Date, nullable=False, index=True)

    # Amounts
    allocated_amount = Column(Numeric(12, 2), nullable=False)
    spent_amount = Column(Numeric(12, 2), nullable=False, default=0)
    remaining_amount = Column(Numeric(12, 2), nullable=False)

    # Alert Threshold
    alert_threshold_percent = Column(Numeric(5, 2), nullable=False, default=80)  # Alert at 80% by default

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

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "category IN ('fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other')",
            name='check_budget_category'
        ),
        CheckConstraint(
            "period IN ('monthly', 'quarterly', 'yearly')",
            name='check_budget_period'
        ),
        CheckConstraint(
            "allocated_amount > 0",
            name='check_budget_allocated_positive'
        ),
        CheckConstraint(
            "spent_amount >= 0",
            name='check_budget_spent_positive'
        ),
        CheckConstraint(
            "remaining_amount >= 0",
            name='check_budget_remaining_positive'
        ),
        CheckConstraint(
            "alert_threshold_percent > 0 AND alert_threshold_percent <= 100",
            name='check_budget_threshold_range'
        ),
        CheckConstraint(
            "end_date > start_date",
            name='check_budget_end_after_start'
        ),
        Index('idx_budget_org_category_period', 'organization_id', 'category', 'start_date'),
        Index('idx_budget_dates', 'start_date', 'end_date'),
    )

    def __repr__(self):
        return f"<Budget(id={self.id}, name='{self.name}', category='{self.category}', allocated={self.allocated_amount}, spent={self.spent_amount})>"

    @property
    def percentage_spent(self) -> Decimal:
        """Calculate percentage of budget spent"""
        if self.allocated_amount == 0:
            return Decimal('0')
        return (self.spent_amount / self.allocated_amount) * Decimal('100')

    @property
    def is_over_threshold(self) -> bool:
        """Check if spending is over alert threshold"""
        return self.percentage_spent >= self.alert_threshold_percent

    @property
    def is_exceeded(self) -> bool:
        """Check if budget is exceeded"""
        return self.spent_amount > self.allocated_amount

    def is_active(self) -> bool:
        """Check if budget period is currently active"""
        from datetime import date
        today = date.today()
        return self.start_date <= today <= self.end_date
