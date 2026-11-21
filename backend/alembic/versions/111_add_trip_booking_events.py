"""Booking cancel / re-book / trip cancel from the app (trip_booking_events + trips.booking_status).

LP / RR-ops can now cancel a trip's truck booking, book another truck and cancel the trip, each sent to RR at once
(md/RR_BOOKING_CANCEL_RULES.md, user decisions 2026-11-20). Every such action is kept as one row of
trip_booking_events (who, when, reason, old / new truck, driver and owner, RR booking and purchase order).
trips.booking_status: NULL = booked as before (all existing rows), 'booking_cancelled' = no truck booked now.

Revision ID: 111
Revises: 110
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision = '111'
down_revision = '110'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('booking_status', sa.String(30), nullable=True))
    op.create_table(
        'trip_booking_events',
        sa.Column('id', UUID(as_uuid=True), primary_key=True),
        sa.Column('trip_id', UUID(as_uuid=True), sa.ForeignKey('trips.id', ondelete='CASCADE'), nullable=False),
        sa.Column('event', sa.String(30), nullable=False),
        sa.Column('reason', sa.Text, nullable=True),
        sa.Column('created_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('rr_trip_id', sa.String(24), nullable=True),
        sa.Column('rr_booking_id', sa.String(30), nullable=True),
        sa.Column('rr_purchase_order_no', sa.String(30), nullable=True),
        sa.Column('old_rr_vehicle_id', sa.String(24), nullable=True),
        sa.Column('old_vehicle_number', sa.String(30), nullable=True),
        sa.Column('old_rr_driver_id', sa.String(24), nullable=True),
        sa.Column('old_driver_name', sa.String(100), nullable=True),
        sa.Column('old_owner_rr_company_id', sa.String(24), nullable=True),
        sa.Column('new_rr_vehicle_id', sa.String(24), nullable=True),
        sa.Column('new_vehicle_number', sa.String(30), nullable=True),
        sa.Column('new_rr_driver_id', sa.String(24), nullable=True),
        sa.Column('new_driver_name', sa.String(100), nullable=True),
        sa.Column('new_owner_rr_company_id', sa.String(24), nullable=True),
        sa.Column('booking_amount', sa.Numeric(12, 2), nullable=True),
    )
    op.create_index('ix_trip_booking_events_trip_id', 'trip_booking_events', ['trip_id'])


def downgrade():
    op.drop_index('ix_trip_booking_events_trip_id', table_name='trip_booking_events')
    op.drop_table('trip_booking_events')
    op.drop_column('trips', 'booking_status')
