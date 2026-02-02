"""
Payment model for fleet management.
Tracks payments received and paid for invoices and expenses.
"""

from sqlalchemy import Column, String, Text, Date, DateTime, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Payment(Base):
    """
    Payment model for tracking received and paid transactions.

    Links to invoices (for received payments) or expenses (for paid payments).
    """
    __tablename__ = "payments"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Payment Identification
    payment_number = Column(String(50), nullable=False, unique=True, index=True)

    # Payment Details
    payment_type = Column(String(20), nullable=False, index=True)  # received or paid
    payment_method = Column(String(50), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    payment_date = Column(Date, nullable=False, index=True)

    # Reference to Invoice or Expense
    invoice_id = Column(
        UUID(as_uuid=True),
        ForeignKey("invoices.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )
    expense_id = Column(
        UUID(as_uuid=True),
        ForeignKey("expenses.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Payment Information
    reference_number = Column(String(100), nullable=True)  # Cheque/transaction number
    bank_name = Column(String(255), nullable=True)
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
    invoice = relationship("Invoice")
    expense = relationship("Expense")
    creator = relationship("User", foreign_keys=[created_by])

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "payment_type IN ('received', 'paid')",
            name='check_payment_type'
        ),
        CheckConstraint(
            "payment_method IN ('cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other')",
            name='check_payment_method'
        ),
        CheckConstraint(
            "amount > 0",
            name='check_payment_amount_positive'
        ),
        CheckConstraint(
            "(invoice_id IS NOT NULL AND expense_id IS NULL) OR (invoice_id IS NULL AND expense_id IS NOT NULL)",
            name='check_payment_reference_exclusive'
        ),
        Index('idx_payment_org_number', 'organization_id', 'payment_number', unique=True),
        Index('idx_payment_type_date', 'payment_type', 'payment_date'),
    )

    def __repr__(self):
        return f"<Payment(id={self.id}, number='{self.payment_number}', type='{self.payment_type}', amount={self.amount})>"

    @property
    def is_received(self) -> bool:
        """Check if this is a received payment"""
        return self.payment_type == 'received'

    @property
    def is_paid(self) -> bool:
        """Check if this is a paid payment"""
        return self.payment_type == 'paid'
