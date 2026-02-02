"""
Expense Service
Business logic for expense management
"""

from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, func, extract
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
import uuid

from app.models.expense import Expense, ExpenseAttachment
from app.models.company import Organization
from app.models.vehicle import Vehicle
from app.models.driver import Driver
from app.models.vendor import Vendor
from app.models.budget import Budget
from app.models.audit_log import AuditLog
from app.utils.constants import (
    AUDIT_ACTION_EXPENSE_CREATED,
    AUDIT_ACTION_EXPENSE_UPDATED,
    AUDIT_ACTION_EXPENSE_SUBMITTED,
    AUDIT_ACTION_EXPENSE_APPROVED,
    AUDIT_ACTION_EXPENSE_REJECTED,
    AUDIT_ACTION_EXPENSE_PAID,
    AUDIT_ACTION_EXPENSE_ATTACHMENT_UPLOADED,
    ENTITY_TYPE_EXPENSE,
    EXPENSE_STATUSES
)


class ExpenseService:
    """Service for expense operations"""

    def __init__(self, db: Session):
        self.db = db

    def _generate_expense_number(self, org_id: str) -> str:
        """Generate unique expense number for organization"""
        # Get count of expenses for organization
        count = self.db.query(Expense).filter(
            Expense.organization_id == org_id
        ).count()

        # Format: EXP-YYYYMM-NNNN
        today = datetime.now()
        return f"EXP-{today.strftime('%Y%m')}-{str(count + 1).zfill(4)}"

    def create_expense(
        self,
        user_id: str,
        org_id: str,
        expense_data: Dict[str, Any]
    ) -> Expense:
        """
        Create a new expense in draft status.

        Args:
            user_id: User creating the expense
            org_id: Organization ID
            expense_data: Expense information

        Returns:
            Created expense

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

        # Validate vehicle if provided
        if expense_data.get('vehicle_id'):
            vehicle = self.db.query(Vehicle).filter(
                Vehicle.id == expense_data['vehicle_id'],
                Vehicle.organization_id == org_id
            ).first()

            if not vehicle:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Vehicle not found in your organization"
                )

        # Validate driver if provided
        if expense_data.get('driver_id'):
            driver = self.db.query(Driver).filter(
                Driver.id == expense_data['driver_id'],
                Driver.organization_id == org_id
            ).first()

            if not driver:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Driver not found in your organization"
                )

        # Validate vendor if provided
        if expense_data.get('vendor_id'):
            vendor = self.db.query(Vendor).filter(
                Vendor.id == expense_data['vendor_id'],
                Vendor.organization_id == org_id
            ).first()

            if not vendor:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Vendor not found in your organization"
                )

        # Calculate total amount
        amount = expense_data['amount']
        tax_amount = expense_data.get('tax_amount', Decimal('0'))
        total_amount = amount + tax_amount

        # Generate expense number
        expense_number = self._generate_expense_number(org_id)

        # Create expense
        expense = Expense(
            id=uuid.uuid4(),
            organization_id=org_id,
            expense_number=expense_number,
            category=expense_data['category'],
            description=expense_data['description'],
            amount=amount,
            tax_amount=tax_amount,
            total_amount=total_amount,
            expense_date=expense_data['expense_date'],
            vehicle_id=expense_data.get('vehicle_id'),
            driver_id=expense_data.get('driver_id'),
            vendor_id=expense_data.get('vendor_id'),
            notes=expense_data.get('notes'),
            status='draft',
            created_by=user_id
        )

        self.db.add(expense)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_EXPENSE_CREATED,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=f"Created expense {expense_number} for {expense_data['category']}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(expense)

        return expense

    def get_expense_by_id(self, expense_id: str, org_id: str) -> Optional[Expense]:
        """Get expense by ID with organization scope"""
        return self.db.query(Expense).options(
            joinedload(Expense.attachments)
        ).filter(
            Expense.id == expense_id,
            Expense.organization_id == org_id
        ).first()

    def get_expenses_by_organization(
        self,
        org_id: str,
        skip: int = 0,
        limit: int = 100,
        status: Optional[str] = None,
        category: Optional[str] = None,
        vehicle_id: Optional[str] = None,
        driver_id: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> tuple[List[Expense], int]:
        """
        Get expenses for organization with filters and pagination.

        Returns:
            Tuple of (expenses, total_count)
        """
        query = self.db.query(Expense).filter(
            Expense.organization_id == org_id
        )

        # Apply filters
        if status:
            query = query.filter(Expense.status == status)

        if category:
            query = query.filter(Expense.category == category)

        if vehicle_id:
            query = query.filter(Expense.vehicle_id == vehicle_id)

        if driver_id:
            query = query.filter(Expense.driver_id == driver_id)

        if from_date:
            query = query.filter(Expense.expense_date >= from_date)

        if to_date:
            query = query.filter(Expense.expense_date <= to_date)

        # Get total count
        total = query.count()

        # Get paginated results
        expenses = query.options(
            joinedload(Expense.attachments)
        ).order_by(
            Expense.expense_date.desc(),
            Expense.created_at.desc()
        ).offset(skip).limit(limit).all()

        return expenses, total

    def update_expense(
        self,
        user_id: str,
        expense_id: str,
        org_id: str,
        expense_data: Dict[str, Any]
    ) -> Expense:
        """
        Update expense (only if in draft or rejected status).

        Args:
            user_id: User updating the expense
            expense_id: Expense ID
            org_id: Organization ID
            expense_data: Updated expense information

        Returns:
            Updated expense

        Raises:
            HTTPException: If update fails
        """
        expense = self.get_expense_by_id(expense_id, org_id)

        if not expense:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        if not expense.can_edit():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot edit expense in {expense.status} status"
            )

        # Update fields if provided
        if 'category' in expense_data:
            expense.category = expense_data['category']

        if 'description' in expense_data:
            expense.description = expense_data['description']

        if 'amount' in expense_data or 'tax_amount' in expense_data:
            expense.amount = expense_data.get('amount', expense.amount)
            expense.tax_amount = expense_data.get('tax_amount', expense.tax_amount)
            expense.total_amount = expense.amount + expense.tax_amount

        if 'expense_date' in expense_data:
            expense.expense_date = expense_data['expense_date']

        if 'vehicle_id' in expense_data:
            expense.vehicle_id = expense_data['vehicle_id']

        if 'driver_id' in expense_data:
            expense.driver_id = expense_data['driver_id']

        if 'vendor_id' in expense_data:
            expense.vendor_id = expense_data['vendor_id']

        if 'notes' in expense_data:
            expense.notes = expense_data['notes']

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_EXPENSE_UPDATED,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=f"Updated expense {expense.expense_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(expense)

        return expense

    def submit_expense(self, user_id: str, expense_id: str, org_id: str) -> Expense:
        """
        Submit expense for approval.

        Args:
            user_id: User submitting the expense
            expense_id: Expense ID
            org_id: Organization ID

        Returns:
            Updated expense

        Raises:
            HTTPException: If submission fails
        """
        expense = self.get_expense_by_id(expense_id, org_id)

        if not expense:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        if not expense.can_submit():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot submit expense in {expense.status} status"
            )

        expense.status = 'submitted'
        expense.submitted_at = datetime.now()
        expense.submitted_by = user_id

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_EXPENSE_SUBMITTED,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=f"Submitted expense {expense.expense_number} for approval"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(expense)

        return expense

    def approve_expense(
        self,
        user_id: str,
        expense_id: str,
        org_id: str,
        approved: bool,
        rejection_reason: Optional[str] = None
    ) -> Expense:
        """
        Approve or reject expense.

        Args:
            user_id: User approving/rejecting
            expense_id: Expense ID
            org_id: Organization ID
            approved: True to approve, False to reject
            rejection_reason: Reason for rejection (required if rejected)

        Returns:
            Updated expense

        Raises:
            HTTPException: If approval fails
        """
        expense = self.get_expense_by_id(expense_id, org_id)

        if not expense:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        if not expense.can_approve():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot approve expense in {expense.status} status"
            )

        if approved:
            expense.status = 'approved'
            expense.approved_at = datetime.now()
            expense.approved_by = user_id
            expense.rejection_reason = None

            # Update budget if exists
            self._update_budget_for_expense(expense)

            action = AUDIT_ACTION_EXPENSE_APPROVED
            details = f"Approved expense {expense.expense_number}"
        else:
            if not rejection_reason:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Rejection reason is required"
                )

            expense.status = 'rejected'
            expense.approved_at = datetime.now()
            expense.approved_by = user_id
            expense.rejection_reason = rejection_reason

            action = AUDIT_ACTION_EXPENSE_REJECTED
            details = f"Rejected expense {expense.expense_number}: {rejection_reason}"

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=action,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=details
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(expense)

        return expense

    def mark_expense_paid(self, user_id: str, expense_id: str, org_id: str) -> Expense:
        """
        Mark expense as paid.

        Args:
            user_id: User marking as paid
            expense_id: Expense ID
            org_id: Organization ID

        Returns:
            Updated expense

        Raises:
            HTTPException: If marking fails
        """
        expense = self.get_expense_by_id(expense_id, org_id)

        if not expense:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        if not expense.can_mark_paid():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot mark expense as paid in {expense.status} status"
            )

        expense.status = 'paid'
        expense.paid_at = datetime.now()

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_EXPENSE_PAID,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=f"Marked expense {expense.expense_number} as paid"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(expense)

        return expense

    def get_expense_summary(
        self,
        org_id: str,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        group_by: str = 'category'
    ) -> Dict[str, Any]:
        """
        Get expense summary grouped by category, vehicle, or month.

        Args:
            org_id: Organization ID
            from_date: Start date filter
            to_date: End date filter
            group_by: Group by 'category', 'vehicle', or 'month'

        Returns:
            Summary data with totals
        """
        query = self.db.query(Expense).filter(
            Expense.organization_id == org_id,
            Expense.status.in_(['approved', 'paid'])
        )

        if from_date:
            query = query.filter(Expense.expense_date >= from_date)

        if to_date:
            query = query.filter(Expense.expense_date <= to_date)

        summary = []

        if group_by == 'category':
            results = query.with_entities(
                Expense.category,
                func.sum(Expense.total_amount).label('total_amount'),
                func.count(Expense.id).label('count')
            ).group_by(Expense.category).all()

            summary = [
                {
                    'category': r.category,
                    'total_amount': r.total_amount or Decimal('0'),
                    'count': r.count
                }
                for r in results
            ]

        elif group_by == 'vehicle':
            results = query.with_entities(
                Expense.vehicle_id,
                func.sum(Expense.total_amount).label('total_amount'),
                func.count(Expense.id).label('count')
            ).group_by(Expense.vehicle_id).all()

            summary = [
                {
                    'vehicle_id': r.vehicle_id,
                    'total_amount': r.total_amount or Decimal('0'),
                    'count': r.count
                }
                for r in results
            ]

        elif group_by == 'month':
            results = query.with_entities(
                func.to_char(Expense.expense_date, 'YYYY-MM').label('month'),
                func.sum(Expense.total_amount).label('total_amount'),
                func.count(Expense.id).label('count')
            ).group_by(func.to_char(Expense.expense_date, 'YYYY-MM')).all()

            summary = [
                {
                    'month': r.month,
                    'total_amount': r.total_amount or Decimal('0'),
                    'count': r.count
                }
                for r in results
            ]

        # Calculate grand total
        grand_total = sum(item['total_amount'] for item in summary)
        total_count = sum(item['count'] for item in summary)

        return {
            'summary': summary,
            'grand_total': grand_total,
            'total_count': total_count
        }

    def upload_expense_attachment(
        self,
        user_id: str,
        expense_id: str,
        org_id: str,
        file_name: str,
        file_path: str,
        file_size: int,
        file_type: Optional[str] = None
    ) -> ExpenseAttachment:
        """
        Upload attachment for expense.

        Args:
            user_id: User uploading the file
            expense_id: Expense ID
            org_id: Organization ID
            file_name: Original file name
            file_path: Stored file path
            file_size: File size in bytes
            file_type: MIME type

        Returns:
            Created attachment

        Raises:
            HTTPException: If upload fails
        """
        expense = self.get_expense_by_id(expense_id, org_id)

        if not expense:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Expense not found"
            )

        attachment = ExpenseAttachment(
            id=uuid.uuid4(),
            expense_id=expense_id,
            file_name=file_name,
            file_path=file_path,
            file_size=file_size,
            file_type=file_type,
            uploaded_by=user_id
        )

        self.db.add(attachment)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_EXPENSE_ATTACHMENT_UPLOADED,
            entity_type=ENTITY_TYPE_EXPENSE,
            entity_id=str(expense.id),
            details=f"Uploaded attachment {file_name} for expense {expense.expense_number}"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(attachment)

        return attachment

    def _update_budget_for_expense(self, expense: Expense):
        """Update budget spent amount when expense is approved"""
        # Find matching budget for the expense category and period
        expense_month = expense.expense_date.month
        expense_year = expense.expense_date.year

        # Try to find monthly budget
        budget = self.db.query(Budget).filter(
            Budget.organization_id == expense.organization_id,
            Budget.category == expense.category,
            Budget.period == 'monthly',
            extract('year', Budget.start_date) == expense_year,
            extract('month', Budget.start_date) == expense_month
        ).first()

        if budget:
            budget.spent_amount += expense.total_amount
            budget.remaining_amount = budget.allocated_amount - budget.spent_amount
