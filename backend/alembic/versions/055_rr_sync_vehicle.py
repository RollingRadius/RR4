"""Add rr_vehicle_id to vehicles for RR sync.

Revision ID: 055
Revises: 054
Create Date: 2026-05-23
"""
from alembic import op
import sqlalchemy as sa

revision = '055'
down_revision = '054'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('vehicles', sa.Column('rr_vehicle_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('vehicles', 'rr_vehicle_id')
