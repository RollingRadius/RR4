"""Add Stage 4 Bilty Number synced-lock flag

Revision ID: 089
Revises: 088
Create Date: 2026-08-07

RR's own get_and_update_bilty_number endpoint is a strict one-time assignment
per parcel — once a parcel has a bilty number set, RR rejects every later
call for that parcel, even with a different number (confirmed by reading
rrbc-api/app/trips/app.py:3014-3015). So once RR4's Bilty Number sync
succeeds, later edits from RR4 would never actually reach RR. Rather than
silently letting the user think a re-edit worked, s4_bilty_synced marks the
field as locked in the UI the moment the first sync succeeds — matching
RR's own one-time-assignment behavior instead of masking it.
"""

from alembic import op
import sqlalchemy as sa

revision = '089'
down_revision = '088'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s4_bilty_synced', sa.Boolean(), nullable=True, server_default='false'))


def downgrade():
    op.drop_column('trips', 's4_bilty_synced')
