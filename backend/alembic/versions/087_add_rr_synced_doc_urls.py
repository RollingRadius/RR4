"""Track the local doc URL last pushed to RR per doc slot on a trip

Revision ID: 087
Revises: 086
Create Date: 2026-08-01

Stage 1 doc sync only ever filled in a side RR was missing (never replaced
an existing side), so re-uploading a corrected DL/RC/etc. photo and
re-syncing never pushed the new file to RR. rr_synced_doc_urls records,
per doc slot, the local URL last successfully pushed for THIS trip — sync
now compares the trip's current s1_* URL against that record and replaces
RR's copy whenever it differs, converging RR to match what's on the trip
every time either of the two sync buttons is used.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '087'
down_revision = '086'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_synced_doc_urls', JSONB, nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_synced_doc_urls')
