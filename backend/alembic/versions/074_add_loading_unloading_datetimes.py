"""Add loading/unloading datetime fields to trips

Revision ID: 074
Revises: 073
Create Date: 2026-07-14

Maps onto RR's parcels.loading / parcels.unloading schema
(D:/RR/rrbc-api/app/settings.py:5397-5520):
  loading:   truck_reach_datetime, start_datetime, end_datetime
  unloading: truck_reach_datetime, start_datetime, end_datetime

Stage 3 (Truck Arrival) captures loading reach + start; Stage 4 (Truck Exit)
captures loading end (vehicle exit); Stage 5 (Unloading) captures all three
unloading timestamps since there's no separate arrival-at-destination stage.
"""

from alembic import op
import sqlalchemy as sa

revision = '074'
down_revision = '073'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s3_vehicle_reach_datetime',   sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s3_loading_start_datetime',   sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s4_vehicle_exit_datetime',    sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s5_vehicle_reach_datetime',   sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s5_unloading_start_datetime', sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s5_unloading_end_datetime',   sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 's5_unloading_end_datetime')
    op.drop_column('trips', 's5_unloading_start_datetime')
    op.drop_column('trips', 's5_vehicle_reach_datetime')
    op.drop_column('trips', 's4_vehicle_exit_datetime')
    op.drop_column('trips', 's3_loading_start_datetime')
    op.drop_column('trips', 's3_vehicle_reach_datetime')
