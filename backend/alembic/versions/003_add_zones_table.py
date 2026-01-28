"""Add zones table for custom shape drawing

Revision ID: 003_add_zones_table
Revises: 002_add_driver_tables
Create Date: 2026-01-22

Creates zones table for storing custom drawn polygons/shapes
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision: str = '003_add_zones_table'
down_revision: Union[str, None] = '002_add_driver_tables'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create zones table"""

    # Create zones table
    op.create_table(
        'zones',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), primary_key=True),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('zone_type', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('coordinates', postgresql.JSONB(), nullable=False),
        sa.Column('color', sa.String(length=7), nullable=False, server_default='#3B82F6'),
        sa.Column('fill_opacity', sa.String(length=4), nullable=False, server_default='0.3'),
        sa.Column('stroke_width', sa.String(length=4), nullable=False, server_default='2'),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.CheckConstraint(
            "zone_type IN ('service_area', 'parking', 'restricted', 'delivery', 'geofence', 'custom')",
            name='check_zone_type'
        ),
        sa.CheckConstraint(
            "status IN ('active', 'inactive', 'archived')",
            name='check_zone_status'
        ),
        sa.CheckConstraint(
            "color ~ '^#[0-9A-Fa-f]{6}$'",
            name='check_color_format'
        )
    )

    # Create indexes for zones table
    op.create_index('idx_zones_organization', 'zones', ['organization_id'])
    op.create_index('idx_zones_type', 'zones', ['zone_type'])
    op.create_index('idx_zones_status', 'zones', ['status'])
    op.create_index('idx_zone_org_type', 'zones', ['organization_id', 'zone_type'])


def downgrade() -> None:
    """Drop zones table"""

    # Drop indexes first
    op.drop_index('idx_zone_org_type', 'zones')
    op.drop_index('idx_zones_status', 'zones')
    op.drop_index('idx_zones_type', 'zones')
    op.drop_index('idx_zones_organization', 'zones')

    # Drop table
    op.drop_table('zones')
