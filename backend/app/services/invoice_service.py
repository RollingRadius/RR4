"""
Invoice Service
Business logic for invoice management
"""

from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, func
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
import uuid

from app.models.invoice import Invoice, InvoiceLineItem
from app.models.company import Organization
from app.models.vehicle import Vehicle
from app.models.user import User
from app.models.audit_log import AuditLog
from app.schemas.invoice import (
    InvoiceCreateRequest,
    InvoiceUpdateRequest,
    InvoiceLineItemRequest
)
from app.utils.constants import (
    AUDIT_ACTION_INVOICE_CREATED,
    AUDIT_ACTION_INVOICE_UPDATED,
    AUDIT_ACTION_INVOICE_SENT,
    AUDIT_ACTION_INVOICE_PAYMENT_RECORDED,
    AUDIT_ACTION_INVOICE_CANCELLED,
    ENTITY_TYPE_INVOICE
)


class InvoiceService:
    """Service for invoice operations"""

    def __init__(self, db: Session):
        self.db = db

    def _generate_invoice_number(self, org_id: str) -> str:
        """Generate unique invoice number for organization"""
        # Get count of invoices for organization
        count = self.db.query(Invoice).filter(
            Invoice.organization_id == org_id
        ).count()

        # Format: INV-YYYYMM-NNNN
        today = datetime.now()
        return f"INV-{today.strftime('%Y%m')}-{str(count + 1).zfill(4)}"

    def create_invoice(
        self,
        user_id: str,
        org_id: str,
        invoice_data: InvoiceCreateRequest
    ) -> Invoice:
        """
        Create a new invoice in draft status.

        Args:
            user_id: User creating the invoice
            org_id: Organization ID
            invoice_data: Validated invoice information

        Returns:
            Created invoice

        Raises:
            HTTPException: If creation fails
        """
        # Validate organization exists
        organization = self.db.query(Organization).filter(
            Organization.id == org_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Calculate subtotal from line items
        subtotal = sum(
            item.quantity * item.unit_price
            for item in invoice_data.line_items
        )
        total_amount = subtotal + invoice_data.tax_amount

        # Generate invoice number
        invoice_number = self._generate_invoice_number(org_id)

        # Create invoice
        invoice = Invoice(
            id=uuid.uuid4(),
            organization_id=org_id,
            invoice_number=invoice_number,
            customer_name=invoice_data.customer_name,
            customer_email=invoice_data.customer_email,
            customer_phone=invoice_data.customer_phone,
            customer_address=invoice_data.customer_address,
            customer_gstin=invoice_data.customer_gstin,
            invoice_date=invoice_data.invoice_date,
            due_date=invoice_data.due_date,
            subtotal=subtotal,
            tax_amount=invoice_data.tax_amount,
            total_amount=total_amount,
            amount_paid=Decimal('0'),
            status='draft',
            notes=invoice_data.notes,
            terms_and_conditions=invoice_data.terms_and_conditions,
            created_by=user_id
        )

        self.db.add(invoice)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_INVOICE_CREATED,
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice.id),
            details=f"Created invoice {invoice_number} for {invoice_data.customer_name}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(invoice)

        return invoice

    def get_invoice_by_id(self, invoice_id: str, org_id: str) -> Optional[Invoice]:
        """Get invoice by ID with organization scope"""
        return self.db.query(Invoice).options(
            joinedload(Invoice.line_items)
        ).filter(
            Invoice.id == invoice_id,
            Invoice.organization_id == org_id
        ).first()

    def get_invoices_by_organization(
        self,
        org_id: str,
        skip: int = 0,
        limit: int = 100,
        status: Optional[str] = None,
        customer_name: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        overdue_only: bool = False
    ) -> tuple[List[Invoice], int]:
        """
        Get invoices for organization with filters and pagination.

        Returns:
            Tuple of (invoices, total_count)
        """
        query = self.db.query(Invoice).filter(
            Invoice.organization_id == org_id
        )

        # Apply filters
        if status:
            query = query.filter(Invoice.status == status)

        if customer_name:
            query = query.filter(Invoice.customer_name.ilike(f"%{customer_name}%"))

        if from_date:
            query = query.filter(Invoice.invoice_date >= from_date)

        if to_date:
            query = query.filter(Invoice.invoice_date <= to_date)

        if overdue_only:
            today = date.today()
            query = query.filter(
                Invoice.status.in_(['sent', 'partially_paid']),
                Invoice.due_date < today
            )

        # Get total count
        total = query.count()

        # Get paginated results
        invoices = query.options(
            joinedload(Invoice.line_items)
        ).order_by(
            Invoice.invoice_date.desc(),
            Invoice.created_at.desc()
        ).offset(skip).limit(limit).all()

        return invoices, total

    def update_invoice(
        self,
        user_id: str,
        invoice_id: str,
        org_id: str,
        invoice_data: InvoiceUpdateRequest
    ) -> Invoice:
        """
        Update invoice (only if in draft status).

        Args:
            user_id: User updating the invoice
            invoice_id: Invoice ID
            org_id: Organization ID
            invoice_data: Validated updated invoice information

        Returns:
            Updated invoice

        Raises:
            HTTPException: If update fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status != 'draft':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot edit invoice in {invoice.status} status"
            )

        # Update fields if provided (using model_dump with exclude_unset)
        update_data = invoice_data.model_dump(exclude_unset=True)

        if 'customer_name' in update_data:
            invoice.customer_name = invoice_data.customer_name

        if 'customer_email' in update_data:
            invoice.customer_email = invoice_data.customer_email

        if 'customer_phone' in update_data:
            invoice.customer_phone = invoice_data.customer_phone

        if 'customer_address' in update_data:
            invoice.customer_address = invoice_data.customer_address

        if 'customer_gstin' in update_data:
            invoice.customer_gstin = invoice_data.customer_gstin

        if 'invoice_date' in update_data:
            invoice.invoice_date = invoice_data.invoice_date

        if 'due_date' in update_data:
            invoice.due_date = invoice_data.due_date

        if 'tax_amount' in update_data:
            invoice.tax_amount = invoice_data.tax_amount

        if 'notes' in update_data:
            invoice.notes = invoice_data.notes

        if 'terms_and_conditions' in update_data:
            invoice.terms_and_conditions = invoice_data.terms_and_conditions

        # Recalculate totals
        self._recalculate_invoice_totals(invoice)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_INVOICE_UPDATED,
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice.id),
            details=f"Updated invoice {invoice.invoice_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(invoice)

        return invoice

    def delete_invoice(self, user_id: str, invoice_id: str, org_id: str) -> None:
        """
        Delete invoice (only if in draft status).

        Args:
            user_id: User deleting the invoice
            invoice_id: Invoice ID
            org_id: Organization ID

        Raises:
            HTTPException: If deletion fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status != 'draft':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete invoice in {invoice.status} status"
            )

        invoice_number = invoice.invoice_number

        # Delete invoice (line items will cascade)
        self.db.delete(invoice)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action="invoice_deleted",
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice_id),
            details=f"Deleted invoice {invoice_number}"
        )
        self.db.add(audit_log)

        self.db.commit()

    def add_line_item(
        self,
        user_id: str,
        invoice_id: str,
        org_id: str,
        line_item_data: InvoiceLineItemRequest
    ) -> InvoiceLineItem:
        """
        Add line item to invoice.

        Args:
            user_id: User adding the line item
            invoice_id: Invoice ID
            org_id: Organization ID
            line_item_data: Validated line item information

        Returns:
            Created line item

        Raises:
            HTTPException: If addition fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status != 'draft':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot add line items to invoice in {invoice.status} status"
            )

        # Validate vehicle if provided
        if line_item_data.vehicle_id:
            vehicle = self.db.query(Vehicle).filter(
                Vehicle.id == line_item_data.vehicle_id,
                Vehicle.organization_id == org_id
            ).first()

            if not vehicle:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Vehicle not found in your organization"
                )

        # Calculate amount
        amount = line_item_data.quantity * line_item_data.unit_price

        # Create line item
        line_item = InvoiceLineItem(
            id=uuid.uuid4(),
            invoice_id=invoice_id,
            description=line_item_data.description,
            quantity=line_item_data.quantity,
            unit_price=line_item_data.unit_price,
            amount=amount,
            vehicle_id=line_item_data.vehicle_id
        )

        self.db.add(line_item)

        # Recalculate invoice totals
        self._recalculate_invoice_totals(invoice)

        self.db.commit()
        self.db.refresh(line_item)

        return line_item

    def update_line_item(
        self,
        user_id: str,
        invoice_id: str,
        line_item_id: str,
        org_id: str,
        line_item_data: InvoiceLineItemRequest
    ) -> InvoiceLineItem:
        """
        Update line item.

        Args:
            user_id: User updating the line item
            invoice_id: Invoice ID
            line_item_id: Line item ID
            org_id: Organization ID
            line_item_data: Validated updated line item information

        Returns:
            Updated line item

        Raises:
            HTTPException: If update fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status != 'draft':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot update line items for invoice in {invoice.status} status"
            )

        line_item = self.db.query(InvoiceLineItem).filter(
            InvoiceLineItem.id == line_item_id,
            InvoiceLineItem.invoice_id == invoice_id
        ).first()

        if not line_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Line item not found"
            )

        # Update fields
        line_item.description = line_item_data.description
        line_item.quantity = line_item_data.quantity
        line_item.unit_price = line_item_data.unit_price
        line_item.vehicle_id = line_item_data.vehicle_id

        # Recalculate amount
        line_item.amount = line_item.quantity * line_item.unit_price

        # Recalculate invoice totals
        self._recalculate_invoice_totals(invoice)

        self.db.commit()
        self.db.refresh(line_item)

        return line_item

    def delete_line_item(
        self,
        user_id: str,
        invoice_id: str,
        line_item_id: str,
        org_id: str
    ) -> None:
        """
        Delete line item.

        Args:
            user_id: User deleting the line item
            invoice_id: Invoice ID
            line_item_id: Line item ID
            org_id: Organization ID

        Raises:
            HTTPException: If deletion fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status != 'draft':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete line items from invoice in {invoice.status} status"
            )

        line_item = self.db.query(InvoiceLineItem).filter(
            InvoiceLineItem.id == line_item_id,
            InvoiceLineItem.invoice_id == invoice_id
        ).first()

        if not line_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Line item not found"
            )

        self.db.delete(line_item)

        # Recalculate invoice totals
        self._recalculate_invoice_totals(invoice)

        self.db.commit()

    def _recalculate_invoice_totals(self, invoice: Invoice) -> None:
        """Recalculate invoice subtotal and total based on line items"""
        # Sum all line items
        line_items = self.db.query(InvoiceLineItem).filter(
            InvoiceLineItem.invoice_id == invoice.id
        ).all()

        subtotal = sum(item.amount for item in line_items)
        invoice.subtotal = subtotal
        invoice.total_amount = subtotal + invoice.tax_amount

    def send_invoice(
        self,
        user_id: str,
        invoice_id: str,
        org_id: str,
        recipient_email: Optional[str] = None,
        cc_emails: Optional[List[str]] = None,
        custom_message: Optional[str] = None
    ) -> Invoice:
        """
        Mark invoice as sent.

        Args:
            user_id: User sending the invoice
            invoice_id: Invoice ID
            org_id: Organization ID
            recipient_email: Optional recipient email (defaults to customer email)
            cc_emails: Optional CC emails
            custom_message: Optional custom message

        Returns:
            Updated invoice

        Raises:
            HTTPException: If sending fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if not invoice.can_send():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot send invoice in {invoice.status} status"
            )

        invoice.status = 'sent'
        invoice.sent_at = datetime.now()
        invoice.sent_by = user_id

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_INVOICE_SENT,
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice.id),
            details=f"Sent invoice {invoice.invoice_number} to {recipient_email or invoice.customer_email}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(invoice)

        return invoice

    def record_payment(
        self,
        user_id: str,
        invoice_id: str,
        org_id: str,
        amount: Decimal,
        payment_date: date,
        payment_method: str,
        reference_number: Optional[str] = None
    ) -> Invoice:
        """
        Record payment for invoice.

        Args:
            user_id: User recording the payment
            invoice_id: Invoice ID
            org_id: Organization ID
            amount: Payment amount
            payment_date: Payment date
            payment_method: Payment method
            reference_number: Optional reference number

        Returns:
            Updated invoice

        Raises:
            HTTPException: If recording fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if not invoice.can_record_payment():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot record payment for invoice in {invoice.status} status"
            )

        # Update amount paid
        invoice.amount_paid += amount

        # Update status based on payment
        if invoice.is_fully_paid:
            invoice.status = 'paid'
        elif invoice.amount_paid > 0:
            invoice.status = 'partially_paid'

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_INVOICE_PAYMENT_RECORDED,
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice.id),
            details=f"Recorded payment of {amount} for invoice {invoice.invoice_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(invoice)

        return invoice

    def cancel_invoice(self, user_id: str, invoice_id: str, org_id: str) -> Invoice:
        """
        Cancel invoice.

        Args:
            user_id: User cancelling the invoice
            invoice_id: Invoice ID
            org_id: Organization ID

        Returns:
            Updated invoice

        Raises:
            HTTPException: If cancellation fails
        """
        invoice = self.get_invoice_by_id(invoice_id, org_id)

        if not invoice:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invoice not found"
            )

        if invoice.status in ['cancelled', 'paid']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel invoice in {invoice.status} status"
            )

        invoice.status = 'cancelled'

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_INVOICE_CANCELLED,
            entity_type=ENTITY_TYPE_INVOICE,
            entity_id=str(invoice.id),
            details=f"Cancelled invoice {invoice.invoice_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(invoice)

        return invoice

    def get_overdue_invoices(self, org_id: str) -> List[Invoice]:
        """
        Get all overdue invoices for organization.

        Args:
            org_id: Organization ID

        Returns:
            List of overdue invoices
        """
        today = date.today()
        invoices = self.db.query(Invoice).filter(
            Invoice.organization_id == org_id,
            Invoice.status.in_(['sent', 'partially_paid']),
            Invoice.due_date < today
        ).all()

        # Update status to overdue if needed
        for invoice in invoices:
            if invoice.status != 'overdue':
                invoice.status = 'overdue'

        if invoices:
            self.db.commit()

        return invoices

    def _check_overdue_status(self, invoice: Invoice) -> None:
        """Check and update invoice status if overdue"""
        if invoice.is_overdue and invoice.status != 'overdue':
            invoice.status = 'overdue'

    def get_invoice_summary(
        self,
        org_id: str,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get invoice summary statistics.

        Args:
            org_id: Organization ID
            from_date: Start date filter
            to_date: End date filter

        Returns:
            Summary statistics
        """
        query = self.db.query(Invoice).filter(
            Invoice.organization_id == org_id
        )

        if from_date:
            query = query.filter(Invoice.invoice_date >= from_date)

        if to_date:
            query = query.filter(Invoice.invoice_date <= to_date)

        invoices = query.all()

        total_invoices = len(invoices)
        total_amount = sum(inv.total_amount for inv in invoices)
        total_paid = sum(inv.amount_paid for inv in invoices)
        total_due = total_amount - total_paid

        # Count by status
        draft_count = len([inv for inv in invoices if inv.status == 'draft'])
        sent_count = len([inv for inv in invoices if inv.status == 'sent'])
        partially_paid_count = len([inv for inv in invoices if inv.status == 'partially_paid'])
        paid_count = len([inv for inv in invoices if inv.status == 'paid'])
        overdue_count = len([inv for inv in invoices if inv.is_overdue])
        cancelled_count = len([inv for inv in invoices if inv.status == 'cancelled'])

        return {
            'total_invoices': total_invoices,
            'total_amount': total_amount,
            'total_paid': total_paid,
            'total_due': total_due,
            'draft_count': draft_count,
            'sent_count': sent_count,
            'partially_paid_count': partially_paid_count,
            'paid_count': paid_count,
            'overdue_count': overdue_count,
            'cancelled_count': cancelled_count
        }
