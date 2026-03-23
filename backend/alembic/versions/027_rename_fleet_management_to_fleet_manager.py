"""rename fleet management role_name to Fleet Manager

Changes:
  - roles.role_name: 'Fleet Management' → 'Fleet Manager'
  - roles.description updated to reflect Fleet Manager title

Revision ID: 027
Revises: 026
Create Date: 2026-03-23
"""

from alembic import op

revision = '027'
down_revision = '026'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "UPDATE roles "
        "SET role_name = 'Fleet Manager', "
        "    description = 'Fleet company manager with full access to fleet management resources.' "
        "WHERE role_key = 'fleet_management'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE roles "
        "SET role_name = 'Fleet Management', "
        "    description = 'Fleet company owner with full access to fleet management resources.' "
        "WHERE role_key = 'fleet_management'"
    )
