"""
Payment Service
Business logic for payment management
"""

from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, func, extract
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
import uuid

from app.models.payment import Payment
from app.models.invoice import Invoice
from app.models.expense import Expense
from app.models.company import Organization
from app.models.audit_log import AuditLog
from app.schemas.payment import PaymentCreateRequest, PaymentUpdateRequest
from app.utils.constants import (
    AUDIT_ACTION_PAYMENT_CREATED,
    AUDIT_ACTION_PAYMENT_UPDATED,
    AUDIT_ACTION_PAYMENT_DELETED,
    ENTITY_TYPE_PAYMENT
)


class PaymentService:
    """Service for payment operations"""

    def __init__(self, db: Session):
        self.db = db

    def _generate_payment_number(self, org_id: str) -> str:
        """Generate unique payment number for organization"""
        # Get count of payments for organization
        count = self.db.query(Payment).filter(
            Payment.organization_id == org_id
        ).count()

        # Format: PAY-YYYYMM-NNNN
        today = datetime.now()
        return f"PAY-{today.strftime('%Y%m')}-{str(count + 1).zfill(4)}"

    def _validate_payment_reference(
        self,
        invoice_id: Optional[str],
        expense_id: Optional[str]
    ) -> None:
        """
        Validate that payment references exactly one entity (invoice XOR expense).

        Args:
            invoice_id: Invoice ID (optional)
            expense_id: Expense ID (optional)

        Raises:
            HTTPException: If validation fails
        """
        if invoice_id and expense_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment can only reference an invoice OR an expense, not both"
            )

        if not invoice_id and not expense_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment must reference either an invoice or an expense"
            )

    def _update_linked_entity(
        self,
        org_id: str,
        invoice_id: Optional[str],
        expense_id: Optional[str],
        amount: Decimal,
        reverse: bool = False
    ) -> None:
        """
        Update linked invoice or expense when payment is created/deleted.

        Args:
            org_id: Organization ID
            invoice_id: Invoice ID (if linked to invoice)
            expense_id: Expense ID (if linked to expense)
            amount: Payment amount
            reverse: True to reverse the update (on deletion)

        Raises:
            HTTPException: If update fails
        """
        if invoice_id:
            invoice = self.db.query(Invoice).filter(
                Invoice.id == invoice_id,
                Invoice.organization_id == org_id
            ).first()

            if not invoice:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Invoice not found"
                )

            # Update amount paid
            if reverse:
                invoice.amount_paid -= amount
            else:
                invoice.amount_paid += amount

            # Update status based on payment
            if invoice.is_fully_paid:
                invoice.status = 'paid'
            elif invoice.amount_paid > 0:
                invoice.status = 'partially_paid'
            else:
                invoice.status = 'sent'

        elif expense_id:
            expense = self.db.query(Expense).filter(
                Expense.id == expense_id,
                Expense.organization_id == org_id
            ).first()

            if not expense:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Expense not found"
                )

            # Update expense status
            if reverse:
                # Revert to approved status when payment is deleted
                if expense.status == 'paid':
                    expense.status = 'approved'
            else:
                # Mark as paid when payment is created
                if expense.status == 'approved':
                    expense.status = 'paid'
                    expense.paid_at = datetime.now()

    def create_payment(
        self,
        user_id: str,
        org_id: str,
        payment_data: PaymentCreateRequest
    ) -> Payment:
        """
        Create a new payment.

        Args:
            user_id: User creating the payment
            org_id: Organization ID
            payment_data: Validated payment information

        Returns:
            Created payment

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

        # Validate payment reference (invoice XOR expense) - already validated by Pydantic
        self._validate_payment_reference(payment_data.invoice_id, payment_data.expense_id)

        # Generate payment number
        payment_number = self._generate_payment_number(org_id)

        # Create payment
        payment = Payment(
            id=uuid.uuid4(),
            organization_id=org_id,
            payment_number=payment_number,
            payment_type=payment_data.payment_type,
            payment_method=payment_data.payment_method,
            amount=payment_data.amount,
            payment_date=payment_data.payment_date,
            invoice_id=payment_data.invoice_id,
            expense_id=payment_data.expense_id,
            reference_number=payment_data.reference_number,
            bank_name=payment_data.bank_name,
            notes=payment_data.notes,
            created_by=user_id
        )

        self.db.add(payment)

        # Update linked entity (invoice or expense)
        self._update_linked_entity(
            org_id=org_id,
            invoice_id=payment_data.invoice_id,
            expense_id=payment_data.expense_id,
            amount=payment.amount,
            reverse=False
        )

        # Create audit log
        entity_type = "invoice" if payment_data.invoice_id else "expense"
        entity_id = payment_data.invoice_id or payment_data.expense_id
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_PAYMENT_CREATED,
            entity_type=ENTITY_TYPE_PAYMENT,
            entity_id=str(payment.id),
            details=f"Created {payment_data.payment_type} payment {payment_number} for {entity_type} ({payment_data.amount})"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(payment)

        return payment

    def get_payment_by_id(self, payment_id: str, org_id: str) -> Optional[Payment]:
        """Get payment by ID with organization scope"""
        return self.db.query(Payment).options(
            joinedload(Payment.invoice),
            joinedload(Payment.expense)
        ).filter(
            Payment.id == payment_id,
            Payment.organization_id == org_id
        ).first()

    def get_payments_by_organization(
        self,
        org_id: str,
        skip: int = 0,
        limit: int = 100,
        payment_type: Optional[str] = None,
        payment_method: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> tuple[List[Payment], int]:
        """
        Get payments for organization with filters and pagination.

        Returns:
            Tuple of (payments, total_count)
        """
        query = self.db.query(Payment).filter(
            Payment.organization_id == org_id
        )

        # Apply filters
        if payment_type:
            query = query.filter(Payment.payment_type == payment_type)

        if payment_method:
            query = query.filter(Payment.payment_method == payment_method)

        if from_date:
            query = query.filter(Payment.payment_date >= from_date)

        if to_date:
            query = query.filter(Payment.payment_date <= to_date)

        # Get total count
        total = query.count()

        # Get paginated results
        payments = query.options(
            joinedload(Payment.invoice),
            joinedload(Payment.expense)
        ).order_by(
            Payment.payment_date.desc(),
            Payment.created_at.desc()
        ).offset(skip).limit(limit).all()

        return payments, total

    def update_payment(
        self,
        user_id: str,
        payment_id: str,
        org_id: str,
        payment_data: PaymentUpdateRequest
    ) -> Payment:
        """
        Update payment.

        Args:
            user_id: User updating the payment
            payment_id: Payment ID
            org_id: Organization ID
            payment_data: Validated updated payment information

        Returns:
            Updated payment

        Raises:
            HTTPException: If update fails
        """
        payment = self.get_payment_by_id(payment_id, org_id)

        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found"
            )

        # Update fields if provided (using model_dump with exclude_unset)
        update_data = payment_data.model_dump(exclude_unset=True)

        if 'payment_method' in update_data:
            payment.payment_method = payment_data.payment_method

        if 'payment_date' in update_data:
            payment.payment_date = payment_data.payment_date

        if 'reference_number' in update_data:
            payment.reference_number = payment_data.reference_number

        if 'bank_name' in update_data:
            payment.bank_name = payment_data.bank_name

        if 'notes' in update_data:
            payment.notes = payment_data.notes

        # Note: Cannot change amount, type, or linked entity after creation

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_PAYMENT_UPDATED,
            entity_type=ENTITY_TYPE_PAYMENT,
            entity_id=str(payment.id),
            details=f"Updated payment {payment.payment_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(payment)

        return payment

    def delete_payment(self, user_id: str, payment_id: str, org_id: str) -> None:
        """
        Delete payment and reverse linked entity updates.

        Args:
            user_id: User deleting the payment
            payment_id: Payment ID
            org_id: Organization ID

        Raises:
            HTTPException: If deletion fails
        """
        payment = self.get_payment_by_id(payment_id, org_id)

        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found"
            )

        payment_number = payment.payment_number

        # Reverse linked entity updates
        self._update_linked_entity(
            org_id=org_id,
            invoice_id=payment.invoice_id,
            expense_id=payment.expense_id,
            amount=payment.amount,
            reverse=True
        )

        # Delete payment
        self.db.delete(payment)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_PAYMENT_DELETED,
            entity_type=ENTITY_TYPE_PAYMENT,
            entity_id=str(payment_id),
            details=f"Deleted payment {payment_number}"
        )
        self.db.add(audit_log)

        self.db.commit()

    def get_payments_by_method(
        self,
        org_id: str,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get payments grouped by payment method.

        Args:
            org_id: Organization ID
            from_date: Start date filter
            to_date: End date filter

        Returns:
            Payments grouped by method with totals
        """
        query = self.db.query(Payment).filter(
            Payment.organization_id == org_id
        )

        if from_date:
            query = query.filter(Payment.payment_date >= from_date)

        if to_date:
            query = query.filter(Payment.payment_date <= to_date)

        results = query.with_entities(
            Payment.payment_method,
            Payment.payment_type,
            func.sum(Payment.amount).label('total_amount'),
            func.count(Payment.id).label('count')
        ).group_by(Payment.payment_method, Payment.payment_type).all()

        summary = {}
        for r in results:
            if r.payment_method not in summary:
                summary[r.payment_method] = {
                    'method': r.payment_method,
                    'received': Decimal('0'),
                    'paid': Decimal('0'),
                    'count': 0
                }

            if r.payment_type == 'received':
                summary[r.payment_method]['received'] = r.total_amount or Decimal('0')
            elif r.payment_type == 'paid':
                summary[r.payment_method]['paid'] = r.total_amount or Decimal('0')

            summary[r.payment_method]['count'] += r.count

        return {
            'by_method': list(summary.values()),
            'total_received': sum(item['received'] for item in summary.values()),
            'total_paid': sum(item['paid'] for item in summary.values())
        }

    def get_payments_by_period(
        self,
        org_id: str,
        period: str = 'monthly',
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get payments grouped by period (monthly, quarterly, yearly).

        Args:
            org_id: Organization ID
            period: Group by 'monthly', 'quarterly', or 'yearly'
            from_date: Start date filter
            to_date: End date filter

        Returns:
            Payments grouped by period
        """
        query = self.db.query(Payment).filter(
            Payment.organization_id == org_id
        )

        if from_date:
            query = query.filter(Payment.payment_date >= from_date)

        if to_date:
            query = query.filter(Payment.payment_date <= to_date)

        if period == 'monthly':
            date_format = 'YYYY-MM'
        elif period == 'quarterly':
            date_format = 'YYYY-Q'
        else:  # yearly
            date_format = 'YYYY'

        results = query.with_entities(
            func.to_char(Payment.payment_date, date_format).label('period'),
            Payment.payment_type,
            func.sum(Payment.amount).label('total_amount'),
            func.count(Payment.id).label('count')
        ).group_by(
            func.to_char(Payment.payment_date, date_format),
            Payment.payment_type
        ).order_by(
            func.to_char(Payment.payment_date, date_format)
        ).all()

        summary = {}
        for r in results:
            if r.period not in summary:
                summary[r.period] = {
                    'period': r.period,
                    'received': Decimal('0'),
                    'paid': Decimal('0'),
                    'net_flow': Decimal('0'),
                    'count': 0
                }

            if r.payment_type == 'received':
                summary[r.period]['received'] = r.total_amount or Decimal('0')
            elif r.payment_type == 'paid':
                summary[r.period]['paid'] = r.total_amount or Decimal('0')

            summary[r.period]['count'] += r.count

        # Calculate net flow for each period
        for item in summary.values():
            item['net_flow'] = item['received'] - item['paid']

        return {
            'by_period': list(summary.values()),
            'period_type': period
        }

    def get_payment_summary(
        self,
        org_id: str,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get overall payment summary statistics.

        Args:
            org_id: Organization ID
            from_date: Start date filter
            to_date: End date filter

        Returns:
            Summary statistics
        """
        query = self.db.query(Payment).filter(
            Payment.organization_id == org_id
        )

        if from_date:
            query = query.filter(Payment.payment_date >= from_date)

        if to_date:
            query = query.filter(Payment.payment_date <= to_date)

        results = query.with_entities(
            Payment.payment_type,
            func.sum(Payment.amount).label('total_amount'),
            func.count(Payment.id).label('count')
        ).group_by(Payment.payment_type).all()

        total_received = Decimal('0')
        total_paid = Decimal('0')
        received_count = 0
        paid_count = 0

        for r in results:
            if r.payment_type == 'received':
                total_received = r.total_amount or Decimal('0')
                received_count = r.count
            elif r.payment_type == 'paid':
                total_paid = r.total_amount or Decimal('0')
                paid_count = r.count

        return {
            'total_received': total_received,
            'total_paid': total_paid,
            'net_flow': total_received - total_paid,
            'received_count': received_count,
            'paid_count': paid_count,
            'total_count': received_count + paid_count
        }
