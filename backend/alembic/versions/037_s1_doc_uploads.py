"""Stage 1 — replace text fields with upload URL columns

Revision ID: 037
Revises: 036
Create Date: 2026-03-27
"""

from alembic import op
import sqlalchemy as sa

revision = '037'
down_revision = '036'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # New columns for DL and Aadhaar photo uploads
    op.add_column('trips', sa.Column('s1_driving_license_url', sa.Text, nullable=True))
    op.add_column('trips', sa.Column('s1_aadhaar_url',         sa.Text, nullable=True))
    # Widen existing doc columns from VARCHAR to TEXT so they can store URL paths
    op.alter_column('trips', 's1_rc',
                    existing_type=sa.String(50),  type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_insurance',
                    existing_type=sa.String(50),  type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_pollution',
                    existing_type=sa.String(50),  type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_fitness',
                    existing_type=sa.String(50),  type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_pan',
                    existing_type=sa.String(20),  type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_tax_declaration',
                    existing_type=sa.String(100), type_=sa.Text, existing_nullable=True)
    op.alter_column('trips', 's1_cancelled_cheque',
                    existing_type=sa.String(100), type_=sa.Text, existing_nullable=True)


def downgrade() -> None:
    op.drop_column('trips', 's1_driving_license_url')
    op.drop_column('trips', 's1_aadhaar_url')
    op.alter_column('trips', 's1_rc',
                    existing_type=sa.Text, type_=sa.String(50),  existing_nullable=True)
    op.alter_column('trips', 's1_insurance',
                    existing_type=sa.Text, type_=sa.String(50),  existing_nullable=True)
    op.alter_column('trips', 's1_pollution',
                    existing_type=sa.Text, type_=sa.String(50),  existing_nullable=True)
    op.alter_column('trips', 's1_fitness',
                    existing_type=sa.Text, type_=sa.String(50),  existing_nullable=True)
    op.alter_column('trips', 's1_pan',
                    existing_type=sa.Text, type_=sa.String(20),  existing_nullable=True)
    op.alter_column('trips', 's1_tax_declaration',
                    existing_type=sa.Text, type_=sa.String(100), existing_nullable=True)
    op.alter_column('trips', 's1_cancelled_cheque',
                    existing_type=sa.Text, type_=sa.String(100), existing_nullable=True)
