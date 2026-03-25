"""add stage 4 columns and notifications table

Revision ID: 034
Revises: 033
Create Date: 2026-03-25
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '034'
down_revision = '033'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Stage 4 columns on trips ──────────────────────────────────────────────
    op.add_column('trips', sa.Column('s4_truck_moved',       sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s4_security_verified', sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s4_bilty_checked',     sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s4_weight_checked',    sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s4_material_checked',  sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s4_completed_at',  sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s4_notified_at',   sa.TIMESTAMP(timezone=True), nullable=True))

    # ── Notifications table ───────────────────────────────────────────────────
    op.create_table(
        'notifications',
        sa.Column('id',               UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('recipient_org_id', UUID(as_uuid=True), nullable=False, index=True),
        sa.Column('trip_id',          UUID(as_uuid=True), nullable=True),
        sa.Column('type',             sa.String(50),  nullable=False),
        sa.Column('title',            sa.String(200), nullable=False),
        sa.Column('body',             sa.Text(),      nullable=False),
        sa.Column('is_read',          sa.Boolean(),   nullable=False, server_default='false'),
        sa.Column('created_at',       sa.TIMESTAMP(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index('ix_notifications_recipient_org_id', 'notifications', ['recipient_org_id'])
    op.create_index('ix_notifications_trip_id',          'notifications', ['trip_id'])


def downgrade() -> None:
    op.drop_index('ix_notifications_trip_id',          table_name='notifications')
    op.drop_index('ix_notifications_recipient_org_id', table_name='notifications')
    op.drop_table('notifications')

    op.drop_column('trips', 's4_notified_at')
    op.drop_column('trips', 's4_completed_at')
    op.drop_column('trips', 's4_material_checked')
    op.drop_column('trips', 's4_weight_checked')
    op.drop_column('trips', 's4_bilty_checked')
    op.drop_column('trips', 's4_security_verified')
    op.drop_column('trips', 's4_truck_moved')
