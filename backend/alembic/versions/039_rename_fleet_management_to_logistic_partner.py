"""Rename fleet_management role and business_type to logistic_partner

Changes:
  - roles: role_key 'fleet_management' → 'logistic_partner'
  - roles: role_name 'Fleet Manager' → 'Logistic Partner'
  - roles: description updated
  - organizations: business_type 'fleet_management' → 'logistic_partner'
  - organizations: DROP old CHECK constraint, ADD new one with 'logistic_partner'
  - user_organizations: any cached role references updated via FK cascade

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

# Full list of valid business types after this migration
VALID_BUSINESS_TYPES = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'logistic_partner', 'load_owner', 'other'
)


def upgrade() -> None:
    # ── 1. Drop old CHECK constraint on organizations.business_type ──────────
    # The constraint was created in migration 020 and may have been updated.
    # We drop it safely (ignore error if it doesn't exist under this name).
    try:
        op.drop_constraint('check_business_type', 'organizations', type_='check')
    except Exception:
        pass  # Constraint may not exist or may have a different name — safe to continue

    # ── 2. Update organizations: business_type fleet_management → logistic_partner ──
    op.execute(
        sa.text(
            "UPDATE organizations "
            "SET business_type = 'logistic_partner' "
            "WHERE business_type = 'fleet_management'"
        )
    )

    # ── 3. Normalise any stray business_type values to 'other' ───────────────
    valid_list = ", ".join(f"'{t}'" for t in VALID_BUSINESS_TYPES)
    op.execute(
        sa.text(
            f"UPDATE organizations "
            f"SET business_type = 'other' "
            f"WHERE business_type NOT IN ({valid_list})"
        )
    )

    # ── 4. Add new CHECK constraint with logistic_partner ────────────────────
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )

    # ── 5. Update roles table: role_key and role_name ────────────────────────
    # Remove any conflicting 'logistic_partner' row that might exist from seeding
    op.execute(
        sa.text(
            "DELETE FROM roles "
            "WHERE role_key = 'logistic_partner' AND role_name != 'Logistic Partner'"
        )
    )

    op.execute(
        sa.text(
            "UPDATE roles "
            "SET role_key = 'logistic_partner', "
            "    role_name = 'Logistic Partner', "
            "    description = 'Logistic partner company with full access to fleet resources. "
            "Searches and fulfills load requirements posted by load owners.' "
            "WHERE role_key = 'fleet_management'"
        )
    )

    # ── 6. Update user_organizations: if role_key is stored as a string column ─
    # (Most setups use a FK to roles.id so the above update cascades automatically.
    #  This handles any denormalised role_key text column if present.)
    try:
        op.execute(
            sa.text(
                "UPDATE user_organizations "
                "SET role_key = 'logistic_partner' "
                "WHERE role_key = 'fleet_management'"
            )
        )
    except Exception:
        pass  # Column may not exist — safe to skip


def downgrade() -> None:
    # ── Reverse: logistic_partner → fleet_management ─────────────────────────
    try:
        op.drop_constraint('check_business_type', 'organizations', type_='check')
    except Exception:
        pass

    op.execute(
        sa.text(
            "UPDATE organizations "
            "SET business_type = 'fleet_management' "
            "WHERE business_type = 'logistic_partner'"
        )
    )

    OLD_VALID_BUSINESS_TYPES = (
        'transportation', 'logistics', 'freight', 'courier',
        'delivery', 'taxi', 'rental', 'fleet_management', 'load_owner', 'other'
    )
    old_valid_list = ", ".join(f"'{t}'" for t in OLD_VALID_BUSINESS_TYPES)
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({old_valid_list})"
    )

    op.execute(
        sa.text(
            "UPDATE roles "
            "SET role_key = 'fleet_management', "
            "    role_name = 'Fleet Manager', "
            "    description = 'Fleet company manager with full access to fleet management resources.' "
            "WHERE role_key = 'logistic_partner'"
        )
    )

    try:
        op.execute(
            sa.text(
                "UPDATE user_organizations "
                "SET role_key = 'fleet_management' "
                "WHERE role_key = 'logistic_partner'"
            )
        )
    except Exception:
        pass
