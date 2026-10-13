"""Add trip_trail_gaps table

Revision ID: 104
Revises: 103
Create Date: 2026-10-13

Caches the road route drawn across a "location was off" gap in a driver's
trail (last ping before the gap -> first ping after it), so each gap is
routed once instead of on every trail view. driver_locations is partitioned,
so the ping ids are plain UUIDs without a foreign key.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '104'
down_revision = '103'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'trip_trail_gaps',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('trip_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('trips.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_ping_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('to_ping_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('route_points', postgresql.JSONB(), nullable=True),
        sa.Column('distance_km', sa.Float(), nullable=True),
        sa.Column('provider', sa.String(20), nullable=False),
        sa.Column('mode', sa.String(20), nullable=False),
        sa.Column('status', sa.String(10), nullable=False),
        sa.Column('attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('next_retry_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint('trip_id', 'from_ping_id', 'to_ping_id', name='uq_trip_trail_gaps_pair'),
    )
    op.create_index('ix_trip_trail_gaps_trip_id', 'trip_trail_gaps', ['trip_id'])


def downgrade():
    op.drop_table('trip_trail_gaps')
