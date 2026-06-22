"""Add rr_driver_id to trips

Revision ID: 069
Revises: 068
Create Date: 2026-06-09

069 exists because 068 was deployed to the server before rr_driver_id was
added to that migration. This migration adds just the missing column.
"""

from alembic import op
import sqlalchemy as sa

revision = '069'
down_revision = '068'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS rr_driver_id VARCHAR(24)")


def downgrade():
    op.drop_column('trips', 'rr_driver_id')
