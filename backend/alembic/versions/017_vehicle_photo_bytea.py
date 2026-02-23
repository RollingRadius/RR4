"""migrate vehicle photo to bytea storage

Revision ID: 017_vehicle_photo_bytea
Revises: 016_add_driver_photo
Create Date: 2026-02-23

Replaces photo_url (file-system path) with photo (bytea) + photo_content_type
columns on the vehicles table. All existing photo_url values are discarded.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = '017_vehicle_photo_bytea'
down_revision: Union[str, None] = '016_add_driver_photo'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column('vehicles', 'photo_url')
    op.add_column('vehicles', sa.Column('photo', sa.LargeBinary(), nullable=True))
    op.add_column('vehicles', sa.Column('photo_content_type', sa.String(50), nullable=True))


def downgrade() -> None:
    op.drop_column('vehicles', 'photo_content_type')
    op.drop_column('vehicles', 'photo')
    op.add_column('vehicles', sa.Column('photo_url', sa.String(500), nullable=True))
