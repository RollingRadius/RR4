"""add business_type check constraint with fleet_owner and load_owner

Revision ID: 020_add_business_type_constraint
Revises: 019_add_load_owner_role
Create Date: 2026-03-20

Adds a CHECK constraint on organizations.business_type to enforce valid values,
including the new fleet_owner and load_owner types.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '020_add_business_type_constraint'
down_revision: Union[str, None] = '019_add_load_owner_role'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

VALID_BUSINESS_TYPES = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'fleet_owner', 'load_owner', 'other'
)


def upgrade() -> None:
    """Add check constraint on business_type and update any existing invalid values."""
    # Set any unrecognized business_type values to 'other' before adding constraint
    valid_list = ", ".join(f"'{t}'" for t in VALID_BUSINESS_TYPES)
    op.execute(
        sa.text(f"""
            UPDATE organizations
            SET business_type = 'other'
            WHERE business_type NOT IN ({valid_list})
        """)
    )

    # Add check constraint
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )


def downgrade() -> None:
    """Remove check constraint on business_type."""
    op.drop_constraint('check_business_type', 'organizations', type_='check')
