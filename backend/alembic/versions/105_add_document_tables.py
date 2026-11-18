"""Add document tables (uploads stored in the database)

Revision ID: 105
Revises: 104
Create Date: 2026-11-05

Adds driver_documents, owner_documents, trip_documents and document_history, and
replaces the old, never-used vehicle_documents table with the new layout. Every
document table holds the file bytes (`content`, STORAGE EXTERNAL because the files
are already-compressed images) next to its metadata; a replace updates the row in
place and writes one document_history entry.

This migration only creates structure. No file is copied and no existing column
or file is touched. Plan: md/TESTS_NEXT_STEPS_AND_OPEN_FINDINGS.md.
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '105'
down_revision = '104'
branch_labels = None
depends_on = None

UUID = postgresql.UUID(as_uuid=True)


def _file_columns():
    """Columns every document table has (mirrors DocumentFileMixin)."""
    return [
        sa.Column('id', UUID, primary_key=True),
        sa.Column('url_path', sa.Text(), nullable=False),
        sa.Column('content', sa.LargeBinary(), nullable=False),
        sa.Column('content_type', sa.String(100), nullable=False),
        sa.Column('size_bytes', sa.Integer(), nullable=False),
        sa.Column('sha256', sa.String(64), nullable=False),
        sa.Column('file_name', sa.String(255), nullable=True),
        sa.Column('uploaded_by', UUID, sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploader_username', sa.String(150), nullable=True),
        sa.Column('uploader_role', sa.String(50), nullable=True),
        sa.Column('uploader_org_id', UUID, sa.ForeignKey('organizations.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploaded_via', sa.String(20), nullable=False, server_default='app'),
        sa.Column('uploader_ref', sa.String(200), nullable=True),
        sa.Column('uploaded_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('rr_file_id', sa.String(100), nullable=True),
        sa.Column('rr_synced_sha256', sa.String(64), nullable=True),
    ]


def _common_indexes(table):
    op.create_index(f'uq_{table}_url_path', table, ['url_path'], unique=True)
    op.create_index(f'ix_{table}_uploader', table, ['uploaded_by', sa.text('uploaded_at DESC')])
    op.create_index(f'ix_{table}_org', table, ['uploader_org_id'])


def _external_storage(table):
    # Only affects values written after this point, so it is set before any data exists.
    op.execute(f'ALTER TABLE {table} ALTER COLUMN content SET STORAGE EXTERNAL')


def upgrade():
    # The old vehicle_documents table has no writer in the app. Refuse to drop it if it holds rows.
    conn = op.get_bind()
    old_rows = conn.execute(sa.text('SELECT count(*) FROM vehicle_documents')).scalar()
    if old_rows:
        raise RuntimeError(
            f'vehicle_documents holds {old_rows} rows; it was expected to be empty. '
            'Stop and review before replacing it.'
        )
    op.drop_table('vehicle_documents')

    # ---- driver_documents ----
    op.create_table(
        'driver_documents',
        *_file_columns(),
        sa.Column('driver_id', UUID, sa.ForeignKey('drivers.id', ondelete='CASCADE'), nullable=True),
        sa.Column('rr_driver_id', sa.String(24), nullable=True),
        sa.Column('doc_type', sa.String(30), nullable=False),
        sa.Column('side', sa.String(5), nullable=False, server_default='front'),
        sa.Column('number', sa.String(50), nullable=True),
        sa.Column('holder_name', sa.String(200), nullable=True),
        sa.Column('expiry_date', sa.Date(), nullable=True),
        sa.Column('verified', sa.Boolean(), nullable=True),
        sa.CheckConstraint("doc_type IN ('driving_licence', 'aadhaar')", name='ck_driver_documents_doc_type'),
        sa.CheckConstraint("side IN ('front', 'back')", name='ck_driver_documents_side'),
        sa.CheckConstraint('driver_id IS NOT NULL OR rr_driver_id IS NOT NULL', name='ck_driver_documents_owner'),
    )
    _external_storage('driver_documents')
    _common_indexes('driver_documents')
    op.create_index('uq_driver_documents_driver', 'driver_documents', ['driver_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('driver_id IS NOT NULL'))
    op.create_index('uq_driver_documents_rr_driver', 'driver_documents', ['rr_driver_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('driver_id IS NULL'))
    op.create_index('ix_driver_documents_expiry', 'driver_documents', ['expiry_date'],
                    postgresql_where=sa.text('expiry_date IS NOT NULL'))
    op.create_index('ix_driver_documents_number', 'driver_documents', ['number'])

    # ---- vehicle_documents (new layout) ----
    op.create_table(
        'vehicle_documents',
        *_file_columns(),
        sa.Column('vehicle_id', UUID, sa.ForeignKey('vehicles.id', ondelete='CASCADE'), nullable=True),
        sa.Column('rr_vehicle_id', sa.String(24), nullable=True),
        sa.Column('doc_type', sa.String(30), nullable=False),
        sa.Column('side', sa.String(5), nullable=False, server_default='front'),
        sa.Column('number', sa.String(50), nullable=True),
        sa.Column('expiry_date', sa.Date(), nullable=True),
        sa.CheckConstraint(
            "doc_type IN ('registration_certificate', 'insurance', 'puc', 'fitness', 'permit')",
            name='ck_vehicle_documents_doc_type',
        ),
        sa.CheckConstraint("side IN ('front', 'back')", name='ck_vehicle_documents_side'),
        sa.CheckConstraint('vehicle_id IS NOT NULL OR rr_vehicle_id IS NOT NULL', name='ck_vehicle_documents_owner'),
    )
    _external_storage('vehicle_documents')
    _common_indexes('vehicle_documents')
    op.create_index('uq_vehicle_documents_vehicle', 'vehicle_documents', ['vehicle_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('vehicle_id IS NOT NULL'))
    op.create_index('uq_vehicle_documents_rr_vehicle', 'vehicle_documents', ['rr_vehicle_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('vehicle_id IS NULL'))
    op.create_index('ix_vehicle_documents_expiry', 'vehicle_documents', ['expiry_date'],
                    postgresql_where=sa.text('expiry_date IS NOT NULL'))

    # ---- owner_documents ----
    op.create_table(
        'owner_documents',
        *_file_columns(),
        sa.Column('organization_id', UUID, sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=True),
        sa.Column('rr_company_id', sa.String(24), nullable=True),
        sa.Column('doc_type', sa.String(30), nullable=False),
        sa.Column('side', sa.String(5), nullable=False, server_default='front'),
        sa.Column('number', sa.String(50), nullable=True),
        sa.Column('expiry_date', sa.Date(), nullable=True),
        sa.CheckConstraint("doc_type IN ('pan', 'tax_declaration', 'cancelled_cheque')", name='ck_owner_documents_doc_type'),
        sa.CheckConstraint("side IN ('front', 'back')", name='ck_owner_documents_side'),
        sa.CheckConstraint('organization_id IS NOT NULL OR rr_company_id IS NOT NULL', name='ck_owner_documents_owner'),
    )
    _external_storage('owner_documents')
    _common_indexes('owner_documents')
    op.create_index('uq_owner_documents_org', 'owner_documents', ['organization_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('organization_id IS NOT NULL'))
    op.create_index('uq_owner_documents_rr_company', 'owner_documents', ['rr_company_id', 'doc_type', 'side'],
                    unique=True, postgresql_where=sa.text('organization_id IS NULL'))
    op.create_index('ix_owner_documents_expiry', 'owner_documents', ['expiry_date'],
                    postgresql_where=sa.text('expiry_date IS NOT NULL'))
    op.create_index('ix_owner_documents_number', 'owner_documents', ['number'])

    # ---- trip_documents ----
    op.create_table(
        'trip_documents',
        *_file_columns(),
        sa.Column('trip_id', UUID, sa.ForeignKey('trips.id', ondelete='CASCADE'), nullable=False),
        sa.Column('doc_type', sa.String(40), nullable=False),
        sa.Column('slot', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('stage', sa.Integer(), nullable=False),
        sa.UniqueConstraint('trip_id', 'doc_type', 'slot', name='uq_trip_documents_slot'),
    )
    _external_storage('trip_documents')
    _common_indexes('trip_documents')

    # ---- document_history ----
    op.create_table(
        'document_history',
        sa.Column('id', UUID, primary_key=True),
        sa.Column('kind', sa.String(20), nullable=False),
        sa.Column('document_id', UUID, nullable=False),
        sa.Column('owner_ref', sa.String(100), nullable=True),
        sa.Column('doc_type', sa.String(40), nullable=False),
        sa.Column('old_sha256', sa.String(64), nullable=True),
        sa.Column('old_size_bytes', sa.Integer(), nullable=True),
        sa.Column('old_uploaded_by', UUID, nullable=True),
        sa.Column('old_uploader_username', sa.String(150), nullable=True),
        sa.Column('old_uploaded_at', sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column('replaced_by', UUID, nullable=True),
        sa.Column('replaced_by_username', sa.String(150), nullable=True),
        sa.Column('replaced_by_role', sa.String(50), nullable=True),
        sa.Column('replaced_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('reason', sa.String(100), nullable=True),
        sa.Column('reason_note', sa.Text(), nullable=True),
        sa.CheckConstraint(
            "kind IN ('driver', 'vehicle', 'owner', 'trip', 'receiving', 'logo')",
            name='ck_document_history_kind',
        ),
    )
    op.create_index('ix_document_history_document', 'document_history',
                    ['kind', 'document_id', sa.text('replaced_at DESC')])
    op.create_index('ix_document_history_replaced_by', 'document_history', ['replaced_by'])


def downgrade():
    op.drop_table('document_history')
    op.drop_table('trip_documents')
    op.drop_table('owner_documents')
    op.drop_table('vehicle_documents')
    op.drop_table('driver_documents')

    # Restore the old (empty) vehicle_documents table exactly as migration 005 created it.
    op.create_table(
        'vehicle_documents',
        sa.Column('id', UUID, primary_key=True),
        sa.Column('vehicle_id', UUID, sa.ForeignKey('vehicles.id', ondelete='CASCADE'), nullable=False),
        sa.Column('document_type', sa.String(50), nullable=False),
        sa.Column('document_name', sa.String(255), nullable=False),
        sa.Column('file_path', sa.String(500), nullable=False),
        sa.Column('file_size', sa.Integer, nullable=False),
        sa.Column('mime_type', sa.String(100), nullable=False),
        sa.Column('expiry_date', sa.Date, nullable=True),
        sa.Column('uploaded_by', UUID, sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploaded_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column('notes', sa.Text, nullable=True),
        sa.CheckConstraint(
            "document_type IN ('registration', 'insurance', 'pollution_cert', 'fitness_cert', 'permit', 'tax_receipt', 'other')",
            name='check_document_type',
        ),
    )
    op.create_index('idx_vehicle_documents_vehicle_id', 'vehicle_documents', ['vehicle_id'])
    op.create_index('idx_vehicle_documents_document_type', 'vehicle_documents', ['document_type'])
    op.create_index('idx_vehicle_documents_expiry_date', 'vehicle_documents', ['expiry_date'])
