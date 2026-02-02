"""
Expense Schemas
Pydantic models for expense endpoints
"""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


class ExpenseAttachmentResponse(BaseModel):
    """Expense attachment response"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    file_name: str
    file_path: str
    file_size: Decimal
    file_type: Optional[str] = None
    uploaded_by: Optional[UUID] = None
    uploaded_at: datetime


class ExpenseCreateRequest(BaseModel):
    """Create new expense request"""
    category: str = Field(..., description="Expense category")
    description: str = Field(..., min_length=3, max_length=1000)
    amount: Decimal = Field(..., ge=0, description="Expense amount (excluding tax)")
    tax_amount: Decimal = Field(default=Decimal('0'), ge=0, description="Tax amount")
    expense_date: date
    vehicle_id: Optional[UUID] = Field(None, description="Related vehicle")
    driver_id: Optional[UUID] = Field(None, description="Related driver")
    vendor_id: Optional[UUID] = Field(None, description="Related vendor")
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator('category')
    @classmethod
    def validate_category(cls, v):
        """Validate expense category"""
        valid_categories = ['fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other']
        if v not in valid_categories:
            raise ValueError(f'Category must be one of: {", ".join(valid_categories)}')
        return v

    @field_validator('expense_date')
    @classmethod
    def validate_expense_date(cls, v):
        """Validate expense date is not in future"""
        if v > date.today():
            raise ValueError('Expense date cannot be in the future')
        return v


class ExpenseUpdateRequest(BaseModel):
    """Update expense request (only for draft/rejected status)"""
    category: Optional[str] = None
    description: Optional[str] = Field(None, min_length=3, max_length=1000)
    amount: Optional[Decimal] = Field(None, ge=0)
    tax_amount: Optional[Decimal] = Field(None, ge=0)
    expense_date: Optional[date] = None
    vehicle_id: Optional[UUID] = None
    driver_id: Optional[UUID] = None
    vendor_id: Optional[UUID] = None
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator('category')
    @classmethod
    def validate_category(cls, v):
        if v:
            valid_categories = ['fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other']
            if v not in valid_categories:
                raise ValueError(f'Category must be one of: {", ".join(valid_categories)}')
        return v

    @field_validator('expense_date')
    @classmethod
    def validate_expense_date(cls, v):
        if v and v > date.today():
            raise ValueError('Expense date cannot be in the future')
        return v


class ExpenseApproveRequest(BaseModel):
    """Approve or reject expense request"""
    approved: bool = Field(..., description="True to approve, False to reject")
    rejection_reason: Optional[str] = Field(None, max_length=500, description="Required if rejected")

    @field_validator('rejection_reason')
    @classmethod
    def validate_rejection_reason(cls, v, info):
        """Require rejection reason if not approved"""
        approved = info.data.get('approved')
        if not approved and not v:
            raise ValueError('Rejection reason is required when rejecting an expense')
        return v


class ExpenseResponse(BaseModel):
    """Expense response with full details"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    organization_id: UUID
    expense_number: str
    category: str
    description: str
    amount: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    expense_date: date
    vehicle_id: Optional[UUID] = None
    driver_id: Optional[UUID] = None
    vendor_id: Optional[UUID] = None
    status: str
    submitted_at: Optional[datetime] = None
    submitted_by: Optional[UUID] = None
    approved_at: Optional[datetime] = None
    approved_by: Optional[UUID] = None
    rejection_reason: Optional[str] = None
    paid_at: Optional[datetime] = None
    notes: Optional[str] = None
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
    attachments: List[ExpenseAttachmentResponse] = []


class ExpenseListResponse(BaseModel):
    """Paginated expense list response"""
    total: int
    page: int
    page_size: int
    expenses: List[ExpenseResponse]


class ExpenseSummaryItem(BaseModel):
    """Expense summary item"""
    category: Optional[str] = None
    vehicle_id: Optional[UUID] = None
    month: Optional[str] = None
    total_amount: Decimal
    count: int


class ExpenseSummaryResponse(BaseModel):
    """Expense summary response"""
    summary: List[ExpenseSummaryItem]
    grand_total: Decimal
    total_count: int
