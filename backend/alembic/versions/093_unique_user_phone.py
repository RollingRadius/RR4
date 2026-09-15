"""Add normalized-phone unique index on users

Revision ID: 093
Revises: 092
Create Date: 2026-09-08

Phone-number uniqueness for user accounts was never enforced at the DB
level — only checked application-side, and only on profile edits
(profile_service.py's update_profile), never at signup. A DB audit found
one collision (5 test accounts sharing a placeholder +911234567890),
now resolved manually; every other phone number in the table is unique.

Signup and profile-edit stored phone verbatim as typed, with no
normalization — validate_phone() (app/utils/validators.py) accepts
"9876543210", "+919876543210", "+91 98765 67890" etc. as equally valid,
so two accounts of the *same* number in different formats would not be
caught by a plain UNIQUE(phone). This mirrors the normalized expression
index already used for drivers.phone (see
090_add_driver_phone_index.py) — right(regexp_replace(phone,
'[^0-9]', '', 'g'), 10) — but as a UNIQUE index instead of a plain one.

Must stay in sync with app/utils/phone.py's normalize_phone().
"""

from alembic import op

revision = '093'
down_revision = '092'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "CREATE UNIQUE INDEX ux_users_phone_normalized ON users "
        "(right(regexp_replace(phone, '[^0-9]', '', 'g'), 10))"
    )


def downgrade():
    op.execute("DROP INDEX IF EXISTS ux_users_phone_normalized")
