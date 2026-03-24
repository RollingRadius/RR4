"""add stage 3 weigh bridge fields and trip amount to fulfill

Changes:
  - trips.s3_empty_truck_weight_kg  VARCHAR(20)  — empty truck weight from dharma kanta
  - trips.s3_loaded_truck_weight_kg VARCHAR(20)  — loaded truck weight from dharma kanta

Revision ID: 030
Revises: 029
Create Date: 2026-03-24
"""

from alembic import op
import sqlalchemy as sa

revision = '030'
down_revision = '029'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column('s3_empty_truck_weight_kg',  sa.String(20), nullable=True))
    op.add_column('trips', sa.Column('s3_loaded_truck_weight_kg', sa.String(20), nullable=True))


def downgrade() -> None:
    op.drop_column('trips', 's3_loaded_truck_weight_kg')
    op.drop_column('trips', 's3_empty_truck_weight_kg')
