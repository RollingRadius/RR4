"""Add RC back photo and number fields for RC/PUC/Fitness/Permit/Insurance

Revision ID: 083
Revises: 082
Create Date: 2026-07-31

RC back is a genuine RR capability (Registration Certificate supports a
back-side photo, unlike PUC/Fitness/Permit which are front-only even on RR
web) that our app never captured. Number fields for RC/PUC/Fitness/Permit/
Insurance mirror the existing DL/Aadhaar number fields (s1_driving_license,
s1_aadhaar) that already exist for driver docs — the vehicle side never had
equivalents, even though RR's schema supports a `number`/`policy_number`
field for each of these.
"""

from alembic import op
import sqlalchemy as sa

revision = '083'
down_revision = '082'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('trips', sa.Column('s1_rc_back', sa.Text(), nullable=True))
    op.add_column('trips', sa.Column('rr_rc_back_file_id', sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('s1_rc_number', sa.String(50), nullable=True))
    op.add_column('trips', sa.Column('s1_puc_number', sa.String(50), nullable=True))
    op.add_column('trips', sa.Column('s1_fitness_number', sa.String(50), nullable=True))
    op.add_column('trips', sa.Column('s1_permit_number', sa.String(50), nullable=True))
    op.add_column('trips', sa.Column('s1_insurance_number', sa.String(50), nullable=True))
    # Insurance was never synced before (separate RR field, not part of
    # identities[]) so it never had a pushed-photo cache column either.
    op.add_column('trips', sa.Column('rr_insurance_file_id', sa.String(100), nullable=True))


def downgrade():
    op.drop_column('trips', 'rr_insurance_file_id')
    op.drop_column('trips', 's1_insurance_number')
    op.drop_column('trips', 's1_permit_number')
    op.drop_column('trips', 's1_fitness_number')
    op.drop_column('trips', 's1_puc_number')
    op.drop_column('trips', 's1_rc_number')
    op.drop_column('trips', 'rr_rc_back_file_id')
    op.drop_column('trips', 's1_rc_back')
