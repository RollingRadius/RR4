"""
Invoice Management API Endpoints
Handles all invoice-related operations including CRUD, line items, and actions.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import date
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.invoice_service import InvoiceService
from app.schemas.invoice import (
    InvoiceCreateRequest,
    InvoiceUpdateRequest,
    InvoiceLineItemRequest,
    InvoiceSendRequest,
    InvoiceRecordPaymentRequest,
    InvoiceResponse,
    InvoiceListResponse,
    InvoiceSummaryResponse
)
from app.core.permissions import require_capability, AccessLevel


router = APIRouter()


@router.post(
    "",
    response_model=InvoiceResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new invoice",
    description="Create a new invoice in draft status. Requires invoice.create capability."
)
def create_invoice(
    invoice_data: InvoiceCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.create", AccessLevel.FULL))
):
    """
    Create a new invoice in draft status with optional line items.

    Required capability: invoice.create (FULL access)
    """
    service = InvoiceService(db)

    # Create invoice with line items
    invoice = service.create_invoice(
        user_id=str(current_user.id),
        org_id=org_id,
        invoice_data=invoice_data
    )

    # Add line items
    for item_data in invoice_data.line_items:
        service.add_line_item(
            user_id=str(current_user.id),
            invoice_id=str(invoice.id),
            org_id=org_id,
            line_item_data=item_data
        )

    # Refresh to get line items
    db.refresh(invoice)

    return invoice


@router.get(
    "",
    response_model=InvoiceListResponse,
    summary="Get list of invoices",
    description="Get paginated list of invoices with optional filters. Requires invoice.view capability."
)
def get_invoices(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    status: Optional[str] = Query(None, description="Filter by status"),
    customer_name: Optional[str] = Query(None, description="Filter by customer name"),
    from_date: Optional[date] = Query(None, description="Filter invoices from this date"),
    to_date: Optional[date] = Query(None, description="Filter invoices until this date"),
    overdue_only: bool = Query(False, description="Show only overdue invoices"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.view", AccessLevel.VIEW))
):
    """
    Get paginated list of invoices with filters.

    Required capability: invoice.view (VIEW or higher access)
    """
    service = InvoiceService(db)
    invoices, total = service.get_invoices_by_organization(
        org_id=org_id,
        skip=skip,
        limit=limit,
        status=status,
        customer_name=customer_name,
        from_date=from_date,
        to_date=to_date,
        overdue_only=overdue_only
    )

    page = (skip // limit) + 1 if limit > 0 else 1

    return InvoiceListResponse(
        total=total,
        page=page,
        page_size=limit,
        invoices=invoices
    )


@router.get(
    "/overdue",
    response_model=List[InvoiceResponse],
    summary="Get overdue invoices",
    description="Get all overdue invoices. Requires invoice.view capability."
)
def get_overdue_invoices(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.view", AccessLevel.VIEW))
):
    """
    Get all overdue invoices.

    Required capability: invoice.view (VIEW or higher access)
    """
    service = InvoiceService(db)
    invoices = service.get_overdue_invoices(org_id)
    return invoices


@router.get(
    "/summary",
    response_model=InvoiceSummaryResponse,
    summary="Get invoice summary statistics",
    description="Get invoice summary statistics. Requires invoice.view capability."
)
def get_invoice_summary(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.view", AccessLevel.VIEW))
):
    """
    Get invoice summary statistics.

    Required capability: invoice.view (VIEW or higher access)
    """
    service = InvoiceService(db)
    summary = service.get_invoice_summary(
        org_id=org_id,
        from_date=from_date,
        to_date=to_date
    )
    return summary


@router.get(
    "/{invoice_id}",
    response_model=InvoiceResponse,
    summary="Get invoice by ID",
    description="Get detailed invoice information. Requires invoice.view capability."
)
def get_invoice(
    invoice_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.view", AccessLevel.VIEW))
):
    """
    Get invoice by ID with line items.

    Required capability: invoice.view (VIEW or higher access)
    """
    service = InvoiceService(db)
    invoice = service.get_invoice_by_id(invoice_id, org_id)

    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )

    return invoice


@router.put(
    "/{invoice_id}",
    response_model=InvoiceResponse,
    summary="Update invoice",
    description="Update invoice (only if draft). Requires invoice.edit capability."
)
def update_invoice(
    invoice_id: str,
    invoice_data: InvoiceUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.edit", AccessLevel.FULL))
):
    """
    Update invoice (only if in draft status).

    Required capability: invoice.edit (FULL access)
    """
    service = InvoiceService(db)
    invoice = service.update_invoice(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id,
        invoice_data=invoice_data
    )
    return invoice


@router.delete(
    "/{invoice_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete invoice",
    description="Delete invoice (only if draft). Requires invoice.delete capability."
)
def delete_invoice(
    invoice_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.delete", AccessLevel.FULL))
):
    """
    Delete invoice (only if in draft status).

    Required capability: invoice.delete (FULL access)
    """
    service = InvoiceService(db)
    service.delete_invoice(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id
    )


@router.post(
    "/{invoice_id}/line-items",
    status_code=status.HTTP_201_CREATED,
    summary="Add line item to invoice",
    description="Add line item to draft invoice. Requires invoice.edit capability."
)
def add_line_item(
    invoice_id: str,
    line_item_data: InvoiceLineItemRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.edit", AccessLevel.FULL))
):
    """
    Add line item to invoice.

    Required capability: invoice.edit (FULL access)
    """
    service = InvoiceService(db)
    line_item = service.add_line_item(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id,
        line_item_data=line_item_data
    )
    return line_item


@router.put(
    "/{invoice_id}/line-items/{line_item_id}",
    summary="Update line item",
    description="Update line item in draft invoice. Requires invoice.edit capability."
)
def update_line_item(
    invoice_id: str,
    line_item_id: str,
    line_item_data: InvoiceLineItemRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.edit", AccessLevel.FULL))
):
    """
    Update line item.

    Required capability: invoice.edit (FULL access)
    """
    service = InvoiceService(db)
    line_item = service.update_line_item(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        line_item_id=line_item_id,
        org_id=org_id,
        line_item_data=line_item_data
    )
    return line_item


@router.delete(
    "/{invoice_id}/line-items/{line_item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete line item",
    description="Delete line item from draft invoice. Requires invoice.edit capability."
)
def delete_line_item(
    invoice_id: str,
    line_item_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.edit", AccessLevel.FULL))
):
    """
    Delete line item.

    Required capability: invoice.edit (FULL access)
    """
    service = InvoiceService(db)
    service.delete_line_item(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        line_item_id=line_item_id,
        org_id=org_id
    )


@router.post(
    "/{invoice_id}/send",
    response_model=InvoiceResponse,
    summary="Send invoice to customer",
    description="Mark invoice as sent. Requires invoice.send capability."
)
def send_invoice(
    invoice_id: str,
    send_data: InvoiceSendRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.send", AccessLevel.FULL))
):
    """
    Send invoice to customer.

    Required capability: invoice.send (FULL access)
    """
    service = InvoiceService(db)
    invoice = service.send_invoice(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id,
        recipient_email=send_data.recipient_email,
        cc_emails=send_data.cc_emails,
        custom_message=send_data.custom_message
    )
    return invoice


@router.post(
    "/{invoice_id}/record-payment",
    response_model=InvoiceResponse,
    summary="Record payment for invoice",
    description="Record payment received for invoice. Requires invoice.edit capability."
)
def record_payment(
    invoice_id: str,
    payment_data: InvoiceRecordPaymentRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.edit", AccessLevel.FULL))
):
    """
    Record payment for invoice.

    Required capability: invoice.edit (FULL access)
    """
    service = InvoiceService(db)
    invoice = service.record_payment(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id,
        amount=payment_data.amount,
        payment_date=payment_data.payment_date,
        payment_method=payment_data.payment_method,
        reference_number=payment_data.reference_number
    )
    return invoice


@router.post(
    "/{invoice_id}/cancel",
    response_model=InvoiceResponse,
    summary="Cancel invoice",
    description="Cancel invoice. Requires invoice.delete capability."
)
def cancel_invoice(
    invoice_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("invoice.delete", AccessLevel.FULL))
):
    """
    Cancel invoice.

    Required capability: invoice.delete (FULL access)
    """
    service = InvoiceService(db)
    invoice = service.cancel_invoice(
        user_id=str(current_user.id),
        invoice_id=invoice_id,
        org_id=org_id
    )
    return invoice
