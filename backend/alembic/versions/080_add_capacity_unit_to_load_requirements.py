"""Add capacity_unit to load_requirements

Revision ID: 080
Revises: 079
Create Date: 2026-07-27

The load owner's create-load form lets them enter the required truck weight
in either Tons or Kg, but the unit was never persisted anywhere — capacity
was stored as a bare number with no way to tell which unit it meant. This
column stores that unit ('Tons' or 'Kg') so LP/RR-ops can display it
correctly (e.g. "20 tons" vs "20000 kgs").
"""
from alembic import op
import sqlalchemy as sa

revision = '080'
down_revision = '079'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('load_requirements', sa.Column('capacity_unit', sa.String(10), nullable=True))


def downgrade():
    op.drop_column('load_requirements', 'capacity_unit')
