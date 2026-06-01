"""Add consignee_rr_company_id to trips

Revision ID: 062
Revises: 061
Create Date: 2026-06-01

Stores the RR MongoDB ObjectId for the consignee company directly on the trip,
so we no longer need the consignee to be a registered organisation in RR4.
"""

from alembic import op
import sqlalchemy as sa

revision = '062'
down_revision = '061'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('trips',
        sa.Column('consignee_rr_company_id', sa.String(), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('trips', 'consignee_rr_company_id')
