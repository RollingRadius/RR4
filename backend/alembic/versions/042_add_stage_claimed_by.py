"""Track which worker is currently working on each trip stage

Revision ID: 042
Revises: 041
Create Date: 2026-03-31
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '042'
down_revision = '041'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column('s1_claimed_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s2_claimed_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s3_claimed_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s4_claimed_by', UUID(as_uuid=True), nullable=True))


def downgrade() -> None:
    op.drop_column('trips', 's4_claimed_by')
    op.drop_column('trips', 's3_claimed_by')
    op.drop_column('trips', 's2_claimed_by')
    op.drop_column('trips', 's1_claimed_by')
