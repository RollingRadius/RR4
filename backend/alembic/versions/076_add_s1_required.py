"""Add trips.s1_required — lets LP/RR-ops make Stage 1 optional for FE per trip

Revision ID: 076
Revises: 075
Create Date: 2026-07-15

LP/RR-ops can check on RR web whether the selected driver/vehicle already has
KYC docs on file, and if so, skip asking the field executive to re-fill Stage
1 for that specific trip. Defaults to True (required) so existing/new trips
are unaffected unless explicitly toggled off. This is a live, per-trip switch
(not a one-time decision) — LP/RR-ops can flip it at any point while the trip
is active; it only ever gates FE's access to Stage 1, never LP/RR-ops'.
"""

from alembic import op
import sqlalchemy as sa

revision = '076'
down_revision = '075'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s1_required', sa.Boolean(),
                                      nullable=False, server_default=sa.true()))


def downgrade():
    op.drop_column('trips', 's1_required')
