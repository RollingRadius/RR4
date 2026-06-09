"""Add vehicle_number, rr_vehicle_id, rr_driver_id to trips

Revision ID: 068
Revises: 067
Create Date: 2026-06-09

vehicle_number  — manually entered registration number (e.g. UP32AB1234).
rr_vehicle_id   — RR MongoDB vehicle ObjectId selected via the picker; used
                  as `vehicle_id` in POST /create_trip without any extra lookup.
rr_driver_id    — RR MongoDB user ObjectId for the driver (from vehicle crew);
                  used as `driver_id` in POST /create_trip without any extra lookup.
"""

from alembic import op
import sqlalchemy as sa

revision = '068'
down_revision = '067'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('vehicle_number', sa.String(30), nullable=True))
    op.add_column('trips', sa.Column('rr_vehicle_id',  sa.String(24), nullable=True))
    op.add_column('trips', sa.Column('rr_driver_id',   sa.String(24), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_driver_id')
    op.drop_column('trips', 'rr_vehicle_id')
    op.drop_column('trips', 'vehicle_number')
