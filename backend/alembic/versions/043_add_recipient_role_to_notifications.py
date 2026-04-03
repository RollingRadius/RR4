"""Add recipient_role to notifications (creates table if missing)

Revision ID: 043
Revises: 042
Create Date: 2026-04-03
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '043'
down_revision = '042'
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = inspector.get_table_names()

    if 'notifications' not in tables:
        # Table was never created (migration 034 was applied before notifications
        # table creation was added to it). Create it now with recipient_role included.
        op.create_table(
            'notifications',
            sa.Column('id',               UUID(as_uuid=True), primary_key=True,
                      server_default=sa.text('gen_random_uuid()')),
            sa.Column('recipient_org_id', UUID(as_uuid=True), nullable=False),
            sa.Column('recipient_role',   sa.String(50),  nullable=True),
            sa.Column('trip_id',          UUID(as_uuid=True), nullable=True),
            sa.Column('type',             sa.String(50),  nullable=False),
            sa.Column('title',            sa.String(200), nullable=False),
            sa.Column('body',             sa.Text(),      nullable=False),
            sa.Column('is_read',          sa.Boolean(),   nullable=False,
                      server_default='false'),
            sa.Column('created_at',       sa.TIMESTAMP(timezone=True),
                      server_default=sa.text('now()'), nullable=False),
        )
        op.create_index('ix_notifications_recipient_org_id', 'notifications', ['recipient_org_id'])
        op.create_index('ix_notifications_trip_id',          'notifications', ['trip_id'])
    else:
        # Table exists — just add the new column if it's not already there.
        columns = [c['name'] for c in inspector.get_columns('notifications')]
        if 'recipient_role' not in columns:
            op.add_column(
                'notifications',
                sa.Column('recipient_role', sa.String(50), nullable=True),
            )


def downgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = inspector.get_table_names()
    if 'notifications' in tables:
        columns = [c['name'] for c in inspector.get_columns('notifications')]
        if 'recipient_role' in columns:
            op.drop_column('notifications', 'recipient_role')
