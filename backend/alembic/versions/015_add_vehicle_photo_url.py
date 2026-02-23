"""add vehicle photo_url column

Revision ID: 015_add_vehicle_photo_url
Revises: 014_seed_owner_capabilities
Create Date: 2026-02-23

Adds a nullable photo_url column to the vehicles table to store
the path to an uploaded vehicle photo.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '015_add_vehicle_photo_url'
down_revision: Union[str, None] = '014_seed_owner_capabilities'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'vehicles',
        sa.Column('photo_url', sa.String(500), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('vehicles', 'photo_url')
