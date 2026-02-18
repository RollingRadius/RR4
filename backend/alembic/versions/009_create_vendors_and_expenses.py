"""Create vendors and expenses tables

Revision ID: 009_create_vendors_and_expenses
Revises: add_user_id_to_drivers
Create Date: 2026-01-30 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
import uuid

# revision identifiers
revision: str = '009_create_vendors_and_expenses'
down_revision: Union[str, None] = '008_add_requested_role_field'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create vendors table
    op.create_table(
        'vendors',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column('organization_id', UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('vendor_name', sa.String(255), nullable=False),
        sa.Column('vendor_type', sa.String(50), nullable=False),
        sa.Column('contact_person', sa.String(255), nullable=True),
        sa.Column('email', sa.String(255), nullable=True),
        sa.Column('phone', sa.String(20), nullable=True),
        sa.Column('address', sa.Text, nullable=True),
        sa.Column('city', sa.String(100), nullable=True),
        sa.Column('state', sa.String(100), nullable=True),
        sa.Column('pincode', sa.String(10), nullable=True),
        sa.Column('country', sa.String(100), nullable=False, server_default='India'),
        sa.Column('gstin', sa.String(15), nullable=True),
        sa.Column('pan', sa.String(10), nullable=True),
        sa.Column('bank_name', sa.String(255), nullable=True),
        sa.Column('bank_account_number', sa.String(50), nullable=True),
        sa.Column('bank_ifsc_code', sa.String(11), nullable=True),
        sa.Column('notes', sa.Text, nullable=True),
        sa.Column('status', sa.String(20), nullable=False, server_default='active'),
        sa.Column('created_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, nullable=False, server_default=sa.func.now()),

        # Constraints
        sa.CheckConstraint(
            "vendor_type IN ('supplier', 'workshop', 'fuel_station', 'insurance', 'other')",
            name='check_vendor_type'
        ),
        sa.CheckConstraint(
            "status IN ('active', 'inactive')",
            name='check_vendor_status'
        ),
        sa.CheckConstraint(
            r"email IS NULL OR email ~ '^[\w\.-]+@[\w\.-]+\.\w+$'",
            name='check_vendor_email_format'
        ),
        sa.CheckConstraint(
            r"phone IS NULL OR phone ~ '^\+?[0-9]{10,20}$'",
            name='check_vendor_phone_format'
        ),
        sa.CheckConstraint(
            r"pincode IS NULL OR pincode ~ '^\d{6}$'",
            name='check_vendor_pincode_format'
        ),
        sa.CheckConstraint(
            r"gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$'",
            name='check_vendor_gstin_format'
        ),
        sa.CheckConstraint(
            r"pan IS NULL OR pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'",
            name='check_vendor_pan_format'
        ),
    )

    # Create indexes for vendors
    op.create_index('idx_vendors_organization_id', 'vendors', ['organization_id'])
    op.create_index('idx_vendors_vendor_type', 'vendors', ['vendor_type'])
    op.create_index('idx_vendors_status', 'vendors', ['status'])
    op.create_index('idx_vendors_gstin', 'vendors', ['gstin'])
    op.create_index('idx_vendor_org_name', 'vendors', ['organization_id', 'vendor_name'])

    # Create expenses table
    op.create_table(
        'expenses',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column('organization_id', UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('expense_number', sa.String(50), nullable=False),
        sa.Column('category', sa.String(50), nullable=False),
        sa.Column('description', sa.Text, nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('tax_amount', sa.Numeric(12, 2), nullable=False, server_default='0'),
        sa.Column('total_amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('expense_date', sa.Date, nullable=False),
        sa.Column('vehicle_id', UUID(as_uuid=True), sa.ForeignKey('vehicles.id', ondelete='SET NULL'), nullable=True),
        sa.Column('driver_id', UUID(as_uuid=True), sa.ForeignKey('drivers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('vendor_id', UUID(as_uuid=True), sa.ForeignKey('vendors.id', ondelete='SET NULL'), nullable=True),
        sa.Column('status', sa.String(20), nullable=False, server_default='draft'),
        sa.Column('submitted_at', sa.DateTime, nullable=True),
        sa.Column('submitted_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('approved_at', sa.DateTime, nullable=True),
        sa.Column('approved_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('rejection_reason', sa.Text, nullable=True),
        sa.Column('paid_at', sa.DateTime, nullable=True),
        sa.Column('notes', sa.Text, nullable=True),
        sa.Column('created_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, nullable=False, server_default=sa.func.now()),

        # Constraints
        sa.CheckConstraint(
            "category IN ('fuel', 'maintenance', 'toll', 'parking', 'insurance', 'salary', 'other')",
            name='check_expense_category'
        ),
        sa.CheckConstraint(
            "status IN ('draft', 'submitted', 'approved', 'rejected', 'paid')",
            name='check_expense_status'
        ),
        sa.CheckConstraint(
            "amount >= 0",
            name='check_expense_amount_positive'
        ),
        sa.CheckConstraint(
            "tax_amount >= 0",
            name='check_tax_amount_positive'
        ),
        sa.CheckConstraint(
            "total_amount >= 0",
            name='check_total_amount_positive'
        ),
        sa.UniqueConstraint('expense_number', name='uq_expense_number'),
    )

    # Create indexes for expenses
    op.create_index('idx_expenses_organization_id', 'expenses', ['organization_id'])
    op.create_index('idx_expenses_expense_number', 'expenses', ['expense_number'])
    op.create_index('idx_expenses_category', 'expenses', ['category'])
    op.create_index('idx_expenses_vehicle_id', 'expenses', ['vehicle_id'])
    op.create_index('idx_expenses_driver_id', 'expenses', ['driver_id'])
    op.create_index('idx_expenses_vendor_id', 'expenses', ['vendor_id'])
    op.create_index('idx_expenses_status', 'expenses', ['status'])
    op.create_index('idx_expenses_expense_date', 'expenses', ['expense_date'])
    op.create_index('idx_expense_org_number', 'expenses', ['organization_id', 'expense_number'], unique=True)
    op.create_index('idx_expense_status_date', 'expenses', ['status', 'expense_date'])

    # Create expense_attachments table
    op.create_table(
        'expense_attachments',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column('expense_id', UUID(as_uuid=True), sa.ForeignKey('expenses.id', ondelete='CASCADE'), nullable=False),
        sa.Column('file_name', sa.String(255), nullable=False),
        sa.Column('file_path', sa.String(500), nullable=False),
        sa.Column('file_size', sa.Numeric(12, 0), nullable=False),
        sa.Column('file_type', sa.String(50), nullable=True),
        sa.Column('uploaded_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploaded_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    # Create indexes for expense_attachments
    op.create_index('idx_expense_attachments_expense_id', 'expense_attachments', ['expense_id'])


def downgrade() -> None:
    # Drop tables in reverse order
    op.drop_table('expense_attachments')
    op.drop_table('expenses')
    op.drop_table('vendors')
