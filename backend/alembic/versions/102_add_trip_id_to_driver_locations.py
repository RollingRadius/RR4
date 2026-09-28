"""Add trip_id to driver_locations

Revision ID: 102
Revises: 101
Create Date: 2026-09-16

Tags each GPS ping with the trip it was recorded during, so a trip's
actual travelled path (breadcrumb trail) can be queried on its own
instead of mixing together a driver's location history across every
trip they've ever run. Stamped automatically at ingestion time (see
tracking_service.py) by resolving the driver's currently active trip
using the same definition already used by trips.py's
_driver_has_open_trip — status ongoing, not stage-5-complete, not
driver_tracking_stopped. Nullable: pings with no matching active trip
(idle driver) simply go untagged.

driver_locations is RANGE-partitioned by month (see 010_add_gps_tracking.py);
ALTER TABLE ADD COLUMN / ADD CONSTRAINT on the partitioned parent propagates
to all existing partitions automatically (same approach already proven by
091_nullable_driver_location_org.py on this same table).
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '102'
down_revision = '101'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('driver_locations', sa.Column('trip_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(
        'fk_driver_locations_trip_id_trips',
        'driver_locations', 'trips',
        ['trip_id'], ['id'],
        ondelete='SET NULL',
    )
    op.create_index('idx_locations_trip_time', 'driver_locations', ['trip_id', 'timestamp'])


def downgrade():
    op.drop_index('idx_locations_trip_time', table_name='driver_locations')
    op.drop_constraint('fk_driver_locations_trip_id_trips', 'driver_locations', type_='foreignkey')
    op.drop_column('driver_locations', 'trip_id')
