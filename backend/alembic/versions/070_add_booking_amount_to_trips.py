"""Add booking_amount to trips

Revision ID: 070
Revises: 069
Create Date: 2026-06-09

Separate field from expected_freight:
- expected_freight = consignor's expected price (informational)
- booking_amount   = LP's offline bid / offer sent to vehicle provider (used in create_trip)
"""

from alembic import op
import sqlalchemy as sa

revision = '070'
down_revision = '069'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('booking_amount', sa.Numeric(12, 2), nullable=True))


def downgrade():
    op.drop_column('trips', 'booking_amount')
