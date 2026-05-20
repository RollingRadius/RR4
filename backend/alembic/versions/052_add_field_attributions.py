"""Add field_attributions JSONB column to trips for persistent per-field attribution.

Revision ID: 052
Revises: 051
Create Date: 2026-05-16
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '052'
down_revision = '051'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column('field_attributions', JSONB(), nullable=True))


def downgrade() -> None:
    op.drop_column('trips', 'field_attributions')
