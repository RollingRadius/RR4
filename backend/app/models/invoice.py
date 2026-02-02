"""
Invoice and InvoiceLineItem models for fleet management.
Tracks invoices sent to customers with line items and payment tracking.
"""

from sqlalchemy import Column, String, Text, Date, DateTime, Numeric, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import date as date_type
import uuid

from app.database import Base


class Invoice(Base):
    """
    Invoice model for customer billing.

    Tracks invoices with line items and payment status.
    """
    __tablename__ = "invoices"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Invoice Identification
    invoice_number = Column(String(50), nullable=False, unique=True, index=True)

    # Customer Information
    customer_name = Column(String(255), nullable=False)
    customer_email = Column(String(255), nullable=True)
    customer_phone = Column(String(20), nullable=True)
    customer_address = Column(Text, nullable=True)
    customer_gstin = Column(String(15), nullable=True)

    # Invoice Dates
    invoice_date = Column(Date, nullable=False, index=True)
    due_date = Column(Date, nullable=False, index=True)

    # Amounts
    subtotal = Column(Numeric(12, 2), nullable=False)
    tax_amount = Column(Numeric(12, 2), nullable=False, default=0)
    total_amount = Column(Numeric(12, 2), nullable=False)
    amount_paid = Column(Numeric(12, 2), nullable=False, default=0)

    # Status
    status = Column(String(20), nullable=False, default='draft', index=True)

    # Additional Information
    notes = Column(Text, nullable=True)
    terms_and_conditions = Column(Text, nullable=True)

    # Sent Information
    sent_at = Column(DateTime, nullable=True)
    sent_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

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
    sender = relationship("User", foreign_keys=[sent_by])
    creator = relationship("User", foreign_keys=[created_by])
    line_items = relationship(
        "InvoiceLineItem",
        back_populates="invoice",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled')",
            name='check_invoice_status'
        ),
        CheckConstraint(
            "subtotal >= 0",
            name='check_invoice_subtotal_positive'
        ),
        CheckConstraint(
            "tax_amount >= 0",
            name='check_invoice_tax_positive'
        ),
        CheckConstraint(
            "total_amount >= 0",
            name='check_invoice_total_positive'
        ),
        CheckConstraint(
            "amount_paid >= 0",
            name='check_invoice_paid_positive'
        ),
        CheckConstraint(
            "due_date >= invoice_date",
            name='check_invoice_due_after_date'
        ),
        Index('idx_invoice_org_number', 'organization_id', 'invoice_number', unique=True),
        Index('idx_invoice_status_due', 'status', 'due_date'),
    )

    def __repr__(self):
        return f"<Invoice(id={self.id}, number='{self.invoice_number}', customer='{self.customer_name}', total={self.total_amount})>"

    @property
    def is_overdue(self) -> bool:
        """Check if invoice is overdue"""
        return (
            self.status in ['sent', 'partially_paid'] and
            self.due_date < date_type.today()
        )

    @property
    def is_fully_paid(self) -> bool:
        """Check if invoice is fully paid"""
        return self.amount_paid >= self.total_amount

    @property
    def amount_due(self):
        """Calculate amount still due"""
        return self.total_amount - self.amount_paid

    def can_send(self) -> bool:
        """Check if invoice can be sent"""
        return self.status == 'draft'

    def can_record_payment(self) -> bool:
        """Check if payment can be recorded"""
        return self.status in ['sent', 'partially_paid', 'overdue']


class InvoiceLineItem(Base):
    """
    InvoiceLineItem model for itemized billing.
    """
    __tablename__ = "invoice_line_items"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Invoice Reference
    invoice_id = Column(
        UUID(as_uuid=True),
        ForeignKey("invoices.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Line Item Details
    description = Column(Text, nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)

    # Optional Reference
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="SET NULL"),
        nullable=True
    )

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    invoice = relationship("Invoice", back_populates="line_items")
    vehicle = relationship("Vehicle")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "quantity > 0",
            name='check_line_item_quantity_positive'
        ),
        CheckConstraint(
            "unit_price >= 0",
            name='check_line_item_price_positive'
        ),
        CheckConstraint(
            "amount >= 0",
            name='check_line_item_amount_positive'
        ),
    )

    def __repr__(self):
        return f"<InvoiceLineItem(id={self.id}, invoice_id={self.invoice_id}, description='{self.description}', amount={self.amount})>"
