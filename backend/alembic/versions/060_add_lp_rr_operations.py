"""Add lp_rr_operations role and rr_company_id to users

Revision ID: 060
Revises: 059_s3_loaded_weight_slip
Create Date: 2026-05-30
"""

from alembic import op
import sqlalchemy as sa

revision = '060'
down_revision = '059_s3_loaded_weight_slip'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. New role: RR Operations worker under LP org
    op.execute(sa.text(
        "INSERT INTO roles (id, role_name, role_key, description, is_system_role) "
        "VALUES (gen_random_uuid(), :role_name, :role_key, :description, :is_system_role) "
        "ON CONFLICT (role_key) DO NOTHING"
    ).bindparams(
        role_name="RR Operations",
        role_key="lp_rr_operations",
        description=(
            "RR Operations worker at a logistic partner company. "
            "Handles RR sync and trip data entry in the RR system. "
            "Has a dedicated RR Operations dashboard."
        ),
        is_system_role=True,
    ))

    # 2. RR company ObjectId on users (nullable — existing users unaffected)
    #    Same pattern as organizations.rr_company_id.
    #    Set manually for lp_rr_operations workers via pgAdmin.
    op.add_column('users',
        sa.Column('rr_company_id', sa.String(24), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('users', 'rr_company_id')
    op.execute(sa.text(
        "DELETE FROM roles WHERE role_key = 'lp_rr_operations'"
    ))
