"""Add driver_tracking_stopped fields to trips

Revision ID: 097
Revises: 096
Create Date: 2026-09-14

Backs the "Stop Driver Tracking for this Trip" LP/RR-ops action: releases
a driver from this specific trip's assignment-lock and map-tracking early,
without touching the trip's own status/stage/current_stage data, so the
driver can immediately be assigned to a new trip. One-directional (no
"resume tracking" control) — driver_tracking_stopped_at/_by give a cheap
who/when audit trail, mirroring the approved_by/approved_at pattern already
used on user_organizations.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '097'
down_revision = '096'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('driver_tracking_stopped', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('trips', sa.Column('driver_tracking_stopped_at', sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('driver_tracking_stopped_by', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(
        'fk_trips_driver_tracking_stopped_by_users',
        'trips', 'users',
        ['driver_tracking_stopped_by'], ['id'],
        ondelete='SET NULL',
    )


def downgrade():
    op.drop_constraint('fk_trips_driver_tracking_stopped_by_users', 'trips', type_='foreignkey')
    op.drop_column('trips', 'driver_tracking_stopped_by')
    op.drop_column('trips', 'driver_tracking_stopped_at')
    op.drop_column('trips', 'driver_tracking_stopped')
