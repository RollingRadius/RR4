"""Add s3_e_way_bill_url column to trips for e-way bill upload at Stage 3.

Revision ID: 054
Revises: 053
Create Date: 2026-05-20
"""
from alembic import op
import sqlalchemy as sa

revision = '054'
down_revision = '053'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s3_e_way_bill_url', sa.Text(), nullable=True))


def downgrade():
    op.drop_column('trips', 's3_e_way_bill_url')
