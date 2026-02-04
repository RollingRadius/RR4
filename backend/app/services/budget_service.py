"""
Budget Service
Business logic for budget management
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_, func, extract
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from decimal import Decimal
import uuid

from app.models.budget import Budget
from app.models.expense import Expense
from app.models.company import Organization
from app.models.audit_log import AuditLog
from app.schemas.budget import BudgetCreateRequest, BudgetUpdateRequest
from app.utils.constants import (
    AUDIT_ACTION_BUDGET_CREATED,
    AUDIT_ACTION_BUDGET_UPDATED,
    AUDIT_ACTION_BUDGET_ALERT,
    ENTITY_TYPE_BUDGET
)


class BudgetService:
    """Service for budget operations"""

    def __init__(self, db: Session):
        self.db = db

    def create_budget(
        self,
        user_id: str,
        org_id: str,
        budget_data: BudgetCreateRequest
    ) -> Budget:
        """
        Create a new budget.

        Args:
            user_id: User creating the budget
            org_id: Organization ID
            budget_data: Validated budget information

        Returns:
            Created budget

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

        # Date range already validated by Pydantic
        # Check for overlapping budgets in same category
        overlapping = self.db.query(Budget).filter(
            Budget.organization_id == org_id,
            Budget.category == budget_data.category,
            Budget.start_date <= budget_data.end_date,
            Budget.end_date >= budget_data.start_date
        ).first()

        if overlapping:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Budget already exists for {budget_data.category} in this period"
            )

        # Create budget
        budget = Budget(
            id=uuid.uuid4(),
            organization_id=org_id,
            name=budget_data.name,
            category=budget_data.category,
            period=budget_data.period,
            start_date=budget_data.start_date,
            end_date=budget_data.end_date,
            allocated_amount=budget_data.allocated_amount,
            spent_amount=Decimal('0'),
            remaining_amount=budget_data.allocated_amount,
            alert_threshold_percent=budget_data.alert_threshold_percent,
            created_by=user_id
        )

        self.db.add(budget)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_BUDGET_CREATED,
            entity_type=ENTITY_TYPE_BUDGET,
            entity_id=str(budget.id),
            details=f"Created budget '{budget_data.name}' for {budget_data.category} ({budget_data.allocated_amount})"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(budget)

        return budget

    def get_budget_by_id(self, budget_id: str, org_id: str) -> Optional[Budget]:
        """Get budget by ID with organization scope"""
        return self.db.query(Budget).filter(
            Budget.id == budget_id,
            Budget.organization_id == org_id
        ).first()

    def get_budgets_by_organization(
        self,
        org_id: str,
        skip: int = 0,
        limit: int = 100,
        category: Optional[str] = None,
        period: Optional[str] = None,
        active_only: bool = False
    ) -> tuple[List[Budget], int]:
        """
        Get budgets for organization with filters and pagination.

        Returns:
            Tuple of (budgets, total_count)
        """
        query = self.db.query(Budget).filter(
            Budget.organization_id == org_id
        )

        # Apply filters
        if category:
            query = query.filter(Budget.category == category)

        if period:
            query = query.filter(Budget.period == period)

        if active_only:
            today = date.today()
            query = query.filter(
                Budget.start_date <= today,
                Budget.end_date >= today
            )

        # Get total count
        total = query.count()

        # Get paginated results
        budgets = query.order_by(
            Budget.start_date.desc(),
            Budget.created_at.desc()
        ).offset(skip).limit(limit).all()

        return budgets, total

    def update_budget(
        self,
        user_id: str,
        budget_id: str,
        org_id: str,
        budget_data: BudgetUpdateRequest
    ) -> Budget:
        """
        Update budget.

        Args:
            user_id: User updating the budget
            budget_id: Budget ID
            org_id: Organization ID
            budget_data: Validated updated budget information

        Returns:
            Updated budget

        Raises:
            HTTPException: If update fails
        """
        budget = self.get_budget_by_id(budget_id, org_id)

        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found"
            )

        # Update fields if provided (using model_dump with exclude_unset)
        update_data = budget_data.model_dump(exclude_unset=True)

        if 'name' in update_data:
            budget.name = budget_data.name

        if 'allocated_amount' in update_data:
            budget.allocated_amount = budget_data.allocated_amount
            self._recalculate_remaining(budget)

        if 'alert_threshold_percent' in update_data:
            budget.alert_threshold_percent = budget_data.alert_threshold_percent

        if 'start_date' in update_data or 'end_date' in update_data:
            start_date = budget_data.start_date if budget_data.start_date else budget.start_date
            end_date = budget_data.end_date if budget_data.end_date else budget.end_date

            if end_date <= start_date:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="End date must be after start date"
                )

            budget.start_date = start_date
            budget.end_date = end_date

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action=AUDIT_ACTION_BUDGET_UPDATED,
            entity_type=ENTITY_TYPE_BUDGET,
            entity_id=str(budget.id),
            details=f"Updated budget '{budget.name}'"
        )
        self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(budget)

        return budget

    def delete_budget(self, user_id: str, budget_id: str, org_id: str) -> None:
        """
        Delete budget.

        Args:
            user_id: User deleting the budget
            budget_id: Budget ID
            org_id: Organization ID

        Raises:
            HTTPException: If deletion fails
        """
        budget = self.get_budget_by_id(budget_id, org_id)

        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found"
            )

        budget_name = budget.name

        # Delete budget
        self.db.delete(budget)

        # Create audit log
        audit_log = AuditLog(
            user_id=user_id,
            action="budget_deleted",
            entity_type=ENTITY_TYPE_BUDGET,
            entity_id=str(budget_id),
            details=f"Deleted budget '{budget_name}'"
        )
        self.db.add(audit_log)

        self.db.commit()

    def update_spent_amount(
        self,
        budget_id: str,
        amount: Decimal,
        user_id: Optional[str] = None
    ) -> Budget:
        """
        Update budget spent amount (called when expense is approved).

        Args:
            budget_id: Budget ID
            amount: Amount to add to spent
            user_id: Optional user ID for audit log

        Returns:
            Updated budget
        """
        budget = self.db.query(Budget).filter(
            Budget.id == budget_id
        ).first()

        if not budget:
            return None

        budget.spent_amount += amount
        self._recalculate_remaining(budget)

        # Check if over threshold and log alert
        if budget.is_over_threshold and user_id:
            audit_log = AuditLog(
                user_id=user_id,
                action=AUDIT_ACTION_BUDGET_ALERT,
                entity_type=ENTITY_TYPE_BUDGET,
                entity_id=str(budget.id),
                details=f"Budget '{budget.name}' exceeded {budget.alert_threshold_percent}% threshold ({budget.percentage_spent}% spent)"
            )
            self.db.add(audit_log)

        self.db.commit()
        self.db.refresh(budget)

        return budget

    def _recalculate_remaining(self, budget: Budget) -> None:
        """Recalculate remaining amount"""
        budget.remaining_amount = budget.allocated_amount - budget.spent_amount

    def get_budget_alerts(self, org_id: str) -> List[Budget]:
        """
        Get budgets that are over their alert threshold.

        Args:
            org_id: Organization ID

        Returns:
            List of budgets over threshold
        """
        budgets = self.db.query(Budget).filter(
            Budget.organization_id == org_id
        ).all()

        # Filter budgets over threshold
        return [b for b in budgets if b.is_over_threshold]

    def get_budget_utilization(
        self,
        budget_id: str,
        org_id: str
    ) -> Dict[str, Any]:
        """
        Get detailed budget utilization information.

        Args:
            budget_id: Budget ID
            org_id: Organization ID

        Returns:
            Detailed utilization data with projections
        """
        budget = self.get_budget_by_id(budget_id, org_id)

        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found"
            )

        # Calculate days in budget period
        total_days = (budget.end_date - budget.start_date).days
        days_elapsed = (date.today() - budget.start_date).days
        days_remaining = (budget.end_date - date.today()).days

        # Calculate burn rate
        if days_elapsed > 0:
            daily_burn_rate = budget.spent_amount / Decimal(days_elapsed)
        else:
            daily_burn_rate = Decimal('0')

        # Project spending
        if days_remaining > 0:
            projected_total = budget.spent_amount + (daily_burn_rate * Decimal(days_remaining))
        else:
            projected_total = budget.spent_amount

        # Get expenses for this budget
        expenses = self.db.query(Expense).filter(
            Expense.organization_id == org_id,
            Expense.category == budget.category,
            Expense.expense_date >= budget.start_date,
            Expense.expense_date <= budget.end_date,
            Expense.status.in_(['approved', 'paid'])
        ).order_by(Expense.expense_date).all()

        return {
            'budget_id': str(budget.id),
            'name': budget.name,
            'category': budget.category,
            'period': budget.period,
            'start_date': budget.start_date.isoformat(),
            'end_date': budget.end_date.isoformat(),
            'allocated_amount': budget.allocated_amount,
            'spent_amount': budget.spent_amount,
            'remaining_amount': budget.remaining_amount,
            'percentage_spent': budget.percentage_spent,
            'is_over_threshold': budget.is_over_threshold,
            'is_exceeded': budget.is_exceeded,
            'is_active': budget.is_active(),
            'total_days': total_days,
            'days_elapsed': days_elapsed,
            'days_remaining': days_remaining,
            'daily_burn_rate': daily_burn_rate,
            'projected_total': projected_total,
            'projected_percentage': (projected_total / budget.allocated_amount * 100) if budget.allocated_amount > 0 else Decimal('0'),
            'expense_count': len(expenses),
            'alert_threshold_percent': budget.alert_threshold_percent
        }

    def compare_budget_periods(
        self,
        org_id: str,
        category: str,
        period1_start: date,
        period1_end: date,
        period2_start: date,
        period2_end: date
    ) -> Dict[str, Any]:
        """
        Compare budget spending across two periods.

        Args:
            org_id: Organization ID
            category: Expense category
            period1_start: Period 1 start date
            period1_end: Period 1 end date
            period2_start: Period 2 start date
            period2_end: Period 2 end date

        Returns:
            Comparison data
        """
        # Get budget for period 1
        budget1 = self.db.query(Budget).filter(
            Budget.organization_id == org_id,
            Budget.category == category,
            Budget.start_date <= period1_end,
            Budget.end_date >= period1_start
        ).first()

        # Get budget for period 2
        budget2 = self.db.query(Budget).filter(
            Budget.organization_id == org_id,
            Budget.category == category,
            Budget.start_date <= period2_end,
            Budget.end_date >= period2_start
        ).first()

        # Get expenses for period 1
        expenses1 = self.db.query(Expense).filter(
            Expense.organization_id == org_id,
            Expense.category == category,
            Expense.expense_date >= period1_start,
            Expense.expense_date <= period1_end,
            Expense.status.in_(['approved', 'paid'])
        ).all()

        # Get expenses for period 2
        expenses2 = self.db.query(Expense).filter(
            Expense.organization_id == org_id,
            Expense.category == category,
            Expense.expense_date >= period2_start,
            Expense.expense_date <= period2_end,
            Expense.status.in_(['approved', 'paid'])
        ).all()

        spent1 = sum(e.total_amount for e in expenses1)
        spent2 = sum(e.total_amount for e in expenses2)

        # Calculate change
        if spent1 > 0:
            change_amount = spent2 - spent1
            change_percent = (change_amount / spent1) * Decimal('100')
        else:
            change_amount = spent2
            change_percent = Decimal('100') if spent2 > 0 else Decimal('0')

        return {
            'category': category,
            'period1': {
                'start_date': period1_start.isoformat(),
                'end_date': period1_end.isoformat(),
                'budget_allocated': budget1.allocated_amount if budget1 else None,
                'spent_amount': spent1,
                'expense_count': len(expenses1)
            },
            'period2': {
                'start_date': period2_start.isoformat(),
                'end_date': period2_end.isoformat(),
                'budget_allocated': budget2.allocated_amount if budget2 else None,
                'spent_amount': spent2,
                'expense_count': len(expenses2)
            },
            'change': {
                'amount': change_amount,
                'percentage': change_percent,
                'trend': 'increase' if change_amount > 0 else 'decrease' if change_amount < 0 else 'stable'
            }
        }

    def get_budget_summary(
        self,
        org_id: str,
        active_only: bool = True
    ) -> Dict[str, Any]:
        """
        Get overall budget summary for dashboard.

        Args:
            org_id: Organization ID
            active_only: Only include active budgets

        Returns:
            Summary statistics
        """
        query = self.db.query(Budget).filter(
            Budget.organization_id == org_id
        )

        if active_only:
            today = date.today()
            query = query.filter(
                Budget.start_date <= today,
                Budget.end_date >= today
            )

        budgets = query.all()

        total_allocated = sum(b.allocated_amount for b in budgets)
        total_spent = sum(b.spent_amount for b in budgets)
        total_remaining = sum(b.remaining_amount for b in budgets)

        over_threshold_count = len([b for b in budgets if b.is_over_threshold])
        exceeded_count = len([b for b in budgets if b.is_exceeded])

        return {
            'total_budgets': len(budgets),
            'active_budgets': len([b for b in budgets if b.is_active()]),
            'total_allocated': total_allocated,
            'total_spent': total_spent,
            'total_remaining': total_remaining,
            'overall_percentage': (total_spent / total_allocated * 100) if total_allocated > 0 else Decimal('0'),
            'over_threshold_count': over_threshold_count,
            'exceeded_count': exceeded_count
        }
