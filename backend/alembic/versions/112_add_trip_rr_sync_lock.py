"""One RR sync per trip at a time (trips.rr_sync_lock_until).

Two syncs of the same trip at the same moment (two people pressing Sync) both PATCHed RR's parcel; RR refused one
with 412 (etag) and the trip showed a failed stage although RR had the data (found in the 2026-11-20 rehearsal).
A sync now claims the trip by setting this time a few minutes ahead (one short UPDATE, no connection held); a second
sync waits until it is free. It expires by itself, so a crashed sync cannot keep a trip blocked.

Revision ID: 112
Revises: 111
"""

import sqlalchemy as sa
from alembic import op

revision = '112'
down_revision = '111'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_sync_lock_until', sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_sync_lock_until')
