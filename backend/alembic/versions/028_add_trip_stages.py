"""add 3-stage trip compliance fields

Changes:
  - trips.current_stage  INT default 0  (0=not started,1=s1 done,2=s2 done,3=complete)
  - Stage 1: driver registration data (text fields)
  - Stage 2: pre-arrival compliance booleans
  - Stage 3: truck arrival safety booleans

Revision ID: 028
Revises: 027
Create Date: 2026-03-23
"""

from alembic import op
import sqlalchemy as sa

revision = '028'
down_revision = '027'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Stage tracking
    op.add_column('trips', sa.Column('current_stage', sa.Integer(), nullable=False, server_default='0'))

    # ── Stage 1: Truck Detail Registration ──────────────────────────────────
    op.add_column('trips', sa.Column('s1_driver_name',       sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('s1_driver_phone',      sa.String(20),  nullable=True))
    op.add_column('trips', sa.Column('s1_driving_license',   sa.String(50),  nullable=True))
    op.add_column('trips', sa.Column('s1_aadhaar',           sa.String(20),  nullable=True))
    op.add_column('trips', sa.Column('s1_rc',                sa.String(50),  nullable=True))
    op.add_column('trips', sa.Column('s1_insurance',         sa.String(50),  nullable=True))
    op.add_column('trips', sa.Column('s1_pollution',         sa.String(50),  nullable=True))
    op.add_column('trips', sa.Column('s1_fitness',           sa.String(50),  nullable=True))
    op.add_column('trips', sa.Column('s1_pan',               sa.String(20),  nullable=True))
    op.add_column('trips', sa.Column('s1_tax_declaration',   sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('s1_cancelled_cheque',  sa.String(100), nullable=True))
    op.add_column('trips', sa.Column('s1_submitted_at',      sa.TIMESTAMP(timezone=True), nullable=True))

    # ── Stage 2: Pre-Arrival Compliance Check ────────────────────────────────
    op.add_column('trips', sa.Column('s2_specs_verified',        sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s2_docs_verified',         sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s2_driver_docs_valid',     sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s2_entry_permission',      sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s2_verified_at',           sa.TIMESTAMP(timezone=True), nullable=True))

    # ── Stage 3: Truck Arrival at Factory ────────────────────────────────────
    op.add_column('trips', sa.Column('s3_driver_parked',         sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_docs_submitted',        sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_security_verified',     sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_driver_exited_cabin',   sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_wheel_stoppers',        sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_safety_gear',           sa.Boolean(), nullable=True))
    op.add_column('trips', sa.Column('s3_completed_at',          sa.TIMESTAMP(timezone=True), nullable=True))


def downgrade() -> None:
    for col in [
        's3_completed_at', 's3_safety_gear', 's3_wheel_stoppers', 's3_driver_exited_cabin',
        's3_security_verified', 's3_docs_submitted', 's3_driver_parked',
        's2_verified_at', 's2_entry_permission', 's2_driver_docs_valid',
        's2_docs_verified', 's2_specs_verified',
        's1_submitted_at', 's1_cancelled_cheque', 's1_tax_declaration', 's1_pan',
        's1_fitness', 's1_pollution', 's1_insurance', 's1_rc',
        's1_aadhaar', 's1_driving_license', 's1_driver_phone', 's1_driver_name',
        'current_stage',
    ]:
        op.drop_column('trips', col)
