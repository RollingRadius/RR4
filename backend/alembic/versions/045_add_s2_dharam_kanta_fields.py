"""Add Stage 2 dharam kanta location and empty weight fields to trips.

Revision ID: 045
Revises: 044
"""

from alembic import op
import sqlalchemy as sa

revision = "045"
down_revision = "044"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("trips", sa.Column("s2_dharam_kanta_loc",  sa.String(20),  nullable=True))
    op.add_column("trips", sa.Column("s2_empty_weight_kg",   sa.String(20),  nullable=True))
    op.add_column("trips", sa.Column("s2_empty_weight_unit", sa.String(10),  nullable=True))


def downgrade():
    op.drop_column("trips", "s2_dharam_kanta_loc")
    op.drop_column("trips", "s2_empty_weight_kg")
    op.drop_column("trips", "s2_empty_weight_unit")
