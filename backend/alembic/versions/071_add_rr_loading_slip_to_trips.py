"""Add rr_loading_slip_file_id and rr_loading_slip_url to trips

Revision ID: 071
Revises: 070
Create Date: 2026-06-10

For RR web trips (created via POST /create_trip):
- rr_loading_slip_file_id : ObjectId returned by RR /files after upload
- rr_loading_slip_url     : our local saved copy path (mirrors s2_loading_slip_url for RR flow)
"""

from alembic import op
import sqlalchemy as sa

revision = '071'
down_revision = '070'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('rr_loading_slip_file_id', sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('rr_loading_slip_url',     sa.String(500), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_loading_slip_url')
    op.drop_column('trips', 'rr_loading_slip_file_id')
