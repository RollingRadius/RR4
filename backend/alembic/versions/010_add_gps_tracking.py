"""add gps tracking

Revision ID: 010_add_gps_tracking
Revises: 009_create_vendors_and_expenses
Create Date: 2026-02-02 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '010_add_gps_tracking'
down_revision: Union[str, None] = '009_create_vendors_and_expenses'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add tracking_enabled column to drivers table
    op.add_column('drivers', sa.Column('tracking_enabled', sa.Boolean(), nullable=False, server_default='false'))

    # Create driver_locations table (partitioned by month)
    # Note: Primary key must include partition key (timestamp) for partitioned tables
    op.execute("""
        CREATE TABLE driver_locations (
            id UUID NOT NULL DEFAULT gen_random_uuid(),
            driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
            organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
            latitude NUMERIC(10,8) NOT NULL,
            longitude NUMERIC(11,8) NOT NULL,
            accuracy FLOAT,
            altitude FLOAT,
            speed FLOAT,
            heading FLOAT,
            battery_level INTEGER CHECK (battery_level BETWEEN 0 AND 100),
            is_mock_location BOOLEAN DEFAULT false,
            timestamp TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            PRIMARY KEY (id, timestamp),
            CONSTRAINT valid_latitude CHECK (latitude BETWEEN -90 AND 90),
            CONSTRAINT valid_longitude CHECK (longitude BETWEEN -180 AND 180)
        ) PARTITION BY RANGE (timestamp)
    """)

    # Create initial monthly partitions (current month + 3 months ahead)
    op.execute("""
        CREATE TABLE driver_locations_2026_02 PARTITION OF driver_locations
            FOR VALUES FROM ('2026-02-01') TO ('2026-03-01')
    """)

    op.execute("""
        CREATE TABLE driver_locations_2026_03 PARTITION OF driver_locations
            FOR VALUES FROM ('2026-03-01') TO ('2026-04-01')
    """)

    op.execute("""
        CREATE TABLE driver_locations_2026_04 PARTITION OF driver_locations
            FOR VALUES FROM ('2026-04-01') TO ('2026-05-01')
    """)

    op.execute("""
        CREATE TABLE driver_locations_2026_05 PARTITION OF driver_locations
            FOR VALUES FROM ('2026-05-01') TO ('2026-06-01')
    """)

    # Create indexes on driver_locations
    op.execute("""
        CREATE INDEX idx_locations_driver_time ON driver_locations (driver_id, timestamp DESC)
    """)

    op.execute("""
        CREATE INDEX idx_locations_org_time ON driver_locations (organization_id, timestamp DESC)
    """)

    op.execute("""
        CREATE INDEX idx_locations_timestamp ON driver_locations (timestamp)
    """)

    # Create geofence_events table
    op.create_table(
        'geofence_events',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('driver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('drivers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('zone_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('zones.id', ondelete='CASCADE'), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('event_type', sa.String(10), nullable=False),
        sa.Column('location_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('latitude', sa.Numeric(10, 8), nullable=False),
        sa.Column('longitude', sa.Numeric(11, 8), nullable=False),
        sa.Column('timestamp', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.CheckConstraint("event_type IN ('enter', 'exit')", name='check_event_type'),
        sa.CheckConstraint('latitude BETWEEN -90 AND 90', name='check_valid_latitude'),
        sa.CheckConstraint('longitude BETWEEN -180 AND 180', name='check_valid_longitude')
    )

    # Create indexes on geofence_events
    op.create_index('idx_geofence_driver_time', 'geofence_events', ['driver_id', sa.text('timestamp DESC')])
    op.create_index('idx_geofence_zone_time', 'geofence_events', ['zone_id', sa.text('timestamp DESC')])
    op.create_index('idx_geofence_org_time', 'geofence_events', ['organization_id', sa.text('timestamp DESC')])

    # Create route_optimizations table
    op.create_table(
        'route_optimizations',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('waypoints', postgresql.JSONB, nullable=False),
        sa.Column('optimized_route', postgresql.JSONB, nullable=True),
        sa.Column('total_distance', sa.Float, nullable=True),
        sa.Column('estimated_duration', sa.Integer, nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('status', sa.String(20), server_default='draft', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.CheckConstraint("status IN ('draft', 'active', 'completed')", name='check_status')
    )

    # Create indexes on route_optimizations
    op.create_index('idx_routes_org', 'route_optimizations', ['organization_id'])
    op.create_index('idx_routes_created_by', 'route_optimizations', ['created_by'])
    op.create_index('idx_routes_status', 'route_optimizations', ['status'])


def downgrade() -> None:
    # Drop route_optimizations table and indexes
    op.drop_index('idx_routes_status', table_name='route_optimizations')
    op.drop_index('idx_routes_created_by', table_name='route_optimizations')
    op.drop_index('idx_routes_org', table_name='route_optimizations')
    op.drop_table('route_optimizations')

    # Drop geofence_events table and indexes
    op.drop_index('idx_geofence_org_time', table_name='geofence_events')
    op.drop_index('idx_geofence_zone_time', table_name='geofence_events')
    op.drop_index('idx_geofence_driver_time', table_name='geofence_events')
    op.drop_table('geofence_events')

    # Drop driver_locations partitions and table
    op.execute("DROP TABLE IF EXISTS driver_locations_2026_02")
    op.execute("DROP TABLE IF EXISTS driver_locations_2026_03")
    op.execute("DROP TABLE IF EXISTS driver_locations_2026_04")
    op.execute("DROP TABLE IF EXISTS driver_locations_2026_05")
    op.execute("DROP TABLE IF EXISTS driver_locations CASCADE")

    # Remove tracking_enabled column from drivers
    op.drop_column('drivers', 'tracking_enabled')
