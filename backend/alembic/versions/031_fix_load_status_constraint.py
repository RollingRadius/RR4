"""fix load_requirements status constraint to include 'matched'

The original check_load_status constraint was missing 'matched', causing
a CheckViolation when fleet management fulfills a load requirement.

Revision ID: 031
Revises: 030
Create Date: 2026-03-24
"""

from alembic import op

revision = '031'
down_revision = '030'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop the old constraint
    op.drop_constraint('check_load_status', 'load_requirements', type_='check')
    # Re-create with 'matched' included
    op.create_check_constraint(
        'check_load_status',
        'load_requirements',
        "status IN ('pending', 'matched', 'assigned', 'in_transit', 'delivered', 'cancelled')"
    )


def downgrade() -> None:
    op.drop_constraint('check_load_status', 'load_requirements', type_='check')
    op.create_check_constraint(
        'check_load_status',
        'load_requirements',
        "status IN ('pending', 'assigned', 'in_transit', 'delivered', 'cancelled')"
    )
