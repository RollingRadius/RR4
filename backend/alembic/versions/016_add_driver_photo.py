"""add driver photo columns

Revision ID: 016_add_driver_photo
Revises: 015_add_vehicle_photo_url
Create Date: 2026-02-23

Adds photo (bytea) and photo_content_type columns to the drivers table.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = '016_add_driver_photo'
down_revision: Union[str, None] = '015_add_vehicle_photo_url'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('drivers', sa.Column('photo', sa.LargeBinary(), nullable=True))
    op.add_column('drivers', sa.Column('photo_content_type', sa.String(50), nullable=True))


def downgrade() -> None:
    op.drop_column('drivers', 'photo_content_type')
    op.drop_column('drivers', 'photo')
