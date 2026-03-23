"""remove generic owner role — fleet_owner is now the default

Revision ID: 024_remove_generic_owner_role
Revises: 023_migrate_owner_roles_by_business_type
Create Date: 2026-03-21

Removes the generic 'owner' role entirely.
Any remaining users still assigned 'owner' are migrated to 'fleet_owner'.
The 'owner' role record and its capabilities are then deleted.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '024_remove_generic_owner_role'
down_revision: Union[str, None] = '023_migrate_owner_roles'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Migrate any remaining 'owner' users to 'fleet_owner'
    op.execute(
        sa.text("""
            UPDATE user_organizations
            SET role_id = (SELECT id FROM roles WHERE role_key = 'fleet_owner')
            WHERE role_id = (SELECT id FROM roles WHERE role_key = 'owner')
              AND EXISTS (SELECT 1 FROM roles WHERE role_key = 'fleet_owner')
              AND EXISTS (SELECT 1 FROM roles WHERE role_key = 'owner')
        """)
    )

    # 2. Delete 'owner' role capabilities
    op.execute(
        sa.text("""
            DELETE FROM role_capabilities
            WHERE role_id = (SELECT id FROM roles WHERE role_key = 'owner')
        """)
    )

    # 3. Delete 'owner' role
    op.execute(
        sa.text("""
            DELETE FROM roles WHERE role_key = 'owner'
        """)
    )


def downgrade() -> None:
    # Re-insert the generic owner role
    op.execute(
        sa.text("""
            INSERT INTO roles (id, role_name, role_key, description, is_system_role)
            VALUES (
                gen_random_uuid(),
                'Owner',
                'owner',
                'Full access to company resources. Legacy generic owner role.',
                true
            )
            ON CONFLICT (role_key) DO NOTHING
        """)
    )

    # Copy fleet_owner capabilities to owner
    op.execute(
        sa.text("""
            INSERT INTO role_capabilities (id, role_id, capability_key, access_level)
            SELECT gen_random_uuid(), o.id, rc.capability_key, rc.access_level
            FROM role_capabilities rc
            JOIN roles fleet ON fleet.id = rc.role_id AND fleet.role_key = 'fleet_owner'
            JOIN roles o ON o.role_key = 'owner'
            WHERE NOT EXISTS (
                SELECT 1 FROM role_capabilities e
                WHERE e.role_id = o.id AND e.capability_key = rc.capability_key
            )
        """)
    )
