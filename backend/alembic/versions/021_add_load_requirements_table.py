"""add load_requirements table

Revision ID: 021_add_load_requirements_table
Revises: 020_add_business_type_constraint
Create Date: 2026-03-20

Stores load requirements submitted by load_owner companies through the
Upload Load Requirement dashboard (manual, bulk, and photo entry methods).
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision: str = '021_add_load_requirements_table'
down_revision: Union[str, None] = '020_add_business_type_constraint'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'load_requirements',
        sa.Column('id', UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text('gen_random_uuid()')),
        sa.Column('company_id', UUID(as_uuid=True),
                  sa.ForeignKey('organizations.id', ondelete='CASCADE'),
                  nullable=False, index=True),
        sa.Column('created_by', UUID(as_uuid=True),
                  sa.ForeignKey('users.id', ondelete='SET NULL'),
                  nullable=True),
        # Entry method
        sa.Column('entry_method', sa.String(10), nullable=False,
                  server_default='manual'),
        # Route
        sa.Column('pickup_location', sa.Text, nullable=True),
        sa.Column('unload_location', sa.Text, nullable=True),
        # Cargo
        sa.Column('material_type', sa.String(50), nullable=True),
        sa.Column('entry_date', sa.Date, nullable=True),
        sa.Column('truck_count', sa.Integer, nullable=False, server_default='1'),
        # Truck specifications
        sa.Column('capacity', sa.String(50), nullable=True),
        sa.Column('axel_type', sa.String(50), nullable=True),
        sa.Column('body_type', sa.String(50), nullable=True),
        sa.Column('floor_type', sa.String(50), nullable=True),
        # Lifecycle
        sa.Column('status', sa.String(20), nullable=False,
                  server_default='pending'),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True),
                  server_default=sa.text('now()'), nullable=False),
        # Constraints
        sa.CheckConstraint(
            "entry_method IN ('manual', 'bulk', 'photo')",
            name='check_entry_method'
        ),
        sa.CheckConstraint(
            "status IN ('pending', 'assigned', 'in_transit', 'delivered', 'cancelled')",
            name='check_load_status'
        ),
    )


def downgrade() -> None:
    op.drop_table('load_requirements')
