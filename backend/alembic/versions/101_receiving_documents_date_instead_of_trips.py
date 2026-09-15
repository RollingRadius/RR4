"""Link receiving documents to a date instead of trips

Revision ID: 101
Revises: 100
Create Date: 2026-09-15

Product change: a receiving doc is now looked up by the date it was
uploaded for, not by linking it to specific trips. Adds
receiving_documents.doc_date (backfilled from created_at for any existing
rows) and drops the now-unused receiving_document_trips link table.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '101'
down_revision = '100'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('receiving_documents', sa.Column('doc_date', sa.Date(), nullable=True))
    op.execute("UPDATE receiving_documents SET doc_date = created_at::date WHERE doc_date IS NULL")
    op.alter_column('receiving_documents', 'doc_date', nullable=False)
    op.create_index('ix_receiving_documents_doc_date', 'receiving_documents', ['doc_date'])

    op.drop_index('ix_receiving_document_trips_receiving_document_id', table_name='receiving_document_trips')
    op.drop_table('receiving_document_trips')


def downgrade():
    op.create_table(
        'receiving_document_trips',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('receiving_document_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('trip_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['receiving_document_id'], ['receiving_documents.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['trip_id'], ['trips.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('trip_id', name='uq_receiving_document_trips_trip_id'),
    )
    op.create_index('ix_receiving_document_trips_receiving_document_id', 'receiving_document_trips', ['receiving_document_id'])

    op.drop_index('ix_receiving_documents_doc_date', table_name='receiving_documents')
    op.drop_column('receiving_documents', 'doc_date')
