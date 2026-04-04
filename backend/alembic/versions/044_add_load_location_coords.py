"""Add lat/lon coordinates to load_requirements for pickup and unload locations.

Revision ID: 044
Revises: 043
"""

from alembic import op
import sqlalchemy as sa

revision = "044"
down_revision = "043"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("load_requirements", sa.Column("pickup_lat", sa.Float(), nullable=True))
    op.add_column("load_requirements", sa.Column("pickup_lon", sa.Float(), nullable=True))
    op.add_column("load_requirements", sa.Column("unload_lat", sa.Float(), nullable=True))
    op.add_column("load_requirements", sa.Column("unload_lon", sa.Float(), nullable=True))


def downgrade():
    op.drop_column("load_requirements", "unload_lon")
    op.drop_column("load_requirements", "unload_lat")
    op.drop_column("load_requirements", "pickup_lon")
    op.drop_column("load_requirements", "pickup_lat")
