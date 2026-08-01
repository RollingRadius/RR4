"""Add refresh_tokens table for long-lived app session persistence

Revision ID: 085
Revises: 084
Create Date: 2026-07-31

Our own app's access token is short-lived (ACCESS_TOKEN_EXPIRE_MINUTES) and
the existing /api/user/refresh-token endpoint only reissues a fresh access
token while the current one is STILL valid -- it can't restore a session
that's actually expired (e.g. app not opened for a couple of days). This
adds a genuine long-lived, rotating refresh token so the app can stay
logged in across such gaps, matching how RR's own refresh tokens work.

Only a hash of the token is stored, never the raw value -- same principle
as password hashing, so a DB leak doesn't directly expose usable tokens.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '085'
down_revision = '084'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'refresh_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token_hash', sa.String(64), nullable=False, unique=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column('expires_at', sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column('revoked', sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index('ix_refresh_tokens_token_hash', 'refresh_tokens', ['token_hash'])
    op.create_index('ix_refresh_tokens_user_id', 'refresh_tokens', ['user_id'])
    op.create_foreign_key(
        'fk_refresh_tokens_user_id', 'refresh_tokens', 'users',
        ['user_id'], ['id'], ondelete='CASCADE',
    )


def downgrade():
    op.drop_table('refresh_tokens')
