"""Add rr_booking_id to trips

Revision ID: 067
Revises: 066
Create Date: 2026-06-09

Stores the purchase-order booking_id returned by RR POST /create_trip
(e.g. "10002500"). Generated during award_vehicle → post_purchase_order_record.
"""

from alembic import op
import sqlalchemy as sa

revision = '067'
down_revision = '066'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_booking_id', sa.String(30), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_booking_id')
