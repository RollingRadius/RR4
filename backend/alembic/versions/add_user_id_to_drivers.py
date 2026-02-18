"""Add user_id to drivers table

Revision ID: add_user_id_to_drivers
Revises: 012_add_organization_branding
Create Date: 2026-01-29

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'add_user_id_to_drivers'
down_revision: Union[str, None] = '012_add_organization_branding'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    """Add user_id column to drivers table"""

    # Add user_id column
    op.add_column('drivers',
        sa.Column('user_id',
                  postgresql.UUID(as_uuid=True),
                  nullable=True))

    # Add foreign key constraint
    op.create_foreign_key(
        'fk_drivers_user_id',
        'drivers', 'users',
        ['user_id'], ['id'],
        ondelete='SET NULL'
    )

    # Add unique constraint
    op.create_unique_constraint(
        'uq_drivers_user_id',
        'drivers',
        ['user_id']
    )

    # Create index for better query performance
    op.create_index(
        'idx_drivers_user_id',
        'drivers',
        ['user_id']
    )


def downgrade():
    """Remove user_id column from drivers table"""

    # Drop index
    op.drop_index('idx_drivers_user_id', table_name='drivers')

    # Drop unique constraint
    op.drop_constraint('uq_drivers_user_id', 'drivers', type_='unique')

    # Drop foreign key
    op.drop_constraint('fk_drivers_user_id', 'drivers', type_='foreignkey')

    # Drop column
    op.drop_column('drivers', 'user_id')
