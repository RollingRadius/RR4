"""Add consignor_rr_company_id to trips

Revision ID: 063
Revises: 062
Create Date: 2026-06-01

Stores the RR MongoDB ObjectId for the consignor company directly on the trip,
selected by the LP from the RR company picker instead of derived from the load
owner organisation's rr_company_id.
"""

from alembic import op
import sqlalchemy as sa

revision = '063'
down_revision = '062'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips',
        sa.Column('consignor_rr_company_id', sa.String(), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('trips', 'consignor_rr_company_id')
