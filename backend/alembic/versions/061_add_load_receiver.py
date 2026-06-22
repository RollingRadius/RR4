"""Add load_receiver role and consignee columns to trips

Revision ID: 061
Revises: 060
Create Date: 2026-05-30
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '061'
down_revision = '060'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. New role: Load Receiver (consignee)
    op.execute(sa.text(
        "INSERT INTO roles (id, role_name, role_key, description, is_system_role) "
        "VALUES (gen_random_uuid(), :role_name, :role_key, :description, :is_system_role) "
        "ON CONFLICT (role_key) DO NOTHING"
    ).bindparams(
        role_name="Load Receiver",
        role_key="load_receiver",
        description=(
            "Consignee — the party that receives the delivered cargo. "
            "Can be an organisation or an individual user. "
            "Has a dedicated Load Receiver dashboard."
        ),
        is_system_role=True,
    ))

    # 2. Consignee reference on trips
    #    Exactly one of the two will be populated per trip (org OR user).
    op.add_column('trips',
        sa.Column('consignee_org_id', postgresql.UUID(as_uuid=True), nullable=True)
    )
    op.add_column('trips',
        sa.Column('consignee_user_id', postgresql.UUID(as_uuid=True), nullable=True)
    )

    # 3. RR Operations worker assigned to handle this trip's sync
    op.add_column('trips',
        sa.Column('rr_ops_user_id', postgresql.UUID(as_uuid=True), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('trips', 'rr_ops_user_id')
    op.drop_column('trips', 'consignee_user_id')
    op.drop_column('trips', 'consignee_org_id')
    op.execute(sa.text(
        "DELETE FROM roles WHERE role_key = 'load_receiver'"
    ))
