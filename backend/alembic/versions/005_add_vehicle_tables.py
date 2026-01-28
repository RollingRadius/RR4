"""Add vehicle tables

Revision ID: 005_add_vehicle_tables
Revises: 004_add_capability_system
Create Date: 2026-01-28 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB
import uuid

# revision identifiers
revision: str = '005_add_vehicle_tables'
down_revision: Union[str, None] = '004_add_capability_system'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create vehicles table
    op.create_table(
        'vehicles',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column('organization_id', UUID(as_uuid=True), sa.ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False),
        sa.Column('vehicle_number', sa.String(50), nullable=False),
        sa.Column('registration_number', sa.String(50), nullable=False),
        sa.Column('manufacturer', sa.String(100), nullable=False),
        sa.Column('model', sa.String(100), nullable=False),
        sa.Column('year', sa.Integer, nullable=False),
        sa.Column('vehicle_type', sa.String(50), nullable=False),
        sa.Column('fuel_type', sa.String(20), nullable=False),
        sa.Column('capacity', sa.Integer, nullable=True),
        sa.Column('color', sa.String(50), nullable=True),
        sa.Column('vin_number', sa.String(17), nullable=True),
        sa.Column('engine_number', sa.String(50), nullable=True),
        sa.Column('chassis_number', sa.String(50), nullable=True),
        sa.Column('purchase_date', sa.Date, nullable=True),
        sa.Column('purchase_price', sa.Numeric(12, 2), nullable=True),
        sa.Column('current_driver_id', UUID(as_uuid=True), sa.ForeignKey('drivers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('current_odometer', sa.Integer, nullable=False, server_default='0'),
        sa.Column('status', sa.String(20), nullable=False, server_default='active'),
        sa.Column('insurance_provider', sa.String(255), nullable=True),
        sa.Column('insurance_policy_number', sa.String(100), nullable=True),
        sa.Column('insurance_expiry_date', sa.Date, nullable=True),
        sa.Column('registration_expiry_date', sa.Date, nullable=True),
        sa.Column('pollution_certificate_expiry', sa.Date, nullable=True),
        sa.Column('fitness_certificate_expiry', sa.Date, nullable=True),
        sa.Column('notes', sa.Text, nullable=True),
        sa.Column('created_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, nullable=False, server_default=sa.func.now(), onupdate=sa.func.now()),

        # Constraints
        sa.CheckConstraint(
            "status IN ('active', 'inactive', 'maintenance', 'decommissioned')",
            name='check_vehicle_status'
        ),
        sa.CheckConstraint(
            "vehicle_type IN ('truck', 'bus', 'van', 'car', 'motorcycle', 'other')",
            name='check_vehicle_type'
        ),
        sa.CheckConstraint(
            "fuel_type IN ('petrol', 'diesel', 'electric', 'hybrid', 'cng', 'lpg')",
            name='check_fuel_type'
        ),
        sa.CheckConstraint(
            "year >= 1900 AND year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1",
            name='check_vehicle_year'
        ),
        sa.CheckConstraint(
            "current_odometer >= 0",
            name='check_odometer_positive'
        ),
        sa.UniqueConstraint('registration_number', name='uq_registration_number'),
        sa.UniqueConstraint('vin_number', name='uq_vin_number'),
    )

    # Create unique index for vehicle_number within organization
    op.create_index(
        'idx_org_vehicle_number',
        'vehicles',
        ['organization_id', 'vehicle_number'],
        unique=True
    )

    # Create indexes for common queries
    op.create_index('idx_vehicles_organization_id', 'vehicles', ['organization_id'])
    op.create_index('idx_vehicles_status', 'vehicles', ['status'])
    op.create_index('idx_vehicles_vehicle_type', 'vehicles', ['vehicle_type'])
    op.create_index('idx_vehicles_current_driver_id', 'vehicles', ['current_driver_id'])
    op.create_index('idx_vehicles_created_at', 'vehicles', ['created_at'])

    # Create vehicle_documents table
    op.create_table(
        'vehicle_documents',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column('vehicle_id', UUID(as_uuid=True), sa.ForeignKey('vehicles.id', ondelete='CASCADE'), nullable=False),
        sa.Column('document_type', sa.String(50), nullable=False),
        sa.Column('document_name', sa.String(255), nullable=False),
        sa.Column('file_path', sa.String(500), nullable=False),
        sa.Column('file_size', sa.Integer, nullable=False),
        sa.Column('mime_type', sa.String(100), nullable=False),
        sa.Column('expiry_date', sa.Date, nullable=True),
        sa.Column('uploaded_by', UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('uploaded_at', sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column('notes', sa.Text, nullable=True),

        # Constraints
        sa.CheckConstraint(
            "document_type IN ('registration', 'insurance', 'pollution_cert', 'fitness_cert', 'permit', 'tax_receipt', 'other')",
            name='check_document_type'
        ),
    )

    # Create indexes for vehicle_documents
    op.create_index('idx_vehicle_documents_vehicle_id', 'vehicle_documents', ['vehicle_id'])
    op.create_index('idx_vehicle_documents_document_type', 'vehicle_documents', ['document_type'])
    op.create_index('idx_vehicle_documents_expiry_date', 'vehicle_documents', ['expiry_date'])


def downgrade() -> None:
    # Drop tables in reverse order
    op.drop_table('vehicle_documents')
    op.drop_table('vehicles')
