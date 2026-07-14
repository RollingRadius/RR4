"""Add dedicated per-stage sync status columns for Stage 2 (loading slip)

Revision ID: 075
Revises: 074
Create Date: 2026-07-14

Stage 2 previously shared the legacy trips.rr_sync_status column with stages
3 and 5 — whichever stage's background sync finished last would overwrite it,
masking an earlier stage's failure with a later stage's success (e.g. Stage 2's
loading-slip sync failing silently, then Stage 5's POD sync succeeding and
stomping the shared column back to a "done" value). Stages 1/3/4/5 already
have their own dedicated status columns; this gives Stage 2 the same.
"""

from alembic import op
import sqlalchemy as sa

revision = '075'
down_revision = '074'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_s2_sync_status', sa.String(30),
                                      nullable=False, server_default='not_synced'))
    op.add_column('trips', sa.Column('rr_s2_synced_at',   sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('rr_s2_sync_error',  sa.Text(),                    nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_s2_sync_error')
    op.drop_column('trips', 'rr_s2_synced_at')
    op.drop_column('trips', 'rr_s2_sync_status')
