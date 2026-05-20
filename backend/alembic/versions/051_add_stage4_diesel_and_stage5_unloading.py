"""add stage4 diesel receipt and stage5 unloading columns

Revision ID: 051
Revises: 050
Create Date: 2026-05-16
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '051'
down_revision = '050'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Stage 4 — Diesel Receipt (uploaded after truck exits factory)
    op.add_column('trips', sa.Column('s4_diesel_receipt_url', sa.Text(), nullable=True))

    # Stage 5 — Unloading (Proof of Delivery + Halting Charge)
    op.add_column('trips', sa.Column('s5_pod_url',        sa.Text(),                        nullable=True))
    op.add_column('trips', sa.Column('s5_halting_charge', sa.Numeric(12, 2),               nullable=True))
    op.add_column('trips', sa.Column('s5_submitted_by',   UUID(as_uuid=True),              nullable=True))
    op.add_column('trips', sa.Column('s5_completed_at',   sa.TIMESTAMP(timezone=True),     nullable=True))


def downgrade() -> None:
    op.drop_column('trips', 's5_completed_at')
    op.drop_column('trips', 's5_submitted_by')
    op.drop_column('trips', 's5_halting_charge')
    op.drop_column('trips', 's5_pod_url')
    op.drop_column('trips', 's4_diesel_receipt_url')
