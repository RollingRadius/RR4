"""Scope on refresh tokens (refresh_tokens.scope) for the tracking-only tracker login.

The driver app's background tracker gets its own login (POST /api/auth/tracking-session). It used to have the
driver's full power for 90 days and stayed on the phone after logout. Now it is marked 'tracking': it may only
upload GPS points and renew itself, and the mark is kept on every renewal (security audit V-39, user 2026-11-17).
NULL = a normal full login, so all existing rows keep working unchanged.

Revision ID: 110
Revises: 109
"""

import sqlalchemy as sa
from alembic import op

revision = '110'
down_revision = '109'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('refresh_tokens', sa.Column('scope', sa.String(20), nullable=True))


def downgrade():
    op.drop_column('refresh_tokens', 'scope')
