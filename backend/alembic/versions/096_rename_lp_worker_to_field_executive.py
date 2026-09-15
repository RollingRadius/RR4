"""rename logistic_partner_worker role_name to Field Executive

Changes:
  - roles.role_name: 'Logistic Partner Worker' -> 'Field Executive'
    (role_key stays 'logistic_partner_worker' — unchanged)

Revision ID: 096
Revises: 095
Create Date: 2026-09-11
"""

from alembic import op

revision = '096'
down_revision = '095'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "UPDATE roles "
        "SET role_name = 'Field Executive' "
        "WHERE role_key = 'logistic_partner_worker'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE roles "
        "SET role_name = 'Logistic Partner Worker' "
        "WHERE role_key = 'logistic_partner_worker'"
    )
