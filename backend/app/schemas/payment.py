"""
Payment Schemas
Pydantic models for payment endpoints
"""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


class PaymentCreateRequest(BaseModel):
    """Create new payment request"""
    payment_type: str = Field(..., description="Payment type: received or paid")
    payment_method: str = Field(..., description="Payment method")
    amount: Decimal = Field(..., gt=0, description="Payment amount")
    payment_date: date = Field(..., description="Payment date")
    invoice_id: Optional[UUID] = Field(None, description="Related invoice (for received payments)")
    expense_id: Optional[UUID] = Field(None, description="Related expense (for paid payments)")
    reference_number: Optional[str] = Field(None, max_length=100, description="Payment reference number")
    bank_name: Optional[str] = Field(None, max_length=255, description="Bank name")
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator('payment_type')
    @classmethod
    def validate_payment_type(cls, v):
        """Validate payment type"""
        valid_types = ['received', 'paid']
        if v not in valid_types:
            raise ValueError(f'Payment type must be one of: {", ".join(valid_types)}')
        return v

    @field_validator('payment_method')
    @classmethod
    def validate_payment_method(cls, v):
        """Validate payment method"""
        valid_methods = ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other']
        if v not in valid_methods:
            raise ValueError(f'Payment method must be one of: {", ".join(valid_methods)}')
        return v

    @field_validator('expense_id')
    @classmethod
    def validate_reference(cls, v, info):
        """Validate that payment references exactly one entity (invoice XOR expense)"""
        invoice_id = info.data.get('invoice_id')
        if invoice_id and v:
            raise ValueError('Payment can only reference an invoice OR an expense, not both')
        if not invoice_id and not v:
            raise ValueError('Payment must reference either an invoice or an expense')
        return v


class PaymentUpdateRequest(BaseModel):
    """Update payment request"""
    payment_method: Optional[str] = Field(None, description="Payment method")
    payment_date: Optional[date] = None
    reference_number: Optional[str] = Field(None, max_length=100)
    bank_name: Optional[str] = Field(None, max_length=255)
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator('payment_method')
    @classmethod
    def validate_payment_method(cls, v):
        if v:
            valid_methods = ['cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other']
            if v not in valid_methods:
                raise ValueError(f'Payment method must be one of: {", ".join(valid_methods)}')
        return v


class PaymentResponse(BaseModel):
    """Payment response with full details"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    organization_id: UUID
    payment_number: str
    payment_type: str
    payment_method: str
    amount: Decimal
    payment_date: date
    invoice_id: Optional[UUID] = None
    expense_id: Optional[UUID] = None
    reference_number: Optional[str] = None
    bank_name: Optional[str] = None
    notes: Optional[str] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime

    # Computed fields
    @property
    def is_received(self) -> bool:
        """Check if this is a received payment"""
        return self.payment_type == 'received'

    @property
    def is_paid(self) -> bool:
        """Check if this is a paid payment"""
        return self.payment_type == 'paid'

    @property
    def formatted_amount(self) -> str:
        """Format amount with currency symbol"""
        return f"₹{self.amount:,.2f}"

    @property
    def method_icon(self) -> str:
        """Get icon for payment method"""
        icons = {
            'cash': '💵',
            'bank_transfer': '🏦',
            'cheque': '📝',
            'upi': '📱',
            'card': '💳',
            'other': '💰'
        }
        return icons.get(self.payment_method, '💰')

    @property
    def type_color(self) -> str:
        """Get color for payment type"""
        return 'green' if self.payment_type == 'received' else 'red'


class PaymentListResponse(BaseModel):
    """Paginated payment list response"""
    total: int
    page: int
    page_size: int
    payments: List[PaymentResponse]


class PaymentMethodSummary(BaseModel):
    """Payment summary by method"""
    method: str
    received: Decimal
    paid: Decimal
    count: int


class PaymentMethodSummaryResponse(BaseModel):
    """Payment summary by method response"""
    by_method: List[PaymentMethodSummary]
    total_received: Decimal
    total_paid: Decimal


class PaymentPeriodSummary(BaseModel):
    """Payment summary by period"""
    period: str
    received: Decimal
    paid: Decimal
    net_flow: Decimal
    count: int


class PaymentPeriodSummaryResponse(BaseModel):
    """Payment summary by period response"""
    by_period: List[PaymentPeriodSummary]
    period_type: str


class PaymentSummaryResponse(BaseModel):
    """Overall payment summary"""
    total_received: Decimal
    total_paid: Decimal
    net_flow: Decimal
    received_count: int
    paid_count: int
    total_count: int
