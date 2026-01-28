"""Add verification code column

Revision ID: 006_add_verification_code
Revises: 005_add_vehicle_tables
Create Date: 2026-01-28 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = '006_add_verification_code'
down_revision: Union[str, None] = '005_add_vehicle_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add verification_code column to verification_tokens table
    op.add_column('verification_tokens', sa.Column('verification_code', sa.String(10), nullable=True))

    # Create index for verification_code for faster lookups
    op.create_index('idx_verification_tokens_code', 'verification_tokens', ['verification_code'])


def downgrade() -> None:
    # Drop index
    op.drop_index('idx_verification_tokens_code', table_name='verification_tokens')

    # Drop column
    op.drop_column('verification_tokens', 'verification_code')
