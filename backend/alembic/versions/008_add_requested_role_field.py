"""add requested_role_id to user_organizations

Revision ID: 008_add_requested_role_field
Revises: 007_add_profile_completed
Create Date: 2026-01-29

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


# revision identifiers, used by Alembic.
revision = '008_add_requested_role_field'
down_revision = '007_add_profile_completed'
branch_labels = None
depends_on = None


def upgrade():
    """Add requested_role_id field to user_organizations table"""
    op.add_column(
        'user_organizations',
        sa.Column('requested_role_id', UUID(as_uuid=True), nullable=True)
    )

    # Add foreign key constraint
    op.create_foreign_key(
        'fk_user_organizations_requested_role',
        'user_organizations',
        'roles',
        ['requested_role_id'],
        ['id']
    )


def downgrade():
    """Remove requested_role_id field from user_organizations table"""
    op.drop_constraint('fk_user_organizations_requested_role', 'user_organizations', type_='foreignkey')
    op.drop_column('user_organizations', 'requested_role_id')
