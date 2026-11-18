"""Index the URL columns the /uploads handler looks files up by

Revision ID: 107
Revises: 106
Create Date: 2026-11-06

The four document tables already have a unique index on url_path. The profile
picture, receiving document and logo URLs live on other tables and had no index, so
serving them from the database would scan the table on every request.
"""

from alembic import op
import sqlalchemy as sa

revision = '107'
down_revision = '106'
branch_labels = None
depends_on = None


def upgrade():
    op.create_index('ix_users_profile_picture_url', 'users', ['profile_picture_url'],
                    postgresql_where=sa.text('profile_picture_url IS NOT NULL'))
    op.create_index('ix_receiving_documents_file_url', 'receiving_documents', ['file_url'])
    op.create_index('ix_organization_branding_logo_url', 'organization_branding', ['logo_url'],
                    postgresql_where=sa.text('logo_url IS NOT NULL'))


def downgrade():
    op.drop_index('ix_organization_branding_logo_url', table_name='organization_branding')
    op.drop_index('ix_receiving_documents_file_url', table_name='receiving_documents')
    op.drop_index('ix_users_profile_picture_url', table_name='users')
