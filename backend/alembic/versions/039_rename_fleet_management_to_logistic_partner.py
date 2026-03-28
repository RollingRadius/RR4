"""Rename fleet_management role and business_type to logistic_partner

Changes:
  - roles: role_key 'fleet_management' -> 'logistic_partner'
  - roles: role_name -> 'Logistic Partner'
  - organizations: business_type 'fleet_management' -> 'logistic_partner'
  - organizations: CHECK constraint updated to use 'logistic_partner'

Note: user_organizations.role_id is a FK to roles.id — no update needed there.

Revision ID: 039
Revises: 038
Create Date: 2026-03-28
"""

from alembic import op
import sqlalchemy as sa

revision = '039'
down_revision = '038'
branch_labels = None
depends_on = None

VALID_BUSINESS_TYPES = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'logistic_partner', 'load_owner', 'other'
)


def upgrade() -> None:
    valid_list = ", ".join(f"'{t}'" for t in VALID_BUSINESS_TYPES)

    # ── 1. Drop old CHECK constraint safely ───────────────────────────────────
    op.execute(sa.text(
        "ALTER TABLE organizations DROP CONSTRAINT IF EXISTS check_business_type"
    ))

    # ── 2. Update organizations.business_type ────────────────────────────────
    op.execute(sa.text(
        "UPDATE organizations "
        "SET business_type = 'logistic_partner' "
        "WHERE business_type = 'fleet_management'"
    ))

    # ── 3. Normalise any stale business_type values to 'other' ───────────────
    op.execute(sa.text(
        f"UPDATE organizations "
        f"SET business_type = 'other' "
        f"WHERE business_type NOT IN ({valid_list})"
    ))

    # ── 4. Re-add CHECK constraint with logistic_partner ─────────────────────
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )

    # ── 5. Remove any conflicting logistic_partner role row ───────────────────
    op.execute(sa.text(
        "DELETE FROM roles WHERE role_key = 'logistic_partner'"
    ))

    # ── 6. Rename fleet_management role ──────────────────────────────────────
    op.execute(sa.text(
        "UPDATE roles "
        "SET role_key = 'logistic_partner', "
        "    role_name = 'Logistic Partner', "
        "    description = 'Logistic partner company with full access to fleet resources. "
        "Searches and fulfills load requirements posted by load owners.' "
        "WHERE role_key = 'fleet_management'"
    ))
    # user_organizations.role_id is a FK to roles.id — no update needed.


def downgrade() -> None:
    OLD_VALID_BUSINESS_TYPES = (
        'transportation', 'logistics', 'freight', 'courier',
        'delivery', 'taxi', 'rental', 'fleet_management', 'load_owner', 'other'
    )
    old_valid_list = ", ".join(f"'{t}'" for t in OLD_VALID_BUSINESS_TYPES)

    op.execute(sa.text(
        "ALTER TABLE organizations DROP CONSTRAINT IF EXISTS check_business_type"
    ))

    op.execute(sa.text(
        "UPDATE organizations "
        "SET business_type = 'fleet_management' "
        "WHERE business_type = 'logistic_partner'"
    ))

    op.execute(sa.text(
        f"UPDATE organizations "
        f"SET business_type = 'other' "
        f"WHERE business_type NOT IN ({old_valid_list})"
    ))

    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({old_valid_list})"
    )

    op.execute(sa.text(
        "DELETE FROM roles WHERE role_key = 'fleet_management'"
    ))

    op.execute(sa.text(
        "UPDATE roles "
        "SET role_key = 'fleet_management', "
        "    role_name = 'Fleet Manager', "
        "    description = 'Fleet company manager with full access to fleet management resources.' "
        "WHERE role_key = 'logistic_partner'"
    ))
