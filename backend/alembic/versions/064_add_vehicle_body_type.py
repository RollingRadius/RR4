"""Add vehicle_body_type to trips

Revision ID: 064
Revises: 063
Create Date: 2026-06-01

Stores the RR VehicleBodyTypes enum value (e.g. 'Open', 'Container', 'Tipper')
selected by the LP at trip-creation / fulfillment time.
"""

from alembic import op
import sqlalchemy as sa

revision = '064'
down_revision = '063'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips',
        sa.Column('vehicle_body_type', sa.String(50), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('trips', 'vehicle_body_type')
