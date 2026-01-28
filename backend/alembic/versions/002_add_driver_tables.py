"""Add driver and driver_license tables

Revision ID: 002_add_driver_tables
Revises: 001_initial_schema
Create Date: 2026-01-22

Creates 2 tables:
1. drivers - Driver personal and employment information
2. driver_licenses - Driver license information (1-to-1 with drivers)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = '002_add_driver_tables'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create drivers and driver_licenses tables"""

    # 1. Create drivers table
    op.create_table(
        'drivers',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('employee_id', sa.String(length=50), nullable=False),
        sa.Column('join_date', sa.Date(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('first_name', sa.String(length=100), nullable=False),
        sa.Column('last_name', sa.String(length=100), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('phone', sa.String(length=20), nullable=False),
        sa.Column('date_of_birth', sa.Date(), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('state', sa.String(length=100), nullable=True),
        sa.Column('pincode', sa.String(length=10), nullable=True),
        sa.Column('country', sa.String(length=100), nullable=False, server_default='India'),
        sa.Column('emergency_contact_name', sa.String(length=255), nullable=True),
        sa.Column('emergency_contact_phone', sa.String(length=20), nullable=True),
        sa.Column('emergency_contact_relationship', sa.String(length=50), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.CheckConstraint(
            "status IN ('active', 'inactive', 'on_leave', 'terminated')",
            name='check_driver_status'
        ),
        sa.CheckConstraint(
            "email IS NULL OR email ~ '^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$'",
            name='check_driver_email_format'
        ),
        sa.CheckConstraint(
            "phone ~ '^\\+?[0-9]{10,20}$'",
            name='check_driver_phone_format'
        ),
        sa.CheckConstraint(
            "pincode IS NULL OR pincode ~ '^\\d{6}$'",
            name='check_driver_pincode_format'
        ),
        sa.CheckConstraint(
            "emergency_contact_phone IS NULL OR emergency_contact_phone ~ '^\\+?[0-9]{10,20}$'",
            name='check_emergency_phone_format'
        )
    )

    # Create indexes for drivers table
    op.create_index('idx_drivers_organization', 'drivers', ['organization_id'])
    op.create_index('idx_drivers_status', 'drivers', ['status'])
    op.create_index('idx_drivers_email', 'drivers', ['email'], postgresql_where=sa.text('email IS NOT NULL'))
    op.create_index('idx_driver_org_employee', 'drivers', ['organization_id', 'employee_id'], unique=True)

    # 2. Create driver_licenses table
    op.create_table(
        'driver_licenses',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('driver_id', postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column('license_number', sa.String(length=50), nullable=False, unique=True),
        sa.Column('license_type', sa.String(length=10), nullable=False),
        sa.Column('issue_date', sa.Date(), nullable=False),
        sa.Column('expiry_date', sa.Date(), nullable=False),
        sa.Column('issuing_authority', sa.String(length=255), nullable=True),
        sa.Column('issuing_state', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['driver_id'], ['drivers.id'], ondelete='CASCADE'),
        sa.CheckConstraint(
            "license_type IN ('LMV', 'HMV', 'MCWG', 'HPMV')",
            name='check_license_type'
        ),
        sa.CheckConstraint(
            "expiry_date > issue_date",
            name='check_expiry_after_issue'
        ),
        sa.CheckConstraint(
            "license_number ~ '^[A-Z0-9\\-]{10,50}$'",
            name='check_license_number_format'
        )
    )

    # Create indexes for driver_licenses table
    op.create_index('idx_license_number', 'driver_licenses', ['license_number'], unique=True)
    op.create_index('idx_license_expiry', 'driver_licenses', ['expiry_date'])


def downgrade() -> None:
    """Drop drivers and driver_licenses tables"""

    # Drop indexes first
    op.drop_index('idx_license_expiry', 'driver_licenses')
    op.drop_index('idx_license_number', 'driver_licenses')

    op.drop_index('idx_driver_org_employee', 'drivers')
    op.drop_index('idx_drivers_email', 'drivers')
    op.drop_index('idx_drivers_status', 'drivers')
    op.drop_index('idx_drivers_organization', 'drivers')

    # Drop tables in reverse order (respecting foreign keys)
    op.drop_table('driver_licenses')
    op.drop_table('drivers')
