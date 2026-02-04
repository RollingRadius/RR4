"""
Expense Management API Endpoints
Handles all expense-related operations including CRUD, workflow, and attachments.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.expense_service import ExpenseService
from app.schemas.expense import (
    ExpenseCreateRequest,
    ExpenseUpdateRequest,
    ExpenseApproveRequest,
    ExpenseResponse,
    ExpenseListResponse,
    ExpenseSummaryResponse
)
from app.core.permissions import require_capability, AccessLevel


router = APIRouter()


@router.post(
    "",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new expense",
    description="Create a new expense in draft status. Requires expense.create capability."
)
def create_expense(
    expense_data: ExpenseCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.create", AccessLevel.FULL))
):
    """
    Create a new expense in draft status.

    Required capability: expense.create (FULL access)
    """
    service = ExpenseService(db)
    expense = service.create_expense(
        user_id=str(current_user.id),
        org_id=org_id,
        expense_data=expense_data
    )
    return expense


@router.get(
    "",
    response_model=ExpenseListResponse,
    summary="Get list of expenses",
    description="Get paginated list of expenses with optional filters. Requires expense.view capability."
)
def get_expenses(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    status: Optional[str] = Query(None, description="Filter by status"),
    category: Optional[str] = Query(None, description="Filter by category"),
    vehicle_id: Optional[str] = Query(None, description="Filter by vehicle"),
    driver_id: Optional[str] = Query(None, description="Filter by driver"),
    from_date: Optional[date] = Query(None, description="Filter expenses from this date"),
    to_date: Optional[date] = Query(None, description="Filter expenses until this date"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    Get paginated list of expenses with filters.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    expenses, total = service.get_expenses_by_organization(
        org_id=org_id,
        skip=skip,
        limit=limit,
        status=status,
        category=category,
        vehicle_id=vehicle_id,
        driver_id=driver_id,
        from_date=from_date,
        to_date=to_date
    )

    page = (skip // limit) + 1 if limit > 0 else 1

    return ExpenseListResponse(
        total=total,
        page=page,
        page_size=limit,
        expenses=expenses
    )


@router.get(
    "/{expense_id}",
    response_model=ExpenseResponse,
    summary="Get expense by ID",
    description="Get detailed expense information. Requires expense.view capability."
)
def get_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    Get expense by ID.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    expense = service.get_expense_by_id(expense_id, org_id)

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )

    return expense


@router.put(
    "/{expense_id}",
    response_model=ExpenseResponse,
    summary="Update expense",
    description="Update expense (only if draft or rejected). Requires expense.edit capability."
)
def update_expense(
    expense_id: str,
    expense_data: ExpenseUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.edit", AccessLevel.FULL))
):
    """
    Update expense (only if in draft or rejected status).

    Required capability: expense.edit (FULL access)
    """
    service = ExpenseService(db)
    expense = service.update_expense(
        user_id=str(current_user.id),
        expense_id=expense_id,
        org_id=org_id,
        expense_data=expense_data
    )
    return expense


@router.delete(
    "/{expense_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete expense",
    description="Delete expense. Requires expense.delete capability."
)
def delete_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.delete", AccessLevel.FULL))
):
    """
    Delete expense.

    Required capability: expense.delete (FULL access)
    """
    service = ExpenseService(db)
    expense = service.get_expense_by_id(expense_id, org_id)

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )

    db.delete(expense)
    db.commit()


@router.post(
    "/{expense_id}/submit",
    response_model=ExpenseResponse,
    summary="Submit expense for approval",
    description="Submit expense for approval. Requires expense.submit capability."
)
def submit_expense(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.submit", AccessLevel.FULL))
):
    """
    Submit expense for approval.

    Required capability: expense.submit (FULL access)
    """
    service = ExpenseService(db)
    expense = service.submit_expense(
        user_id=str(current_user.id),
        expense_id=expense_id,
        org_id=org_id
    )
    return expense


@router.post(
    "/{expense_id}/approve",
    response_model=ExpenseResponse,
    summary="Approve or reject expense",
    description="Approve or reject submitted expense. Requires expense.approve capability."
)
def approve_expense(
    expense_id: str,
    approval_data: ExpenseApproveRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.approve", AccessLevel.FULL))
):
    """
    Approve or reject expense.

    Required capability: expense.approve (FULL access)
    """
    service = ExpenseService(db)
    expense = service.approve_expense(
        user_id=str(current_user.id),
        expense_id=expense_id,
        org_id=org_id,
        approval_data=approval_data
    )
    return expense


@router.post(
    "/{expense_id}/mark-paid",
    response_model=ExpenseResponse,
    summary="Mark expense as paid",
    description="Mark approved expense as paid. Requires expense.approve capability."
)
def mark_expense_paid(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.approve", AccessLevel.FULL))
):
    """
    Mark expense as paid.

    Required capability: expense.approve (FULL access)
    """
    service = ExpenseService(db)
    expense = service.mark_expense_paid(
        user_id=str(current_user.id),
        expense_id=expense_id,
        org_id=org_id
    )
    return expense


@router.post(
    "/{expense_id}/attachments",
    status_code=status.HTTP_201_CREATED,
    summary="Upload expense attachment",
    description="Upload attachment for expense. Requires expense.edit capability."
)
def upload_attachment(
    expense_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.edit", AccessLevel.FULL))
):
    """
    Upload attachment for expense.

    Required capability: expense.edit (FULL access)
    """
    # TODO: Implement file upload logic with storage service
    # For now, return placeholder
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="File upload functionality not yet implemented"
    )


@router.get(
    "/{expense_id}/attachments",
    summary="List expense attachments",
    description="List all attachments for expense. Requires expense.view capability."
)
def list_attachments(
    expense_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    List all attachments for expense.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    expense = service.get_expense_by_id(expense_id, org_id)

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )

    return {"attachments": expense.attachments}


@router.delete(
    "/{expense_id}/attachments/{attachment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete expense attachment",
    description="Delete attachment. Requires expense.edit capability."
)
def delete_attachment(
    expense_id: str,
    attachment_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.edit", AccessLevel.FULL))
):
    """
    Delete attachment.

    Required capability: expense.edit (FULL access)
    """
    # TODO: Implement attachment deletion with storage service
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="File deletion functionality not yet implemented"
    )


@router.get(
    "/summary/by-category",
    response_model=ExpenseSummaryResponse,
    summary="Get expense summary by category",
    description="Get expense summary grouped by category. Requires expense.view capability."
)
def get_summary_by_category(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    Get expense summary grouped by category.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    summary = service.get_expense_summary(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date,
        group_by='category'
    )
    return summary


@router.get(
    "/summary/by-vehicle",
    response_model=ExpenseSummaryResponse,
    summary="Get expense summary by vehicle",
    description="Get expense summary grouped by vehicle. Requires expense.view capability."
)
def get_summary_by_vehicle(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    Get expense summary grouped by vehicle.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    summary = service.get_expense_summary(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date,
        group_by='vehicle'
    )
    return summary


@router.get(
    "/summary/by-month",
    response_model=ExpenseSummaryResponse,
    summary="Get expense summary by month",
    description="Get expense summary grouped by month. Requires expense.view capability."
)
def get_summary_by_month(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("expense.view", AccessLevel.VIEW))
):
    """
    Get expense summary grouped by month.

    Required capability: expense.view (VIEW or higher access)
    """
    service = ExpenseService(db)
    summary = service.get_expense_summary(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date,
        group_by='month'
    )
    return summary
