"""Add profile completed flag

Revision ID: 007_add_profile_completed
Revises: 006_add_verification_code
Create Date: 2026-01-28 15:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = '007_add_profile_completed'
down_revision: Union[str, None] = '006_add_verification_code'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add profile_completed column to users table
    op.add_column('users', sa.Column('profile_completed', sa.Boolean(), nullable=False, server_default='false'))

    # Update existing users who have a role assigned to have profile_completed=true
    op.execute("""
        UPDATE users
        SET profile_completed = true
        WHERE id IN (
            SELECT DISTINCT user_id
            FROM user_organizations
            WHERE role_id IS NOT NULL
        )
    """)


def downgrade() -> None:
    # Drop column
    op.drop_column('users', 'profile_completed')
