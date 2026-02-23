"""add assigned_by and assigned_at to vehicles

Revision ID: 018_vehicle_assignment_tracking
Revises: 017_vehicle_photo_bytea
Create Date: 2026-02-23

Adds assigned_by_user_id (FK → users) and assigned_at (timestamp) so the
driver dashboard can display who assigned a vehicle and when.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision: str = '018_vehicle_assignment_tracking'
down_revision: Union[str, None] = '017_vehicle_photo_bytea'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('vehicles', sa.Column(
        'assigned_by_user_id',
        UUID(as_uuid=True),
        sa.ForeignKey('users.id', ondelete='SET NULL'),
        nullable=True
    ))
    op.add_column('vehicles', sa.Column(
        'assigned_at',
        sa.DateTime(),
        nullable=True
    ))


def downgrade() -> None:
    op.drop_column('vehicles', 'assigned_at')
    op.drop_column('vehicles', 'assigned_by_user_id')
