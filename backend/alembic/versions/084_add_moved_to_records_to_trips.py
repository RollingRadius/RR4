"""Add moved_to_records_at to trips

Revision ID: 084
Revises: 083
Create Date: 2026-07-31

Backs the Move-to-Records feature: an explicit, one-directional LP/RR-ops
action (long-press a trip -> "Move to Records") independent of sync
progress. A single timestamp column, shared across LP/RR-ops/FE trip
list views -- not per-role state. NULL means not moved to Records.
"""

from alembic import op
import sqlalchemy as sa

revision = '084'
down_revision = '083'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('moved_to_records_at', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 'moved_to_records_at')
