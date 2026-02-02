"""
Expense and ExpenseAttachment models for fleet management.
Tracks expenses with approval workflow and receipt attachments.
"""

from sqlalchemy import Column, String, Text, Date, DateTime, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Expense(Base):
    """
    Expense model for tracking fleet-related expenses with approval workflow.

    Supports status flow: draft → submitted → approved/rejected → paid
    """
    __tablename__ = "expenses"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Expense Identification
    expense_number = Column(String(50), nullable=False, unique=True, index=True)

    # Expense Details
    category = Column(String(50), nullable=False, index=True)
    description = Column(Text, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    tax_amount = Column(Numeric(12, 2), nullable=False, default=0)
    total_amount = Column(Numeric(12, 2), nullable=False)
    expense_date = Column(Date, nullable=False, index=True)

    # References
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )
    driver_id = Column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )
    vendor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vendors.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Workflow
    status = Column(String(20), nullable=False, default='draft', index=True)
    submitted_at = Column(DateTime, nullable=True)
    submitted_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    approved_at = Column(DateTime, nullable=True)
    approved_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    rejection_reason = Column(Text, nullable=True)
    paid_at = Column(DateTime, nullable=True)

    # Additional Information
    notes = Column(Text, nullable=True)

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
    vehicle = relationship("Vehicle")
    driver = relationship("Driver")
    vendor = relationship("Vendor")
    submitter = relationship("User", foreign_keys=[submitted_by])
    approver = relationship("User", foreign_keys=[approved_by])
    creator = relationship("User", foreign_keys=[created_by])
    attachments = relationship(
        "ExpenseAttachment",
        back_populates="expense",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "category IN ('fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other')",
            name='check_expense_category'
        ),
        CheckConstraint(
            "status IN ('draft', 'submitted', 'approved', 'rejected', 'paid')",
            name='check_expense_status'
        ),
        CheckConstraint(
            "amount >= 0",
            name='check_expense_amount_positive'
        ),
        CheckConstraint(
            "tax_amount >= 0",
            name='check_tax_amount_positive'
        ),
        CheckConstraint(
            "total_amount >= 0",
            name='check_total_amount_positive'
        ),
        Index('idx_expense_org_number', 'organization_id', 'expense_number', unique=True),
        Index('idx_expense_status_date', 'status', 'expense_date'),
    )

    def __repr__(self):
        return f"<Expense(id={self.id}, number='{self.expense_number}', category='{self.category}', amount={self.total_amount})>"

    @property
    def is_draft(self) -> bool:
        """Check if expense is in draft status"""
        return self.status == 'draft'

    @property
    def is_submitted(self) -> bool:
        """Check if expense is submitted for approval"""
        return self.status == 'submitted'

    @property
    def is_approved(self) -> bool:
        """Check if expense is approved"""
        return self.status == 'approved'

    @property
    def is_rejected(self) -> bool:
        """Check if expense is rejected"""
        return self.status == 'rejected'

    @property
    def is_paid(self) -> bool:
        """Check if expense is paid"""
        return self.status == 'paid'

    def can_edit(self) -> bool:
        """Check if expense can be edited"""
        return self.status in ['draft', 'rejected']

    def can_submit(self) -> bool:
        """Check if expense can be submitted"""
        return self.status == 'draft'

    def can_approve(self) -> bool:
        """Check if expense can be approved/rejected"""
        return self.status == 'submitted'

    def can_mark_paid(self) -> bool:
        """Check if expense can be marked as paid"""
        return self.status == 'approved'


class ExpenseAttachment(Base):
    """
    ExpenseAttachment model for storing receipt and invoice files.
    """
    __tablename__ = "expense_attachments"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Expense Reference
    expense_id = Column(
        UUID(as_uuid=True),
        ForeignKey("expenses.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # File Information
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(Numeric(12, 0), nullable=False)
    file_type = Column(String(50), nullable=True)

    # Upload Information
    uploaded_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    uploaded_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    expense = relationship("Expense", back_populates="attachments")
    uploader = relationship("User")

    def __repr__(self):
        return f"<ExpenseAttachment(id={self.id}, expense_id={self.expense_id}, file_name='{self.file_name}')>"
