"""
Budget Schemas
Pydantic models for budget endpoints
"""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


class BudgetCreateRequest(BaseModel):
    """Create new budget request"""
    name: str = Field(..., min_length=2, max_length=255)
    category: str = Field(..., description="Expense category")
    period: str = Field(..., description="Budget period: monthly, quarterly, yearly")
    start_date: date = Field(..., description="Budget start date")
    end_date: date = Field(..., description="Budget end date")
    allocated_amount: Decimal = Field(..., gt=0, description="Allocated budget amount")
    alert_threshold_percent: Decimal = Field(default=Decimal('80'), gt=0, le=100, description="Alert threshold percentage")

    @field_validator('category')
    @classmethod
    def validate_category(cls, v):
        """Validate budget category"""
        valid_categories = ['fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other']
        if v not in valid_categories:
            raise ValueError(f'Category must be one of: {", ".join(valid_categories)}')
        return v

    @field_validator('period')
    @classmethod
    def validate_period(cls, v):
        """Validate budget period"""
        valid_periods = ['monthly', 'quarterly', 'yearly']
        if v not in valid_periods:
            raise ValueError(f'Period must be one of: {", ".join(valid_periods)}')
        return v

    @field_validator('end_date')
    @classmethod
    def validate_end_date(cls, v, info):
        """Validate end date is after start date"""
        start_date = info.data.get('start_date')
        if start_date and v <= start_date:
            raise ValueError('End date must be after start date')
        return v


class BudgetUpdateRequest(BaseModel):
    """Update budget request"""
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    allocated_amount: Optional[Decimal] = Field(None, gt=0)
    alert_threshold_percent: Optional[Decimal] = Field(None, gt=0, le=100)


class BudgetResponse(BaseModel):
    """Budget response with full details"""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    organization_id: UUID
    name: str
    category: str
    period: str
    start_date: date
    end_date: date
    allocated_amount: Decimal
    spent_amount: Decimal
    remaining_amount: Decimal
    alert_threshold_percent: Decimal
    created_by: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime

    # Computed fields
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

    @property
    def is_active(self) -> bool:
        """Check if budget period is currently active"""
        today = date.today()
        return self.start_date <= today <= self.end_date

    @property
    def days_remaining(self) -> int:
        """Calculate days remaining in budget period"""
        return (self.end_date - date.today()).days

    @property
    def daily_burn_rate(self) -> Decimal:
        """Calculate daily burn rate"""
        days_elapsed = (date.today() - self.start_date).days
        if days_elapsed <= 0:
            return Decimal('0')
        return self.spent_amount / Decimal(days_elapsed)


class BudgetListResponse(BaseModel):
    """Paginated budget list response"""
    total: int
    page: int
    page_size: int
    budgets: List[BudgetResponse]


class BudgetUtilizationResponse(BaseModel):
    """Detailed budget utilization information"""
    budget_id: str
    name: str
    category: str
    period: str
    start_date: str
    end_date: str
    allocated_amount: Decimal
    spent_amount: Decimal
    remaining_amount: Decimal
    percentage_spent: Decimal
    is_over_threshold: bool
    is_exceeded: bool
    is_active: bool
    total_days: int
    days_elapsed: int
    days_remaining: int
    daily_burn_rate: Decimal
    projected_total: Decimal
    projected_percentage: Decimal
    expense_count: int
    alert_threshold_percent: Decimal


class BudgetPeriodData(BaseModel):
    """Budget period data for comparison"""
    start_date: str
    end_date: str
    budget_allocated: Optional[Decimal]
    spent_amount: Decimal
    expense_count: int


class BudgetComparisonChange(BaseModel):
    """Budget comparison change data"""
    amount: Decimal
    percentage: Decimal
    trend: str  # 'increase', 'decrease', or 'stable'


class BudgetComparisonResponse(BaseModel):
    """Budget period comparison response"""
    category: str
    period1: BudgetPeriodData
    period2: BudgetPeriodData
    change: BudgetComparisonChange


class BudgetSummaryResponse(BaseModel):
    """Overall budget summary for dashboard"""
    total_budgets: int
    active_budgets: int
    total_allocated: Decimal
    total_spent: Decimal
    total_remaining: Decimal
    overall_percentage: Decimal
    over_threshold_count: int
    exceeded_count: int
