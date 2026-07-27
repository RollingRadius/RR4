"""Add material_weight and material_weight_unit to load_requirements

Revision ID: 081
Revises: 080
Create Date: 2026-07-27

Truck weight (capacity) is now optional. Material weight is a new, required
field for how much cargo actually needs to move — separate from truck
weight capacity — with its own unit ('Tons' | 'Kg').
"""
from alembic import op
import sqlalchemy as sa

revision = '081'
down_revision = '080'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('load_requirements', sa.Column('material_weight', sa.String(50), nullable=True))
    op.add_column('load_requirements', sa.Column('material_weight_unit', sa.String(10), nullable=True))


def downgrade():
    op.drop_column('load_requirements', 'material_weight_unit')
    op.drop_column('load_requirements', 'material_weight')
