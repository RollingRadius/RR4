"""rename fleet_owner → fleet_management (role key and business type)

Revision ID: 025_rename_fleet_owner_to_fleet_management
Revises: 024_remove_generic_owner_role
Create Date: 2026-03-23

Renames the 'fleet_owner' role key to 'fleet_management' and updates the
business_type check constraint and all existing data to match.

Steps:
1. Drop old check_business_type constraint
2. Rename business_type 'fleet_owner' → 'fleet_management' in organizations
3. Rename role_key 'fleet_owner' → 'fleet_management' and role_name in roles
4. Re-create check constraint with 'fleet_management' (replacing 'fleet_owner')
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '025_rename_fleet_owner_to_fleet_management'
down_revision: Union[str, None] = '024_remove_generic_owner_role'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

VALID_BUSINESS_TYPES_NEW = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'fleet_management', 'load_owner', 'other'
)

VALID_BUSINESS_TYPES_OLD = (
    'transportation', 'logistics', 'freight', 'courier',
    'delivery', 'taxi', 'rental', 'fleet_owner', 'load_owner', 'other'
)


def upgrade() -> None:
    # 1. Drop old business_type check constraint (may not exist if 020 was not run)
    try:
        op.drop_constraint('check_business_type', 'organizations', type_='check')
    except Exception:
        pass  # constraint didn't exist — that's fine

    # 2. Rename business_type 'fleet_owner' → 'fleet_management' in existing orgs
    op.execute(
        sa.text("""
            UPDATE organizations
            SET business_type = 'fleet_management'
            WHERE business_type = 'fleet_owner'
        """)
    )

    # 3. Rename role: fleet_owner → fleet_management
    op.execute(
        sa.text("""
            UPDATE roles
            SET role_name = 'Fleet Management',
                role_key  = 'fleet_management',
                description = 'Fleet management company owner with full access to fleet resources.'
            WHERE role_key = 'fleet_owner'
        """)
    )

    # 4. Re-create check constraint with new list
    valid_list = ", ".join(f"'{t}'" for t in VALID_BUSINESS_TYPES_NEW)
    op.execute(
        sa.text(f"""
            UPDATE organizations
            SET business_type = 'other'
            WHERE business_type NOT IN ({valid_list})
        """)
    )
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )


def downgrade() -> None:
    # Drop new constraint
    try:
        op.drop_constraint('check_business_type', 'organizations', type_='check')
    except Exception:
        pass

    # Revert business_type 'fleet_management' → 'fleet_owner'
    op.execute(
        sa.text("""
            UPDATE organizations
            SET business_type = 'fleet_owner'
            WHERE business_type = 'fleet_management'
        """)
    )

    # Revert role rename
    op.execute(
        sa.text("""
            UPDATE roles
            SET role_name = 'Fleet Owner',
                role_key  = 'fleet_owner',
                description = 'Fleet company owner with full access to fleet management resources.'
            WHERE role_key = 'fleet_management'
        """)
    )

    # Restore old check constraint
    valid_list = ", ".join(f"'{t}'" for t in VALID_BUSINESS_TYPES_OLD)
    op.create_check_constraint(
        'check_business_type',
        'organizations',
        f"business_type IN ({valid_list})"
    )
