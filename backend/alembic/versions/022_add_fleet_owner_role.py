"""add fleet_owner system role and capabilities

Revision ID: 022_add_fleet_owner_role
Revises: 021_add_load_requirements_table
Create Date: 2026-03-20

Adds the Fleet Owner system role and seeds it with full capabilities
(same as the generic owner role). Fleet owners manage a fleet company.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '022_add_fleet_owner_role'
down_revision: Union[str, None] = '021_add_load_requirements_table'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Seed fleet_owner system role and copy owner capabilities to it."""

    # 1. Insert fleet_owner role
    op.execute(
        sa.text("""
            INSERT INTO roles (id, role_name, role_key, description, is_system_role)
            VALUES (
                gen_random_uuid(),
                'Fleet Owner',
                'fleet_owner',
                'Fleet company owner with full access to fleet management resources.',
                true
            )
            ON CONFLICT (role_key) DO NOTHING
        """)
    )

    # 2. Copy all capabilities from the 'owner' role to 'fleet_owner'
    op.execute(
        sa.text("""
            INSERT INTO role_capabilities (id, role_id, capability_key, access_level)
            SELECT gen_random_uuid(), fleet.id, rc.capability_key, rc.access_level
            FROM role_capabilities rc
            JOIN roles owner_role ON owner_role.id = rc.role_id AND owner_role.role_key = 'owner'
            JOIN roles fleet ON fleet.role_key = 'fleet_owner'
            WHERE NOT EXISTS (
                SELECT 1 FROM role_capabilities existing
                WHERE existing.role_id = fleet.id
                  AND existing.capability_key = rc.capability_key
            )
        """)
    )


def downgrade() -> None:
    """Remove fleet_owner role (only if not assigned to any users)."""
    op.execute(
        sa.text("""
            DELETE FROM role_capabilities
            WHERE role_id = (SELECT id FROM roles WHERE role_key = 'fleet_owner')
        """)
    )
    op.execute(
        sa.text("""
            DELETE FROM roles
            WHERE role_key = 'fleet_owner'
              AND id NOT IN (
                  SELECT DISTINCT role_id FROM user_organizations
                  WHERE role_id IS NOT NULL
              )
        """)
    )
