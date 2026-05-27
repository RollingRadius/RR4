"""Add RR sync columns to trips table.

Revision ID: 057
Revises: 056
Create Date: 2026-05-23

Adds 13 nullable columns to support RR↔RR4 sync:
- City ObjectIds resolved at form-fill time
- Structured weight fields
- invoice_value required by RR
- RR trip/parcel cross-reference ids
- Sync state tracking
"""
from alembic import op
import sqlalchemy as sa

revision = '057'
down_revision = '056'
branch_labels = None
depends_on = None


def upgrade():
    # RR city ObjectIds (resolved via proxy at form-fill time)
    op.add_column('trips', sa.Column('origin_rr_city_id', sa.String(24), nullable=True))
    op.add_column('trips', sa.Column('destination_rr_city_id', sa.String(24), nullable=True))

    # RR material ObjectId (resolved from local material_types table)
    op.add_column('trips', sa.Column('material_rr_id', sa.String(24), nullable=True))

    # Structured weight (replaces free-text weight field — old field kept for compatibility)
    op.add_column('trips', sa.Column('weight_value', sa.Numeric(10, 3), nullable=True))
    op.add_column('trips', sa.Column('weight_unit', sa.String(10), nullable=True))  # KG | TONS | QUINTAL

    # Required by RR but missing in RR4 (short-term: defaults to trip_amount)
    op.add_column('trips', sa.Column('invoice_value', sa.Numeric(12, 2), nullable=True))

    # RR cross-reference
    op.add_column('trips', sa.Column('rr_trip_id', sa.String(24), nullable=True))
    op.add_column('trips', sa.Column('rr_trip_number', sa.String(30), nullable=True))

    # RR parcel reference (auto-created by RR alongside trip)
    op.add_column('trips', sa.Column('rr_parcel_id', sa.String(24), nullable=True))
    op.add_column('trips', sa.Column('rr_parcel_etag', sa.String(100), nullable=True))

    # Sync state tracking
    op.add_column('trips', sa.Column('rr_sync_status', sa.String(30), nullable=True, server_default='not_synced'))
    op.add_column('trips', sa.Column('rr_sync_error', sa.Text(), nullable=True))
    op.add_column('trips', sa.Column('rr_synced_at', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_synced_at')
    op.drop_column('trips', 'rr_sync_error')
    op.drop_column('trips', 'rr_sync_status')
    op.drop_column('trips', 'rr_parcel_etag')
    op.drop_column('trips', 'rr_parcel_id')
    op.drop_column('trips', 'rr_trip_number')
    op.drop_column('trips', 'rr_trip_id')
    op.drop_column('trips', 'invoice_value')
    op.drop_column('trips', 'weight_unit')
    op.drop_column('trips', 'weight_value')
    op.drop_column('trips', 'material_rr_id')
    op.drop_column('trips', 'destination_rr_city_id')
    op.drop_column('trips', 'origin_rr_city_id')
