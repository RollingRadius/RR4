"""
Budget Management API Endpoints
Handles all budget-related operations including CRUD and monitoring.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import date
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.budget_service import BudgetService
from app.schemas.budget import (
    BudgetCreateRequest,
    BudgetUpdateRequest,
    BudgetResponse,
    BudgetListResponse,
    BudgetUtilizationResponse,
    BudgetComparisonResponse,
    BudgetSummaryResponse
)
from app.core.permissions import require_capability, AccessLevel


router = APIRouter()


@router.post(
    "",
    response_model=BudgetResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new budget",
    description="Create a new budget for a category and period. Requires budget.manage capability."
)
def create_budget(
    budget_data: BudgetCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.manage", AccessLevel.FULL))
):
    """
    Create a new budget.

    Required capability: budget.manage (FULL access)
    """
    service = BudgetService(db)
    budget = service.create_budget(
        user_id=str(current_user.id),
        org_id=org_id,
        budget_data=budget_data
    )
    return budget


@router.get(
    "",
    response_model=BudgetListResponse,
    summary="Get list of budgets",
    description="Get paginated list of budgets with optional filters. Requires budget.view capability."
)
def get_budgets(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    category: Optional[str] = Query(None, description="Filter by category"),
    period: Optional[str] = Query(None, description="Filter by period (monthly/quarterly/yearly)"),
    active_only: bool = Query(False, description="Show only active budgets"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get paginated list of budgets with filters.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    budgets, total = service.get_budgets_by_organization(
        org_id=org_id,
        skip=skip,
        limit=limit,
        category=category,
        period=period,
        active_only=active_only
    )

    page = (skip // limit) + 1 if limit > 0 else 1

    return BudgetListResponse(
        total=total,
        page=page,
        page_size=limit,
        budgets=budgets
    )


@router.get(
    "/summary",
    response_model=BudgetSummaryResponse,
    summary="Get budget summary for dashboard",
    description="Get overall budget summary statistics. Requires budget.view capability."
)
def get_budget_summary(
    active_only: bool = Query(True, description="Show only active budgets"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get budget summary statistics for dashboard.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    summary = service.get_budget_summary(
        org_id=org_id,
        active_only=active_only
    )
    return summary


@router.get(
    "/alerts",
    response_model=List[BudgetResponse],
    summary="Get budget alerts",
    description="Get budgets that are over their alert threshold. Requires budget.view capability."
)
def get_budget_alerts(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get budgets over alert threshold.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    budgets = service.get_budget_alerts(org_id)
    return budgets


@router.get(
    "/active",
    response_model=List[BudgetResponse],
    summary="Get active budgets",
    description="Get all currently active budgets. Requires budget.view capability."
)
def get_active_budgets(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get all active budgets.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    budgets, _ = service.get_budgets_by_organization(
        org_id=org_id,
        skip=0,
        limit=1000,
        active_only=True
    )
    return budgets


@router.get(
    "/compare",
    response_model=BudgetComparisonResponse,
    summary="Compare budget periods",
    description="Compare spending across two periods. Requires budget.view capability."
)
def compare_budget_periods(
    category: str = Query(..., description="Expense category"),
    period1_start: date = Query(..., description="Period 1 start date"),
    period1_end: date = Query(..., description="Period 1 end date"),
    period2_start: date = Query(..., description="Period 2 start date"),
    period2_end: date = Query(..., description="Period 2 end date"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Compare budget spending across two periods.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    comparison = service.compare_budget_periods(
        org_id=org_id,
        category=category,
        period1_start=period1_start,
        period1_end=period1_end,
        period2_start=period2_start,
        period2_end=period2_end
    )
    return comparison


@router.get(
    "/{budget_id}",
    response_model=BudgetResponse,
    summary="Get budget by ID",
    description="Get detailed budget information. Requires budget.view capability."
)
def get_budget(
    budget_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get budget by ID.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    budget = service.get_budget_by_id(budget_id, org_id)

    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found"
        )

    return budget


@router.get(
    "/{budget_id}/utilization",
    response_model=BudgetUtilizationResponse,
    summary="Get budget utilization",
    description="Get detailed budget utilization with projections. Requires budget.view capability."
)
def get_budget_utilization(
    budget_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.view", AccessLevel.VIEW))
):
    """
    Get detailed budget utilization information.

    Required capability: budget.view (VIEW or higher access)
    """
    service = BudgetService(db)
    utilization = service.get_budget_utilization(
        budget_id=budget_id,
        org_id=org_id
    )
    return utilization


@router.put(
    "/{budget_id}",
    response_model=BudgetResponse,
    summary="Update budget",
    description="Update budget details. Requires budget.manage capability."
)
def update_budget(
    budget_id: str,
    budget_data: BudgetUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.manage", AccessLevel.FULL))
):
    """
    Update budget.

    Required capability: budget.manage (FULL access)
    """
    service = BudgetService(db)
    budget = service.update_budget(
        user_id=str(current_user.id),
        budget_id=budget_id,
        org_id=org_id,
        budget_data=budget_data
    )
    return budget


@router.delete(
    "/{budget_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete budget",
    description="Delete budget. Requires budget.manage capability."
)
def delete_budget(
    budget_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("budget.manage", AccessLevel.FULL))
):
    """
    Delete budget.

    Required capability: budget.manage (FULL access)
    """
    service = BudgetService(db)
    service.delete_budget(
        user_id=str(current_user.id),
        budget_id=budget_id,
        org_id=org_id
    )
