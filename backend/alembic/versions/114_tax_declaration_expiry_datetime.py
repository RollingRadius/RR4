"""Tax declaration valid-till becomes a date AND time (UTC), like RR web (user, 2026-11-24).

RR keeps it as a UTC date-time and RR web lets its user pick a date and a time in India time. Our app kept a date only
and sent 00:00 UTC (RR web showed 05:30 AM). Existing values keep exactly that meaning: the date at 00:00 UTC.
Columns: trips.s1_tax_declaration_expiry, owner_documents.expiry_date (the stored owner paper's valid-till).

Revision ID: 114
Revises: 113
"""

import sqlalchemy as sa
from alembic import op

revision = '114'
down_revision = '113'
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column('trips', 's1_tax_declaration_expiry', type_=sa.TIMESTAMP(timezone=True),
                    postgresql_using="(s1_tax_declaration_expiry::timestamp AT TIME ZONE 'UTC')")
    op.alter_column('owner_documents', 'expiry_date', type_=sa.TIMESTAMP(timezone=True),
                    postgresql_using="(expiry_date::timestamp AT TIME ZONE 'UTC')")


def downgrade():
    op.alter_column('owner_documents', 'expiry_date', type_=sa.Date(),
                    postgresql_using="((expiry_date AT TIME ZONE 'UTC')::date)")
    op.alter_column('trips', 's1_tax_declaration_expiry', type_=sa.Date(),
                    postgresql_using="((s1_tax_declaration_expiry AT TIME ZONE 'UTC')::date)")
