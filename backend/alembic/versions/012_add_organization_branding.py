"""add organization branding

Revision ID: 012_add_organization_branding
Revises: 011_add_organization_roles
Create Date: 2026-02-17 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '012_add_organization_branding'
down_revision: Union[str, None] = '011_add_organization_roles'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add organization_branding table for white-label theming"""

    # Create organization_branding table
    op.create_table(
        'organization_branding',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),

        # Logo fields
        sa.Column('logo_url', sa.String(500), nullable=True),
        sa.Column('logo_filename', sa.String(255), nullable=True),
        sa.Column('logo_size_bytes', sa.Integer(), nullable=True),
        sa.Column('logo_uploaded_at', sa.TIMESTAMP(), nullable=True),

        # Color fields (hex format: #RRGGBB)
        sa.Column('primary_color', sa.String(7), nullable=False, server_default='#1E40AF'),
        sa.Column('primary_dark', sa.String(7), nullable=False, server_default='#1E3A8A'),
        sa.Column('primary_light', sa.String(7), nullable=False, server_default='#3B82F6'),
        sa.Column('secondary_color', sa.String(7), nullable=False, server_default='#06B6D4'),
        sa.Column('accent_color', sa.String(7), nullable=False, server_default='#0EA5E9'),
        sa.Column('background_primary', sa.String(7), nullable=False, server_default='#F8FAFC'),
        sa.Column('background_secondary', sa.String(7), nullable=False, server_default='#FFFFFF'),

        # Flexible configuration
        sa.Column('theme_config', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default='{}'),

        # Audit fields
        sa.Column('created_at', sa.TIMESTAMP(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('updated_by', postgresql.UUID(as_uuid=True), nullable=True),

        # Constraints
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['updated_by'], ['users.id'], ondelete='SET NULL'),
        sa.UniqueConstraint('organization_id', name='uq_organization_branding_org_id')
    )

    # Create index for faster lookups
    op.create_index('ix_organization_branding_org_id', 'organization_branding', ['organization_id'])

    # Auto-create default branding for existing organizations
    op.execute("""
        INSERT INTO organization_branding (id, organization_id, created_at, updated_at)
        SELECT gen_random_uuid(), id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM organizations
        ON CONFLICT (organization_id) DO NOTHING
    """)


def downgrade() -> None:
    """Remove organization_branding table"""

    op.drop_index('ix_organization_branding_org_id', table_name='organization_branding')
    op.drop_table('organization_branding')
