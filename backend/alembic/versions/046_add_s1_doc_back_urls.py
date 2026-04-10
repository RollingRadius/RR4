"""Add back-side URL columns for Stage 1 driving licence and Aadhaar.

Revision ID: 046
Revises: 045
"""

from alembic import op
import sqlalchemy as sa

revision = "046"
down_revision = "045"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("trips", sa.Column("s1_driving_license_back_url", sa.Text, nullable=True))
    op.add_column("trips", sa.Column("s1_aadhaar_back_url",         sa.Text, nullable=True))


def downgrade():
    op.drop_column("trips", "s1_driving_license_back_url")
    op.drop_column("trips", "s1_aadhaar_back_url")
