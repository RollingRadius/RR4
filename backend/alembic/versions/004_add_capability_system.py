"""add capability system

Revision ID: 004_add_capability_system
Revises: 003_add_zones_table
Create Date: 2026-01-27

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '004_add_capability_system'
down_revision = '003_add_zones_table'
branch_labels = None
depends_on = None


def upgrade():
    # Create capabilities table
    op.create_table(
        'capabilities',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('capability_key', sa.String(length=100), nullable=False),
        sa.Column('feature_category', sa.Enum('USER_MANAGEMENT', 'ROLE_MANAGEMENT', 'VEHICLE_MANAGEMENT', 'DRIVER_MANAGEMENT', 'TRIP_MANAGEMENT', 'TRACKING', 'FINANCIAL', 'MAINTENANCE', 'COMPLIANCE', 'CUSTOMER', 'REPORTING', 'SYSTEM', name='featurecategory'), nullable=False),
        sa.Column('capability_name', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('access_levels', sa.JSON(), nullable=False),
        sa.Column('is_system_critical', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('capability_key')
    )
    op.create_index(op.f('ix_capabilities_capability_key'), 'capabilities', ['capability_key'], unique=False)
    op.create_index(op.f('ix_capabilities_feature_category'), 'capabilities', ['feature_category'], unique=False)

    # Create role_capabilities table
    op.create_table(
        'role_capabilities',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('role_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('capability_key', sa.String(length=100), nullable=False),
        sa.Column('access_level', sa.String(length=20), nullable=False),
        sa.Column('constraints', sa.JSON(), nullable=True),
        sa.Column('granted_at', sa.DateTime(), nullable=True),
        sa.Column('granted_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.ForeignKeyConstraint(['capability_key'], ['capabilities.capability_key'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['granted_by'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('role_id', 'capability_key', name='unique_role_capability')
    )
    op.create_index(op.f('ix_role_capabilities_capability_key'), 'role_capabilities', ['capability_key'], unique=False)
    op.create_index(op.f('ix_role_capabilities_role_id'), 'role_capabilities', ['role_id'], unique=False)

    # Create custom_roles table
    op.create_table(
        'custom_roles',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('role_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('template_sources', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('is_template', sa.Boolean(), nullable=True),
        sa.Column('template_name', sa.String(length=100), nullable=True),
        sa.Column('template_description', sa.Text(), nullable=True),
        sa.Column('customizations', sa.JSON(), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('role_id')
    )


def downgrade():
    op.drop_table('custom_roles')
    op.drop_index(op.f('ix_role_capabilities_role_id'), table_name='role_capabilities')
    op.drop_index(op.f('ix_role_capabilities_capability_key'), table_name='role_capabilities')
    op.drop_table('role_capabilities')
    op.drop_index(op.f('ix_capabilities_feature_category'), table_name='capabilities')
    op.drop_index(op.f('ix_capabilities_capability_key'), table_name='capabilities')
    op.drop_table('capabilities')
    op.execute('DROP TYPE featurecategory')
