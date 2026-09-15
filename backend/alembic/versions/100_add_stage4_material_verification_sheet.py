"""Add Stage 4 Material Verification Sheet upload

Revision ID: 100
Revises: 099
Create Date: 2026-09-15

RR4-only document for now (not synced to RR yet — planned as a follow-up).
Sits alongside the existing s4_bilty_* fields in the "Diesel Receipt and
Bilty" section of Stage 4.
"""

from alembic import op
import sqlalchemy as sa

revision = '100'
down_revision = '099'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s4_material_verification_url', sa.String(500), nullable=True))


def downgrade():
    op.drop_column('trips', 's4_material_verification_url')
