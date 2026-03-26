"""Add target_org_ids to load_requirements

Revision ID: 036
Revises: 035
Create Date: 2026-03-26
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '036'
down_revision = '035'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'load_requirements',
        sa.Column('target_org_ids', JSONB, nullable=True),
    )


def downgrade():
    op.drop_column('load_requirements', 'target_org_ids')
