"""Add recipient_user_id to notifications, make recipient_org_id nullable

Revision ID: 050
Revises: 049
Create Date: 2026-05-02
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '050'
down_revision = '049'
branch_labels = None
depends_on = None


def upgrade():
    # 1. Add recipient_user_id column (nullable UUID)
    op.add_column('notifications', sa.Column(
        'recipient_user_id',
        postgresql.UUID(as_uuid=True),
        nullable=True
    ))

    # 2. Make recipient_org_id nullable (transporters have no org)
    op.alter_column('notifications', 'recipient_org_id', nullable=True)

    # 3. Add index on recipient_user_id for fast lookup
    op.create_index('ix_notifications_recipient_user_id', 'notifications', ['recipient_user_id'])


def downgrade():
    op.drop_index('ix_notifications_recipient_user_id', table_name='notifications')
    op.drop_column('notifications', 'recipient_user_id')
    op.alter_column('notifications', 'recipient_org_id', nullable=False)
