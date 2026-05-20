"""Add s1_permit column to trips for permit document upload.

Revision ID: 053
Revises: 052
Create Date: 2026-05-20
"""
from alembic import op
import sqlalchemy as sa

revision = '053'
down_revision = '052'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s1_permit', sa.Text(), nullable=True))


def downgrade():
    op.drop_column('trips', 's1_permit')
