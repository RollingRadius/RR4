"""migrate existing owner roles based on company business_type

Revision ID: 023_migrate_owner_roles
Revises: 022_add_fleet_owner_role
Create Date: 2026-03-20

For every user currently assigned the generic 'owner' role, update their
user_organizations.role_id to match the company's business_type:
  - business_type = 'fleet_owner'  → fleet_owner role
  - business_type = 'load_owner'   → load_owner  role
  - anything else                  → keep owner   role (no change)
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '023_migrate_owner_roles'
down_revision: Union[str, None] = '022_add_fleet_owner_role'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Re-assign to fleet_owner role where company is fleet_owner type
    op.execute(
        sa.text("""
            UPDATE user_organizations uo
            SET role_id = (SELECT id FROM roles WHERE role_key = 'fleet_owner')
            FROM organizations o, roles r
            WHERE uo.organization_id = o.id
              AND uo.role_id         = r.id
              AND r.role_key         = 'owner'
              AND o.business_type    = 'fleet_owner'
              AND EXISTS (SELECT 1 FROM roles WHERE role_key = 'fleet_owner')
        """)
    )

    # Re-assign to load_owner role where company is load_owner type
    op.execute(
        sa.text("""
            UPDATE user_organizations uo
            SET role_id = (SELECT id FROM roles WHERE role_key = 'load_owner')
            FROM organizations o, roles r
            WHERE uo.organization_id = o.id
              AND uo.role_id         = r.id
              AND r.role_key         = 'owner'
              AND o.business_type    = 'load_owner'
              AND EXISTS (SELECT 1 FROM roles WHERE role_key = 'load_owner')
        """)
    )


def downgrade() -> None:
    # Revert fleet_owner and load_owner users back to generic owner role
    op.execute(
        sa.text("""
            UPDATE user_organizations uo
            SET role_id = (SELECT id FROM roles WHERE role_key = 'owner')
            FROM roles r
            WHERE uo.role_id = r.id
              AND r.role_key IN ('fleet_owner', 'load_owner')
              AND EXISTS (SELECT 1 FROM roles WHERE role_key = 'owner')
        """)
    )
