"""Add normalized-phone expression index on drivers

Revision ID: 090
Revises: 089
Create Date: 2026-08-31

Live driver tracking needs to match the RR-side driver picked in "+New Trip"
(identified by phone number) to a local RR4 Driver/User account. This
expression index keeps that lookup fast without adding a new column or
touching any existing write path. The normalization here (strip non-digits,
take the last 10) MUST stay textually in sync with
backend/app/utils/phone.py's normalize_phone() and the query in
backend/app/services/driver_link_service.py — both sides need to compute
the same value for the index to actually be used.
"""

from alembic import op

revision = '090'
down_revision = '089'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "CREATE INDEX ix_drivers_phone_normalized ON drivers "
        "(right(regexp_replace(phone, '[^0-9]', '', 'g'), 10))"
    )


def downgrade():
    op.execute("DROP INDEX IF EXISTS ix_drivers_phone_normalized")
