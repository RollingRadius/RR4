"""add FK constraints to load_requirements.company_id and created_by

Revision ID: 048
Revises: 047
Create Date: 2026-04-20
"""
from alembic import op
import sqlalchemy as sa

revision = '048'
down_revision = '047'
branch_labels = None
depends_on = None


def upgrade():
    # Add FK: company_id → organizations.id (RESTRICT so orphan loads are prevented)
    op.create_foreign_key(
        'fk_load_requirements_company_id',
        'load_requirements', 'organizations',
        ['company_id'], ['id'],
        ondelete='RESTRICT'
    )
    # Add FK: created_by → users.id (SET NULL so load survives user deletion)
    op.create_foreign_key(
        'fk_load_requirements_created_by',
        'load_requirements', 'users',
        ['created_by'], ['id'],
        ondelete='SET NULL'
    )


def downgrade():
    op.drop_constraint('fk_load_requirements_created_by', 'load_requirements', type_='foreignkey')
    op.drop_constraint('fk_load_requirements_company_id', 'load_requirements', type_='foreignkey')
