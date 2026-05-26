"""add s3_loaded_weight_slip_url to trips

Revision ID: 059_s3_loaded_weight_slip
Revises: 058_rr_material_types
Create Date: 2026-05-26
"""
from alembic import op
import sqlalchemy as sa

revision = '059_s3_loaded_weight_slip'
down_revision = '058'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips',
        sa.Column('s3_loaded_weight_slip_url', sa.String(500), nullable=True)
    )


def downgrade():
    op.drop_column('trips', 's3_loaded_weight_slip_url')
