"""Replace Stage 3 Bilty upload with E-way Bill

Revision ID: 078
Revises: 077
Create Date: 2026-07-16

Stage 3's "Bilty" upload only ever fed RR's documents.bilty_date (a derived
date, not a real stored document) since RR's actual mobile/web client never
writes documents.bilty as a raw string either. RR's real per-trip document
field for this step is documents.eway_bill (number + photos + issue_date +
expiry_date) on the parcels resource. s3_bilty_url is left in place (unused
going forward) — old data isn't touched.
"""

from alembic import op
import sqlalchemy as sa

revision = '078'
down_revision = '077'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s3_eway_bill_number', sa.String(50), nullable=True))
    op.add_column('trips', sa.Column('s3_eway_bill_url', sa.String(500), nullable=True))
    op.add_column('trips', sa.Column('s3_eway_bill_issue_date', sa.TIMESTAMP(timezone=True), nullable=True))
    op.add_column('trips', sa.Column('s3_eway_bill_expiry_date', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 's3_eway_bill_expiry_date')
    op.drop_column('trips', 's3_eway_bill_issue_date')
    op.drop_column('trips', 's3_eway_bill_url')
    op.drop_column('trips', 's3_eway_bill_number')
