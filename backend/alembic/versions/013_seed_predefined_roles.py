"""seed predefined roles and capabilities

Revision ID: 013_seed_predefined_roles
Revises: 012_add_organization_branding
Create Date: 2026-02-19

Seeds the 11 predefined role templates into the roles table and their
capability assignments into role_capabilities. Capabilities are seeded
via the application startup event (see main.py).
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '013_seed_predefined_roles'
down_revision: Union[str, None] = 'add_user_id_to_drivers'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


PREDEFINED_ROLES = [
    ('super_admin', 'Super Admin', 'Highest level of access with full system control'),
    ('fleet_manager', 'Fleet Manager', 'Manages day-to-day fleet operations'),
    ('dispatcher', 'Dispatcher', 'Coordinates vehicle assignments and schedules'),
    ('driver', 'Driver', 'Operates vehicles and completes assigned trips'),
    ('accountant', 'Accountant/Finance Manager', 'Manages financial aspects of fleet operations'),
    ('maintenance_manager', 'Maintenance Manager', 'Oversees vehicle maintenance and repairs'),
    ('compliance_officer', 'Compliance Officer', 'Ensures regulatory compliance and documentation'),
    ('operations_manager', 'Operations Manager', 'Oversees overall fleet operations and strategy'),
    ('maintenance_technician', 'Maintenance Technician', 'Performs vehicle maintenance and repairs'),
    ('customer_service', 'Customer Service Representative', 'Handles customer inquiries and support'),
    ('viewer_analyst', 'Viewer/Analyst', 'Read-only access for monitoring and reporting'),
]


def upgrade() -> None:
    """Seed predefined role templates into the roles table."""
    for role_key, role_name, description in PREDEFINED_ROLES:
        op.execute(
            sa.text("""
                INSERT INTO roles (id, role_name, role_key, description, is_system_role)
                VALUES (gen_random_uuid(), :role_name, :role_key, :description, true)
                ON CONFLICT (role_key) DO NOTHING
            """).bindparams(
                role_name=role_name,
                role_key=role_key,
                description=description
            )
        )


def downgrade() -> None:
    """Remove seeded predefined roles (only if not assigned to any users)."""
    role_keys = [r[0] for r in PREDEFINED_ROLES]
    # Use parameterized approach - delete one by one
    for role_key in role_keys:
        op.execute(
            sa.text(
                "DELETE FROM roles WHERE role_key = :role_key AND id NOT IN "
                "(SELECT DISTINCT role_id FROM user_organizations WHERE role_id IS NOT NULL)"
            ).bindparams(role_key=role_key)
        )
