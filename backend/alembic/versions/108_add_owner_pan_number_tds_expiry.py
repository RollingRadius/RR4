"""Truck owner's PAN number and tax declaration (TDS) valid-till date in Stage 1.

RR web needs the owner's PAN number with the PAN photo (company "PAN" / person "PAN Card" `number`) and uses the
tax declaration slip's `expiry_date` to decide TDS. Both are kept on the trip and on the owner's stored document
(owner_documents.number / expiry_date) and sent to the booking owner in RR on the manual sync.
Plan: md/RR_FIELD_ALIGNMENT.md (G1, G2-TDS).

Revision ID: 108
Revises: 107
"""

import sqlalchemy as sa
from alembic import op

revision = '108'
down_revision = '107'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s1_pan_number', sa.String(10), nullable=True))
    op.add_column('trips', sa.Column('s1_tax_declaration_expiry', sa.Date(), nullable=True))


def downgrade():
    op.drop_column('trips', 's1_tax_declaration_expiry')
    op.drop_column('trips', 's1_pan_number')
