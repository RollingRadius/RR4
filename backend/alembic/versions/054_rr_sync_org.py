"""Add rr_company_id to organizations for RR sync.

Revision ID: 054_rr_sync_org
Revises: 054
Create Date: 2026-05-23
"""
from alembic import op
import sqlalchemy as sa

# Originally revision '054', renumbered to '073' by a main-only fix to dodge
# a collision with 054_add_s3_eway_bill.py — but '073' collides again with
# staging's separate, later 073_add_rr_auto_sync.py. Given a unique,
# self-documenting id instead of reusing another numeric slot.
revision = '054_rr_sync_org'
down_revision = '054'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('organizations', sa.Column('rr_company_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('organizations', 'rr_company_id')
