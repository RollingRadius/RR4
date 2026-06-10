"""Add partial unique indexes on trips.rr_trip_id and trips.rr_trip_number

Revision ID: 072
Revises: 071
Create Date: 2026-06-10

Two RR4 trips must never link to the same RR trip. Partial unique indexes
(WHERE NOT NULL) allow multiple trips to have NULL but enforce uniqueness
across all non-null values.
"""

from alembic import op

revision = '072'
down_revision = '071'
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        'uq_trips_rr_trip_id',
        'trips',
        ['rr_trip_id'],
        unique=True,
        postgresql_where='rr_trip_id IS NOT NULL',
    )
    op.create_index(
        'uq_trips_rr_trip_number',
        'trips',
        ['rr_trip_number'],
        unique=True,
        postgresql_where='rr_trip_number IS NOT NULL',
    )


def downgrade():
    op.drop_index('uq_trips_rr_trip_number', table_name='trips')
    op.drop_index('uq_trips_rr_trip_id', table_name='trips')
