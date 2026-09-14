"""Add receiving_documents and receiving_document_trips tables

Revision ID: 099
Revises: 098
Create Date: 2026-09-14

Backs the "Receiving Docs" LP/RR-ops feature: one uploaded image (a
physical receiving sheet covering multiple trips) linked to many trips via
receiving_document_trips. trip_id is UNIQUE there — one receiving document
per trip for now, enforced at the DB level.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '099'
down_revision = '098'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'receiving_documents',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('file_url', sa.Text(), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['uploaded_by'], ['users.id'], ondelete='SET NULL'),
    )
    op.create_index('ix_receiving_documents_organization_id', 'receiving_documents', ['organization_id'])

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


def downgrade():
    op.drop_index('ix_receiving_document_trips_receiving_document_id', table_name='receiving_document_trips')
    op.drop_table('receiving_document_trips')
    op.drop_index('ix_receiving_documents_organization_id', table_name='receiving_documents')
    op.drop_table('receiving_documents')
