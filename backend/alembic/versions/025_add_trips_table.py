"""add trips table

Revision ID: 025
Revises: 024
Create Date: 2026-03-21
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '025'
down_revision = '024_remove_generic_owner_role'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'trips',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text('gen_random_uuid()')),
        sa.Column('trip_number', sa.String(30), nullable=False, unique=True),
        sa.Column('bilty_number', sa.String(50), nullable=True),

        sa.Column('origin', sa.String(200), nullable=False),
        sa.Column('origin_sub', sa.String(200), nullable=True),
        sa.Column('destination', sa.String(200), nullable=False),
        sa.Column('destination_sub', sa.String(200), nullable=True),

        sa.Column('load_item', sa.String(200), nullable=False),
        sa.Column('weight', sa.String(50), nullable=True),
        sa.Column('trip_amount', sa.Numeric(12, 2), nullable=True),
        sa.Column('invoice_number', sa.String(100), nullable=True),

        sa.Column('status', sa.String(20), nullable=False, server_default='ongoing'),

        sa.Column('organization_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('load_owner_org_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('organizations.id', ondelete='SET NULL'), nullable=True),
        sa.Column('vehicle_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('vehicles.id', ondelete='SET NULL'), nullable=True),
        sa.Column('driver_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('drivers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),

        sa.Column('start_date', sa.Date, nullable=True),
        sa.Column('end_date', sa.Date, nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True),
                  server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True),
                  server_default=sa.text('now()'), nullable=False),
    )

    op.create_index('ix_trips_trip_number', 'trips', ['trip_number'])
    op.create_index('ix_trips_organization_id', 'trips', ['organization_id'])
    op.create_index('ix_trips_load_owner_org_id', 'trips', ['load_owner_org_id'])
    op.create_index('ix_trips_vehicle_id', 'trips', ['vehicle_id'])
    op.create_index('ix_trips_status', 'trips', ['status'])

    # Status check constraint
    op.create_check_constraint(
        'ck_trips_status',
        'trips',
        "status IN ('pending', 'ongoing', 'completed', 'cancelled')"
    )


def downgrade():
    op.drop_table('trips')
