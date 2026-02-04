"""
Invoice Schemas
Pydantic models for invoice endpoints
"""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


class InvoiceLineItemRequest(BaseModel):
    """Invoice line item request"""
    description: str = Field(..., min_length=1, max_length=1000)
    quantity: Decimal = Field(..., gt=0, description="Quantity")
    unit_price: Decimal = Field(..., ge=0, description="Unit price")
    vehicle_id: Optional[UUID] = Field(None, description="Related vehicle")


class InvoiceLineItemResponse(BaseModel):
    """Invoice line item response"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    description: str
    quantity: Decimal
    unit_price: Decimal
    amount: Decimal
    vehicle_id: Optional[UUID] = None
    created_at: datetime


class InvoiceCreateRequest(BaseModel):
    """Create new invoice request"""
    customer_name: str = Field(..., min_length=2, max_length=255)
    customer_email: Optional[str] = Field(None, max_length=255)
    customer_phone: Optional[str] = Field(None, max_length=20)
    customer_address: Optional[str] = Field(None, max_length=1000)
    customer_gstin: Optional[str] = Field(None, max_length=15)
    invoice_date: date
    due_date: date
    tax_amount: Decimal = Field(default=Decimal('0'), ge=0, description="Tax amount")
    notes: Optional[str] = Field(None, max_length=1000)
    terms_and_conditions: Optional[str] = Field(None, max_length=2000)
    line_items: List[InvoiceLineItemRequest] = Field(default_factory=list)

    @field_validator('due_date')
    @classmethod
    def validate_due_date(cls, v, info):
        """Validate due date is after invoice date"""
        invoice_date = info.data.get('invoice_date')
        if invoice_date and v < invoice_date:
            raise ValueError('Due date must be on or after invoice date')
        return v

    @field_validator('customer_gstin')
    @classmethod
    def validate_gstin(cls, v):
        """Validate GSTIN format if provided"""
        if v and len(v) != 15:
            raise ValueError('GSTIN must be 15 characters')
        return v


class InvoiceUpdateRequest(BaseModel):
    """Update invoice request (only for draft status)"""
    customer_name: Optional[str] = Field(None, min_length=2, max_length=255)
    customer_email: Optional[str] = Field(None, max_length=255)
    customer_phone: Optional[str] = Field(None, max_length=20)
    customer_address: Optional[str] = Field(None, max_length=1000)
    customer_gstin: Optional[str] = Field(None, max_length=15)
    invoice_date: Optional[date] = None
    due_date: Optional[date] = None
    tax_amount: Optional[Decimal] = Field(None, ge=0)
    notes: Optional[str] = Field(None, max_length=1000)
    terms_and_conditions: Optional[str] = Field(None, max_length=2000)

    @field_validator('customer_gstin')
    @classmethod
    def validate_gstin(cls, v):
        if v and len(v) != 15:
            raise ValueError('GSTIN must be 15 characters')
        return v


class InvoiceSendRequest(BaseModel):
    """Send invoice request"""
    recipient_email: Optional[str] = Field(None, description="Recipient email (defaults to customer email)")
    cc_emails: List[str] = Field(default_factory=list, description="CC email addresses")
    custom_message: Optional[str] = Field(None, max_length=1000, description="Custom message to include")


class InvoiceRecordPaymentRequest(BaseModel):
    """Record payment for invoice request"""
    amount: Decimal = Field(..., gt=0, description="Payment amount")
    payment_date: date = Field(..., description="Payment date")
    payment_method: str = Field(..., description="Payment method")
    reference_number: Optional[str] = Field(None, max_length=100, description="Payment reference number")

    @field_validator('payment_method')
    @classmethod
    def validate_payment_method(cls, v):
        """Validate payment method"""
        valid_methods = ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other']
        if v not in valid_methods:
            raise ValueError(f'Payment method must be one of: {", ".join(valid_methods)}')
        return v


class InvoiceResponse(BaseModel):
    """Invoice response with full details"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    organization_id: UUID
    invoice_number: str
    customer_name: str
    customer_email: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_address: Optional[str] = None
    customer_gstin: Optional[str] = None
    invoice_date: date
    due_date: date
    subtotal: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    amount_paid: Decimal
    status: str
    notes: Optional[str] = None
    terms_and_conditions: Optional[str] = None
    sent_at: Optional[datetime] = None
    sent_by: Optional[UUID] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    line_items: List[InvoiceLineItemResponse] = []

    # Computed fields
    @property
    def is_overdue(self) -> bool:
        """Check if invoice is overdue"""
        return (
            self.status in ['sent', 'partially_paid'] and
            self.due_date < date.today()
        )

    @property
    def is_fully_paid(self) -> bool:
        """Check if invoice is fully paid"""
        return self.amount_paid >= self.total_amount

    @property
    def amount_due(self) -> Decimal:
        """Calculate amount still due"""
        return self.total_amount - self.amount_paid

    @property
    def can_send(self) -> bool:
        """Check if invoice can be sent"""
        return self.status == 'draft'

    @property
    def days_until_due(self) -> int:
        """Calculate days until due (negative if overdue)"""
        return (self.due_date - date.today()).days


class InvoiceListResponse(BaseModel):
    """Paginated invoice list response"""
    total: int
    page: int
    page_size: int
    invoices: List[InvoiceResponse]


class InvoiceSummaryResponse(BaseModel):
    """Invoice summary statistics"""
    total_invoices: int
    total_amount: Decimal
    total_paid: Decimal
    total_due: Decimal
    draft_count: int
    sent_count: int
    partially_paid_count: int
    paid_count: int
    overdue_count: int
    cancelled_count: int
