"""add weight unit columns to trips stage 3

Stores the unit (tons or kg) separately from the weight value so both
can be persisted and displayed accurately.

Revision ID: 032
Revises: 031
Create Date: 2026-03-24
"""

from alembic import op
import sqlalchemy as sa

revision = '032'
down_revision = '031'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips', sa.Column(
        's3_empty_truck_weight_unit', sa.String(10),
        nullable=True, server_default='tons'
    ))
    op.add_column('trips', sa.Column(
        's3_loaded_truck_weight_unit', sa.String(10),
        nullable=True, server_default='tons'
    ))


def downgrade() -> None:
    op.drop_column('trips', 's3_loaded_truck_weight_unit')
    op.drop_column('trips', 's3_empty_truck_weight_unit')
