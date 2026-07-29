"""Add s3_invoice_number to trips

Revision ID: 082
Revises: 081
Create Date: 2026-07-30

Invoice number off the same document as s3_actual_invoice_value, entered in
Stage 3 alongside the invoice value — PATCHed to RR's parcel
documents.consignor_invoice.number field on sync.
"""

from alembic import op
import sqlalchemy as sa

revision = '082'
down_revision = '081'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s3_invoice_number', sa.String(100), nullable=True))


def downgrade():
    op.drop_column('trips', 's3_invoice_number')
