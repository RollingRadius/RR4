"""Add rr_company_id to organizations for RR sync.

Revision ID: 054
Revises: 053
Create Date: 2026-05-23
"""
from alembic import op
import sqlalchemy as sa

revision = '054'
down_revision = '053'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('organizations', sa.Column('rr_company_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('organizations', 'rr_company_id')
