"""Add profile_picture_url to users

Revision ID: 094
Revises: 093
Create Date: 2026-09-09

Lets a user upload a profile picture, stored on disk under
uploads/profile_pictures/ (same disk+URL pattern already used for trip
documents, licenses, and logos — see UPLOAD_DIR bind-mount in
docker-compose.yml/docker-compose.prod.yml), with this column holding
just the served URL path.
"""

from alembic import op
import sqlalchemy as sa

revision = '094'
down_revision = '093'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('profile_picture_url', sa.String(500), nullable=True))


def downgrade():
    op.drop_column('users', 'profile_picture_url')
