"""Add s3_actual_invoice_value to trips

Revision ID: 079
Revises: 078
Create Date: 2026-07-23

At trip creation, invoice_value is a placeholder entered before the real
invoice exists. This field holds the real invoice amount, entered in Stage 3
once the actual invoice is uploaded, and is PATCHed to RR's parcel `cost`
field on sync — same pattern as s3_loaded_truck_weight_kg -> actual_kanta_weight.
"""

from alembic import op
import sqlalchemy as sa

revision = '079'
down_revision = '078'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s3_actual_invoice_value', sa.Numeric(12, 2), nullable=True))


def downgrade():
    op.drop_column('trips', 's3_actual_invoice_value')
