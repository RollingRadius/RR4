"""add stage 3 bilty and material doc columns

Stores file URL paths for bilty and material documents uploaded during
Stage 3 of the trip intake process.

Revision ID: 033
Revises: 032
Create Date: 2026-03-25
"""

from alembic import op
import sqlalchemy as sa

revision = '033'
down_revision = '032'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column(
        's3_bilty_url', sa.String(500), nullable=True
    ))
    op.add_column('trips', sa.Column(
        's3_material_doc_urls', sa.Text(), nullable=True
    ))


def downgrade() -> None:
    op.drop_column('trips', 's3_material_doc_urls')
    op.drop_column('trips', 's3_bilty_url')
