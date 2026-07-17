"""Add trip-level RR identity-doc file-id cache columns

Revision ID: 077
Revises: 076
Create Date: 2026-07-15

_sync_stage1_docs / get_identity_status / identity-override only ever looked
at a trip's LOCAL vehicle_id/driver_id foreign keys to find the Driver/Vehicle
row to cache each pushed doc's RR file id on. Every trip created via the RR
vehicle/driver picker (the current — and only — trip creation flow) sets
trip.rr_vehicle_id/rr_driver_id instead and never creates a local Driver/
Vehicle row, so those three functions silently no-op for virtually all trips:
Stage 1 docs have never actually synced to RR.

Fixing the entity resolution to fall back to trip.rr_vehicle_id/rr_driver_id
needs somewhere to cache each doc's RR file id for that fallback path (a
picker-selected vehicle/driver has no local row to cache on) — these mirror
the existing per-doc cache columns already on drivers/vehicles (073).
"""

from alembic import op
import sqlalchemy as sa

revision = '077'
down_revision = '076'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_dl_file_id',              sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_dl_back_file_id',         sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_aadhaar_file_id',         sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_aadhaar_back_file_id',    sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_pan_file_id',             sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_tax_declaration_file_id', sa.String(100), nullable=True))

    op.add_column('trips', sa.Column('rr_rc_file_id',       sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_puc_file_id',      sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_fitness_file_id',  sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_permit_file_id',   sa.String(100), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_permit_file_id')
    op.drop_column('trips', 'rr_fitness_file_id')
    op.drop_column('trips', 'rr_puc_file_id')
    op.drop_column('trips', 'rr_rc_file_id')

    op.drop_column('trips', 'rr_tax_declaration_file_id')
    op.drop_column('trips', 'rr_pan_file_id')
    op.drop_column('trips', 'rr_aadhaar_back_file_id')
    op.drop_column('trips', 'rr_aadhaar_file_id')
    op.drop_column('trips', 'rr_dl_back_file_id')
    op.drop_column('trips', 'rr_dl_file_id')
