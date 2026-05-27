"""Add rr_user_id to drivers for RR sync.

Revision ID: 056
Revises: 055
Create Date: 2026-05-23
"""
from alembic import op
import sqlalchemy as sa

revision = '056'
down_revision = '055'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('drivers', sa.Column('rr_user_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('drivers', 'rr_user_id')
