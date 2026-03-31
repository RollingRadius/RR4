"""Track which worker is currently working on each trip stage

Revision ID: 042
Revises: 041
Create Date: 2026-03-31
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '042'
down_revision = '041'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Use IF NOT EXISTS so this is safe even if columns were added via direct SQL
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s1_claimed_by UUID"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s2_claimed_by UUID"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s3_claimed_by UUID"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s4_claimed_by UUID"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s1_claimed_at TIMESTAMP WITH TIME ZONE"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s2_claimed_at TIMESTAMP WITH TIME ZONE"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s3_claimed_at TIMESTAMP WITH TIME ZONE"))
    op.execute(sa.text("ALTER TABLE trips ADD COLUMN IF NOT EXISTS s4_claimed_at TIMESTAMP WITH TIME ZONE"))


def downgrade() -> None:
    op.drop_column('trips', 's4_claimed_at')
    op.drop_column('trips', 's3_claimed_at')
    op.drop_column('trips', 's2_claimed_at')
    op.drop_column('trips', 's1_claimed_at')
    op.drop_column('trips', 's4_claimed_by')
    op.drop_column('trips', 's3_claimed_by')
    op.drop_column('trips', 's2_claimed_by')
    op.drop_column('trips', 's1_claimed_by')
