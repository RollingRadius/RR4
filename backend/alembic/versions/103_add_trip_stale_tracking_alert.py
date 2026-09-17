"""Add driver_tracking_stale_alert_sent_at to trips

Revision ID: 103
Revises: 102
Create Date: 2026-09-17

Throttle flag for the "trail gone stale" alert (see
services/tracking_watchdog.py): set the first time LP/RR-ops are notified
that an ongoing trip's GPS trail has stopped updating, so the periodic
check doesn't re-notify every cycle while it stays stale. Cleared once a
fresh location lands again, so a later stale period gets its own alert.
"""

from alembic import op
import sqlalchemy as sa

revision = '103'
down_revision = '102'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'trips',
        sa.Column('driver_tracking_stale_alert_sent_at', sa.TIMESTAMP(timezone=True), nullable=True),
    )


def downgrade():
    op.drop_column('trips', 'driver_tracking_stale_alert_sent_at')
