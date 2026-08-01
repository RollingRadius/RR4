"""Track the RR session's own 30-day expiry + a notified-once flag

Revision ID: 086
Revises: 085
Create Date: 2026-07-31

Only the derived access token's ~15min expiry (rr_token_expires_at) was
tracked before -- the underlying RR refresh token's real 30-day lifetime
was never tracked at all, so nothing could warn LP/RR-ops before it
silently lapsed. rr_expiry_notified_at prevents re-sending that warning
every time the condition is checked once it's already been sent today.
"""

from alembic import op
import sqlalchemy as sa

revision = '086'
down_revision = '085'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('organizations', sa.Column('rr_session_expires_at', sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('organizations', sa.Column('rr_expiry_notified_at', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('organizations', 'rr_expiry_notified_at')
    op.drop_column('organizations', 'rr_session_expires_at')
