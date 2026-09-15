"""Add last-known permission status + reminder rate-limit to drivers

Revision ID: 098
Revises: 097
Create Date: 2026-09-14

Backs the "turn on location" push reminder: the backend previously had zero
visibility into a driver's actual OS location-permission state. The app now
self-reports it (PUT /api/v1/tracking/my-permission-status), and
driver_link_service.py uses it to decide whether to nudge the driver on
trip assignment and via a rate-limited follow-up on the driver dashboard's
30s poll.
"""

from alembic import op
import sqlalchemy as sa

revision = '098'
down_revision = '097'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('drivers', sa.Column('last_permission_status', sa.String(length=20), nullable=True))
    op.add_column('drivers', sa.Column('last_permission_checked_at', sa.DateTime(), nullable=True))
    op.add_column('drivers', sa.Column('last_location_reminder_sent_at', sa.DateTime(), nullable=True))


def downgrade():
    op.drop_column('drivers', 'last_location_reminder_sent_at')
    op.drop_column('drivers', 'last_permission_checked_at')
    op.drop_column('drivers', 'last_permission_status')
