"""
Payment Management API Endpoints
Handles all payment-related operations including CRUD and reports.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.payment_service import PaymentService
from app.schemas.payment import (
    PaymentCreateRequest,
    PaymentUpdateRequest,
    PaymentResponse,
    PaymentListResponse,
    PaymentMethodSummaryResponse,
    PaymentPeriodSummaryResponse,
    PaymentSummaryResponse
)
from app.core.permissions import require_capability, AccessLevel


router = APIRouter()


@router.post(
    "",
    response_model=PaymentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new payment",
    description="Record a new payment (received or paid). Requires payment.record capability."
)
def create_payment(
    payment_data: PaymentCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.record", AccessLevel.FULL))
):
    """
    Create a new payment record.

    Required capability: payment.record (FULL access)
    """
    service = PaymentService(db)
    payment = service.create_payment(
        user_id=str(current_user.id),
        org_id=org_id,
        payment_data=payment_data
    )
    return payment


@router.get(
    "",
    response_model=PaymentListResponse,
    summary="Get list of payments",
    description="Get paginated list of payments with optional filters. Requires payment.view capability."
)
def get_payments(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    payment_type: Optional[str] = Query(None, description="Filter by payment type (received/paid)"),
    payment_method: Optional[str] = Query(None, description="Filter by payment method"),
    from_date: Optional[date] = Query(None, description="Filter payments from this date"),
    to_date: Optional[date] = Query(None, description="Filter payments until this date"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.view", AccessLevel.VIEW))
):
    """
    Get paginated list of payments with filters.

    Required capability: payment.view (VIEW or higher access)
    """
    service = PaymentService(db)
    payments, total = service.get_payments_by_organization(
        org_id=org_id,
        skip=skip,
        limit=limit,
        payment_type=payment_type,
        payment_method=payment_method,
        from_date=from_date,
        to_date=to_date
    )

    page = (skip // limit) + 1 if limit > 0 else 1

    return PaymentListResponse(
        total=total,
        page=page,
        page_size=limit,
        payments=payments
    )


@router.get(
    "/summary",
    response_model=PaymentSummaryResponse,
    summary="Get payment summary",
    description="Get overall payment summary statistics. Requires payment.view capability."
)
def get_payment_summary(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.view", AccessLevel.VIEW))
):
    """
    Get payment summary statistics (received vs paid).

    Required capability: payment.view (VIEW or higher access)
    """
    service = PaymentService(db)
    summary = service.get_payment_summary(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date
    )
    return summary


@router.get(
    "/by-method",
    response_model=PaymentMethodSummaryResponse,
    summary="Get payments by method",
    description="Get payments grouped by payment method. Requires payment.view capability."
)
def get_payments_by_method(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.view", AccessLevel.VIEW))
):
    """
    Get payments grouped by payment method.

    Required capability: payment.view (VIEW or higher access)
    """
    service = PaymentService(db)
    summary = service.get_payments_by_method(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date
    )
    return summary


@router.get(
    "/by-period",
    response_model=PaymentPeriodSummaryResponse,
    summary="Get payments by period",
    description="Get payments grouped by period. Requires payment.view capability."
)
def get_payments_by_period(
    period: str = Query('monthly', description="Period type: monthly, quarterly, yearly"),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.view", AccessLevel.VIEW))
):
    """
    Get payments grouped by period (monthly/quarterly/yearly).

    Required capability: payment.view (VIEW or higher access)
    """
    service = PaymentService(db)
    summary = service.get_payments_by_period(
        org_id=org_id,
        period=period,
        from_date=from_date,
        to_date=to_date
    )
    return summary


@router.get(
    "/{payment_id}",
    response_model=PaymentResponse,
    summary="Get payment by ID",
    description="Get detailed payment information. Requires payment.view capability."
)
def get_payment(
    payment_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.view", AccessLevel.VIEW))
):
    """
    Get payment by ID.

    Required capability: payment.view (VIEW or higher access)
    """
    service = PaymentService(db)
    payment = service.get_payment_by_id(payment_id, org_id)

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )

    return payment


@router.put(
    "/{payment_id}",
    response_model=PaymentResponse,
    summary="Update payment",
    description="Update payment details. Requires payment.record capability."
)
def update_payment(
    payment_id: str,
    payment_data: PaymentUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.record", AccessLevel.FULL))
):
    """
    Update payment (cannot change amount or linked entity).

    Required capability: payment.record (FULL access)
    """
    service = PaymentService(db)
    payment = service.update_payment(
        user_id=str(current_user.id),
        payment_id=payment_id,
        org_id=org_id,
        payment_data=payment_data
    )
    return payment


@router.delete(
    "/{payment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete payment",
    description="Delete payment and reverse linked entity updates. Requires payment.delete capability."
)
def delete_payment(
    payment_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("payment.delete", AccessLevel.FULL))
):
    """
    Delete payment (reverses invoice/expense updates).

    Required capability: payment.delete (FULL access)
    """
    service = PaymentService(db)
    service.delete_payment(
        user_id=str(current_user.id),
        payment_id=payment_id,
        org_id=org_id
    )
