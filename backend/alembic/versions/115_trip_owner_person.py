"""A truck owner who is a person with no company can be the trip's vehicle provider, as in RR web (user, 2026-11-24).

RR books such a truck with `participant_user_id` (potential_vehicles.vehicle_owner_user_id); RR's own create_trip takes a
user id as `vehicle_provider_id`. trips.transporter_rr_user_id holds that person (transporter_rr_company_id then stays
empty); the booking history keeps the old / new owner person too.

Revision ID: 115
Revises: 114
"""

import sqlalchemy as sa
from alembic import op

revision = '115'
down_revision = '114'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('transporter_rr_user_id', sa.String(24), nullable=True))
    op.add_column('trip_booking_events', sa.Column('old_owner_rr_user_id', sa.String(24), nullable=True))
    op.add_column('trip_booking_events', sa.Column('new_owner_rr_user_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('trip_booking_events', 'new_owner_rr_user_id')
    op.drop_column('trip_booking_events', 'old_owner_rr_user_id')
    op.drop_column('trips', 'transporter_rr_user_id')
