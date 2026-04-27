"""Add transporter role, transporter_user_id to trips, update business_type constraint

Revision ID: 049
Revises: 048
Create Date: 2026-04-27
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '049'
down_revision = '048'
branch_labels = None
depends_on = None


def upgrade():
    # 1. Add transporter_user_id to trips table
    op.add_column('trips', sa.Column(
        'transporter_user_id',
        postgresql.UUID(as_uuid=True),
        nullable=True
    ))

    # 2. Drop old business_type CHECK constraint and recreate with 'transporter'
    op.execute("ALTER TABLE organizations DROP CONSTRAINT IF EXISTS check_business_type")
    op.execute("""
        ALTER TABLE organizations ADD CONSTRAINT check_business_type
        CHECK (business_type IN (
            'transportation','logistics','freight','courier','delivery',
            'taxi','rental','logistic_partner','load_owner','transporter','other'
        ))
    """)

    # 3. Seed the transporter role
    op.execute("""
        INSERT INTO roles (id, role_name, role_key, description, is_system_role, created_at, updated_at)
        VALUES (
            gen_random_uuid(),
            'Transporter',
            'transporter',
            'Independent transporter who handles loading slip upload for trips assigned by a logistic partner.',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (role_key) DO NOTHING
    """)


def downgrade():
    op.drop_column('trips', 'transporter_user_id')

    op.execute("ALTER TABLE organizations DROP CONSTRAINT IF EXISTS check_business_type")
    op.execute("""
        ALTER TABLE organizations ADD CONSTRAINT check_business_type
        CHECK (business_type IN (
            'transportation','logistics','freight','courier','delivery',
            'taxi','rental','logistic_partner','load_owner','other'
        ))
    """)

    op.execute("DELETE FROM roles WHERE role_key = 'transporter'")
