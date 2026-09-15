"""Add token_version to users

Revision ID: 095
Revises: 094
Create Date: 2026-09-09

Session-versioning for instant multi-device logout on password change.
JWT access tokens are stateless — a revoked refresh token alone only stops
FUTURE token renewal, leaving any already-issued access token valid on
other devices until it naturally expires (up to ACCESS_TOKEN_EXPIRE_MINUTES).

This column is embedded as a claim in every newly issued access token
(see create_access_token call sites) and checked on every authenticated
request (get_current_user) — a mismatch instantly rejects the token, even
if it hasn't technically expired yet. Bumped by the new in-profile
change-password flow so every existing token everywhere is invalidated
immediately, not just on next refresh.

default=1 so every already-issued token (which predates this claim and
therefore carries no token_version) is treated as version 1 and stays
valid until the user actually changes their password — this migration
itself does not force a mass logout.
"""

from alembic import op
import sqlalchemy as sa

revision = '095'
down_revision = '094'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('token_version', sa.Integer(), nullable=False, server_default='1'))


def downgrade():
    op.drop_column('users', 'token_version')
