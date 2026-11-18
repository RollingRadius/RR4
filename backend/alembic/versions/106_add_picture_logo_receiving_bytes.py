"""Add database byte columns for profile pictures, logos and receiving documents

Revision ID: 106
Revises: 105
Create Date: 2026-11-05

The three uploads that live outside the document tables keep their URL column and
get nullable byte columns next to it, so the bytes can be stored in the database
and served from the same /uploads/... URLs. Structure only: nothing is copied and
no file is touched. STORAGE EXTERNAL because the files are already-compressed images.
Plan: md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md.
"""

from alembic import op
import sqlalchemy as sa

revision = '106'
down_revision = '105'
branch_labels = None
depends_on = None

# table -> (bytes column, content-type column, checksum column, extra columns)
ADDED = {
    'users': ('profile_picture_content', 'profile_picture_content_type', 'profile_picture_sha256', []),
    'organization_branding': ('logo_content', 'logo_content_type', 'logo_sha256', []),
    'receiving_documents': ('content', 'content_type', 'sha256', [sa.Column('size_bytes', sa.Integer(), nullable=True)]),
}


def upgrade():
    for table, (content, content_type, sha256, extra) in ADDED.items():
        op.add_column(table, sa.Column(content, sa.LargeBinary(), nullable=True))
        op.add_column(table, sa.Column(content_type, sa.String(100), nullable=True))
        op.add_column(table, sa.Column(sha256, sa.String(64), nullable=True))
        for column in extra:
            op.add_column(table, column)
        op.execute(f'ALTER TABLE {table} ALTER COLUMN {content} SET STORAGE EXTERNAL')


def downgrade():
    for table, (content, content_type, sha256, extra) in ADDED.items():
        for column in extra:
            op.drop_column(table, column.name)
        op.drop_column(table, sha256)
        op.drop_column(table, content_type)
        op.drop_column(table, content)
