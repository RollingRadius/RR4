"""Support independent drivers (profile completion flow)

Revision ID: 029
Revises: 028
Create Date: 2026-03-24

Changes:
1. Make organization_id nullable in drivers table (independent drivers have no org)
2. Make employee_id nullable (no employee ID for self-registered drivers)
3. Make join_date nullable (no formal join date for self-registered drivers)
4. Drop the unique index on (organization_id, employee_id) since both can be null
5. Add license_number and license_expiry columns directly to drivers table
   (simpler than requiring the full DriverLicense record at profile completion)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = '029'
down_revision: Union[str, None] = '028'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Drop the unique index on (organization_id, employee_id) — it blocks NULLs
    op.drop_index('idx_driver_org_employee', table_name='drivers')

    # 2. Make organization_id nullable (independent drivers have no org)
    op.alter_column('drivers', 'organization_id', nullable=True)

    # 3. Make employee_id nullable
    op.alter_column('drivers', 'employee_id', nullable=True)

    # 4. Make join_date nullable
    op.alter_column('drivers', 'join_date', nullable=True)

    # 5. Add license_number column to drivers (for self-registered independent drivers)
    op.add_column('drivers', sa.Column('license_number', sa.String(length=50), nullable=True))

    # 6. Add license_expiry column to drivers
    op.add_column('drivers', sa.Column('license_expiry', sa.Date(), nullable=True))

    # 7. Re-create the partial unique index only for org drivers (where both are NOT NULL)
    op.create_index(
        'idx_driver_org_employee',
        'drivers',
        ['organization_id', 'employee_id'],
        unique=True,
        postgresql_where=sa.text('organization_id IS NOT NULL AND employee_id IS NOT NULL')
    )


def downgrade() -> None:
    op.drop_index('idx_driver_org_employee', table_name='drivers')
    op.drop_column('drivers', 'license_expiry')
    op.drop_column('drivers', 'license_number')

    op.alter_column('drivers', 'join_date', nullable=False)
    op.alter_column('drivers', 'employee_id', nullable=False)
    op.alter_column('drivers', 'organization_id', nullable=False)

    op.create_index('idx_driver_org_employee', 'drivers', ['organization_id', 'employee_id'], unique=True)
