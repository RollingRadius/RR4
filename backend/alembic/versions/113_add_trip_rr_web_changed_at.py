"""When RR web last changed one of our trips' booking facts (trips.rr_web_changed_at).

Our app now follows RR web (md/RR_TWO_WAY_SYNC_PLAN.md, user 2026-11-24): when the trip is cancelled, its booking
cancelled, another truck booked or the driver changed on RR web, our trip is updated with the same code as the app's
own cancel / re-book / reassign, and a row is written to trip_booking_events (no user = "RR web"). This time lets the
app show "Changed on RR web" and load that history only for trips that have one.

Revision ID: 113
Revises: 112
"""

import sqlalchemy as sa
from alembic import op

revision = '113'
down_revision = '112'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_web_changed_at', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_web_changed_at')
