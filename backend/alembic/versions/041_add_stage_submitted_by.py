"""Track who submitted each trip stage

Revision ID: 041
Revises: 040
Create Date: 2026-03-30
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '041'
down_revision = '040'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column('s1_submitted_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s2_submitted_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s3_submitted_by', UUID(as_uuid=True), nullable=True))
    op.add_column('trips', sa.Column('s4_submitted_by', UUID(as_uuid=True), nullable=True))


def downgrade() -> None:
    op.drop_column('trips', 's4_submitted_by')
    op.drop_column('trips', 's3_submitted_by')
    op.drop_column('trips', 's2_submitted_by')
    op.drop_column('trips', 's1_submitted_by')
