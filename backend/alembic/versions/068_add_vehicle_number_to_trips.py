"""Add vehicle_number and rr_vehicle_id to trips

Revision ID: 068
Revises: 067
Create Date: 2026-06-09

vehicle_number  — manually entered registration number (e.g. UP32AB1234) stored
                  on the trip when no fleet vehicle is linked.
rr_vehicle_id   — RR MongoDB vehicle ObjectId selected directly via the
                  vehicle-provider picker in the +new trip form; used as
                  `vehicle_id` in POST /create_trip without any extra lookup.
"""

from alembic import op
import sqlalchemy as sa

revision = '068'
down_revision = '067'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('vehicle_number',  sa.String(30), nullable=True))
    op.add_column('trips', sa.Column('rr_vehicle_id',   sa.String(24), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_vehicle_id')
    op.drop_column('trips', 'vehicle_number')
