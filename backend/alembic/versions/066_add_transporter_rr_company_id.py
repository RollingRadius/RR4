"""Add transporter_rr_company_id to trips

Revision ID: 066
Revises: 065
Create Date: 2026-06-05

Stores the RR company ObjectId for vehicle_provider_id in POST /create_trip.
Set at assign-transporter time: transporter org's rr_company_id if available,
else Rolling Radius default (62d66794e54f47829a886a1d).
"""

from alembic import op
import sqlalchemy as sa

revision = '066'
down_revision = '065'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('transporter_rr_company_id', sa.String(24), nullable=True))


def downgrade():
    op.drop_column('trips', 'transporter_rr_company_id')
