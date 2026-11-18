"""When the trip was created in RR (trips.rr_trip_created_at).

RR refuses a bilty date earlier than its trip's creation (get_and_update_bilty_number: "bilty date can not be less
than trip creation date"). The RR trip is created with ours, or later at Confirm Booking, so we keep the moment to
refuse such a date already when it is entered (user, 2026-11-14). Older trips fall back to trips.created_at.

Revision ID: 109
Revises: 108
"""

import sqlalchemy as sa
from alembic import op

revision = '109'
down_revision = '108'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_trip_created_at', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_trip_created_at')
