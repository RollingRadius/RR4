"""add organization roles

Revision ID: 011_add_organization_roles
Revises: 010_add_gps_tracking
Create Date: 2026-02-02 17:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '011_add_organization_roles'
down_revision: Union[str, None] = '010_add_gps_tracking'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add organization member roles (admin, dispatcher, user, viewer)"""

    # Insert organization roles
    op.execute("""
        INSERT INTO roles (role_name, role_key, description, is_system_role) VALUES
        ('Admin', 'admin', 'Can manage members and settings', false),
        ('Dispatcher', 'dispatcher', 'Can manage trips and assignments', false),
        ('User', 'user', 'Standard access to features', false),
        ('Viewer', 'viewer', 'Read-only access', false)
        ON CONFLICT (role_key) DO NOTHING
    """)


def downgrade() -> None:
    """Remove organization roles"""

    op.execute("""
        DELETE FROM roles WHERE role_key IN ('admin', 'dispatcher', 'user', 'viewer')
    """)
