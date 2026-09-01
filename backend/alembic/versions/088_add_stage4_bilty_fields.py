"""Add Stage 4 Bilty Number + manual Bilty upload fields

Revision ID: 088
Revises: 087
Create Date: 2026-08-07

RR's own web app recently added a manual Bilty upload to its parcel flow,
alongside its existing "assign a Bilty Number" mechanism (documents.bilty on
the parcels resource, set via RR's get_and_update_bilty_number endpoint) and
a separate documents.manual_bilty.photos[].manual_photo file field. RR's own
"Generate Bilty" dialog also has an optional backdating date field (neither
field is required there either — label literally says "Bilty Number (If
Any)"). All three are captured on Stage 4 ("Exit") in RR4 and synced into
RR's parcel record.
"""

from alembic import op
import sqlalchemy as sa

revision = '088'
down_revision = '087'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s4_bilty_number', sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('s4_bilty_url', sa.String(500), nullable=True))
    op.add_column('trips', sa.Column('s4_bilty_date', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 's4_bilty_date')
    op.drop_column('trips', 's4_bilty_url')
    op.drop_column('trips', 's4_bilty_number')
