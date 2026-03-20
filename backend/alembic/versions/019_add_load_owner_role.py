"""add load_owner system role

Revision ID: 019_add_load_owner_role
Revises: 018_vehicle_assignment_tracking
Create Date: 2026-03-20

Adds the Load Owner system role. Load owners are cargo/freight owners who
post load requirements and seek transport services without managing a fleet.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '019_add_load_owner_role'
down_revision: Union[str, None] = '018_vehicle_assignment_tracking'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Seed load_owner system role."""
    op.execute(
        sa.text("""
            INSERT INTO roles (id, role_name, role_key, description, is_system_role)
            VALUES (
                gen_random_uuid(),
                'Load Owner',
                'load_owner',
                'Cargo/load owner who posts load requirements and seeks transport services.',
                true
            )
            ON CONFLICT (role_key) DO NOTHING
        """)
    )


def downgrade() -> None:
    """Remove load_owner role (only if not assigned to any users)."""
    op.execute(
        sa.text("""
            DELETE FROM roles
            WHERE role_key = 'load_owner'
              AND id NOT IN (
                  SELECT DISTINCT role_id FROM user_organizations
                  WHERE role_id IS NOT NULL
              )
        """)
    )
