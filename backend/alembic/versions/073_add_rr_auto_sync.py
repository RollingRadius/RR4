"""Add RR auto-sync columns: org-level RR token persistence + per-stage sync tracking on trips

Revision ID: 073
Revises: 072
Create Date: 2026-07-14

organizations: persisted RR access/refresh token (from LP/RR-ops login) so background
stage-sync tasks can silently refresh and reuse it without a human re-logging in.

trips: per-stage sync status/timestamp/error for stages 1, 3, 4, 5 (stage 2 keeps using
the existing generic rr_sync_status/rr_synced_at/rr_sync_error columns).

drivers / vehicles: RR file ids for each Stage 1 identity doc already pushed to RR
(mirrors the existing rr_loading_slip_file_id pattern on trips) — lets _sync_stage1_docs
skip straight past docs it already pushed instead of always GETing RR's identities[] first.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '073'
down_revision = '072'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('organizations', sa.Column('rr_access_token',      sa.Text(),      nullable=True))
    op.add_column('organizations', sa.Column('rr_refresh_token',     sa.Text(),      nullable=True))
    op.add_column('organizations', sa.Column('rr_token_expires_at',  sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('organizations', sa.Column('rr_token_updated_by',  postgresql.UUID(as_uuid=True),
                                              sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True))

    for stage in ('s1', 's3', 's4', 's5'):
        op.add_column('trips', sa.Column(f'rr_{stage}_sync_status', sa.String(30),
                                          nullable=False, server_default='not_synced'))
        op.add_column('trips', sa.Column(f'rr_{stage}_synced_at',   sa.TIMESTAMP(timezone=True), nullable=True))
        op.add_column('trips', sa.Column(f'rr_{stage}_sync_error',  sa.Text(),                    nullable=True))

    op.add_column('drivers', sa.Column('rr_dl_file_id',             sa.String(100), nullable=True))
    op.add_column('drivers', sa.Column('rr_dl_back_file_id',        sa.String(100), nullable=True))
    op.add_column('drivers', sa.Column('rr_aadhaar_file_id',        sa.String(100), nullable=True))
    op.add_column('drivers', sa.Column('rr_aadhaar_back_file_id',   sa.String(100), nullable=True))
    op.add_column('drivers', sa.Column('rr_pan_file_id',            sa.String(100), nullable=True))
    op.add_column('drivers', sa.Column('rr_tax_declaration_file_id', sa.String(100), nullable=True))

    op.add_column('vehicles', sa.Column('rr_rc_file_id',       sa.String(100), nullable=True))
    op.add_column('vehicles', sa.Column('rr_puc_file_id',      sa.String(100), nullable=True))
    op.add_column('vehicles', sa.Column('rr_fitness_file_id',  sa.String(100), nullable=True))
    op.add_column('vehicles', sa.Column('rr_permit_file_id',   sa.String(100), nullable=True))


def downgrade():
    op.drop_column('vehicles', 'rr_permit_file_id')
    op.drop_column('vehicles', 'rr_fitness_file_id')
    op.drop_column('vehicles', 'rr_puc_file_id')
    op.drop_column('vehicles', 'rr_rc_file_id')

    op.drop_column('drivers', 'rr_tax_declaration_file_id')
    op.drop_column('drivers', 'rr_pan_file_id')
    op.drop_column('drivers', 'rr_aadhaar_back_file_id')
    op.drop_column('drivers', 'rr_aadhaar_file_id')
    op.drop_column('drivers', 'rr_dl_back_file_id')
    op.drop_column('drivers', 'rr_dl_file_id')

    for stage in ('s1', 's3', 's4', 's5'):
        op.drop_column('trips', f'rr_{stage}_sync_error')
        op.drop_column('trips', f'rr_{stage}_synced_at')
        op.drop_column('trips', f'rr_{stage}_sync_status')

    op.drop_column('organizations', 'rr_token_updated_by')
    op.drop_column('organizations', 'rr_token_expires_at')
    op.drop_column('organizations', 'rr_refresh_token')
    op.drop_column('organizations', 'rr_access_token')
