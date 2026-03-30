"""Add logistic_partner_worker and load_owner_worker roles

Revision ID: 040
Revises: 039
Create Date: 2026-03-30
"""

from alembic import op
import sqlalchemy as sa

revision = '040'
down_revision = '039'
branch_labels = None
depends_on = None

WORKER_ROLES = [
    {
        "role_name": "Logistic Partner Worker",
        "role_key": "logistic_partner_worker",
        "description": (
            "Worker at a logistic partner company. "
            "Can manage trip stages and view fleet status. "
            "Cannot search or fulfill loads independently."
        ),
        "is_system_role": True,
    },
    {
        "role_name": "Load Owner Worker",
        "role_key": "load_owner_worker",
        "description": "Worker at a load owner company.",
        "is_system_role": True,
    },
]


def upgrade() -> None:
    for role in WORKER_ROLES:
        op.execute(sa.text(
            "INSERT INTO roles (id, role_name, role_key, description, is_system_role) "
            "VALUES (gen_random_uuid(), :role_name, :role_key, :description, :is_system_role) "
            "ON CONFLICT (role_key) DO NOTHING"
        ).bindparams(**role))


def downgrade() -> None:
    for role in WORKER_ROLES:
        op.execute(sa.text(
            "DELETE FROM roles WHERE role_key = :role_key"
        ).bindparams(role_key=role["role_key"]))
