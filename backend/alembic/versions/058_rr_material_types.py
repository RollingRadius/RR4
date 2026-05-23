"""Create material_types table for RR sync.

Revision ID: 058
Revises: 057
Create Date: 2026-05-23

Stores the list of cargo material types seeded from RR's material_types
collection. Used for autocomplete in the trip form and resolving
rr_material_id at form-fill time (zero runtime API calls to RR).
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '058'
down_revision = '057'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'material_types',
        sa.Column('id', UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text('gen_random_uuid()')),
        sa.Column('name', sa.String(100), nullable=False, unique=True),
        sa.Column('rr_material_id', sa.String(24), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True),
                  server_default=sa.text('NOW()'), nullable=False),
    )


def downgrade():
    op.drop_table('material_types')
