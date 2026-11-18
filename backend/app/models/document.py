"""
Document tables: uploaded files stored in PostgreSQL, one current row per document.

driver_documents, vehicle_documents, owner_documents and trip_documents each hold
the file bytes themselves. A replace updates the row in place and writes one
document_history entry; the old bytes are not kept. `content` is deferred, so a
normal query never reads it.
"""

import uuid

from sqlalchemy import (
    Boolean, CheckConstraint, Column, Date, ForeignKey, Index, Integer, LargeBinary,
    String, Text, TIMESTAMP, UniqueConstraint, text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import declared_attr, deferred, relationship
from sqlalchemy.sql import func

from app.database import Base


class DocumentFileMixin:
    """Columns every document table has."""

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    url_path = Column(Text, nullable=False)  # the /uploads/... URL; unique per table
    content_type = Column(String(100), nullable=False)
    size_bytes = Column(Integer, nullable=False)
    sha256 = Column(String(64), nullable=False)
    file_name = Column(String(255), nullable=True)

    uploaded_via = Column(String(20), nullable=False, default="app", server_default="app")
    uploader_username = Column(String(150), nullable=True)
    uploader_role = Column(String(50), nullable=True)
    uploader_ref = Column(String(200), nullable=True)  # set only when there is no user
    uploaded_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    rr_file_id = Column(String(100), nullable=True)
    rr_synced_sha256 = Column(String(64), nullable=True)

    @declared_attr
    def content(cls):
        return deferred(Column(LargeBinary, nullable=False))

    @declared_attr
    def uploaded_by(cls):
        return Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    @declared_attr
    def uploader_org_id(cls):
        return Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="SET NULL"), nullable=True)


class DriverDocument(DocumentFileMixin, Base):
    """A driver's Driving Licence or Aadhaar (one row per document side)."""

    __tablename__ = "driver_documents"

    driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id", ondelete="CASCADE"), nullable=True)
    rr_driver_id = Column(String(24), nullable=True)
    doc_type = Column(String(30), nullable=False)
    side = Column(String(5), nullable=False, default="front", server_default="front")
    number = Column(String(50), nullable=True)
    holder_name = Column(String(200), nullable=True)
    expiry_date = Column(Date, nullable=True)
    verified = Column(Boolean, nullable=True)

    __table_args__ = (
        CheckConstraint("doc_type IN ('driving_licence', 'aadhaar')", name="ck_driver_documents_doc_type"),
        CheckConstraint("side IN ('front', 'back')", name="ck_driver_documents_side"),
        CheckConstraint("driver_id IS NOT NULL OR rr_driver_id IS NOT NULL", name="ck_driver_documents_owner"),
        Index("uq_driver_documents_url_path", "url_path", unique=True),
        Index("uq_driver_documents_driver", "driver_id", "doc_type", "side",
              unique=True, postgresql_where=text("driver_id IS NOT NULL")),
        Index("uq_driver_documents_rr_driver", "rr_driver_id", "doc_type", "side",
              unique=True, postgresql_where=text("driver_id IS NULL")),
        Index("ix_driver_documents_uploader", "uploaded_by", text("uploaded_at DESC")),
        Index("ix_driver_documents_org", "uploader_org_id"),
        Index("ix_driver_documents_expiry", "expiry_date", postgresql_where=text("expiry_date IS NOT NULL")),
        Index("ix_driver_documents_number", "number"),
    )


class VehicleDocument(DocumentFileMixin, Base):
    """A vehicle's RC, insurance, PUC, fitness or permit (one row per document side)."""

    __tablename__ = "vehicle_documents"

    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=True)
    rr_vehicle_id = Column(String(24), nullable=True)
    doc_type = Column(String(30), nullable=False)
    side = Column(String(5), nullable=False, default="front", server_default="front")
    number = Column(String(50), nullable=True)
    expiry_date = Column(Date, nullable=True)

    vehicle = relationship("Vehicle", back_populates="documents")

    __table_args__ = (
        CheckConstraint(
            "doc_type IN ('registration_certificate', 'insurance', 'puc', 'fitness', 'permit')",
            name="ck_vehicle_documents_doc_type",
        ),
        CheckConstraint("side IN ('front', 'back')", name="ck_vehicle_documents_side"),
        CheckConstraint("vehicle_id IS NOT NULL OR rr_vehicle_id IS NOT NULL", name="ck_vehicle_documents_owner"),
        Index("uq_vehicle_documents_url_path", "url_path", unique=True),
        Index("uq_vehicle_documents_vehicle", "vehicle_id", "doc_type", "side",
              unique=True, postgresql_where=text("vehicle_id IS NOT NULL")),
        Index("uq_vehicle_documents_rr_vehicle", "rr_vehicle_id", "doc_type", "side",
              unique=True, postgresql_where=text("vehicle_id IS NULL")),
        Index("ix_vehicle_documents_uploader", "uploaded_by", text("uploaded_at DESC")),
        Index("ix_vehicle_documents_org", "uploader_org_id"),
        Index("ix_vehicle_documents_expiry", "expiry_date", postgresql_where=text("expiry_date IS NOT NULL")),
    )


class OwnerDocument(DocumentFileMixin, Base):
    """A vehicle owner's PAN, tax declaration or cancelled cheque."""

    __tablename__ = "owner_documents"

    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=True)
    rr_company_id = Column(String(24), nullable=True)
    doc_type = Column(String(30), nullable=False)
    side = Column(String(5), nullable=False, default="front", server_default="front")
    number = Column(String(50), nullable=True)
    expiry_date = Column(Date, nullable=True)

    __table_args__ = (
        CheckConstraint(
            "doc_type IN ('pan', 'tax_declaration', 'cancelled_cheque')",
            name="ck_owner_documents_doc_type",
        ),
        CheckConstraint("side IN ('front', 'back')", name="ck_owner_documents_side"),
        CheckConstraint("organization_id IS NOT NULL OR rr_company_id IS NOT NULL", name="ck_owner_documents_owner"),
        Index("uq_owner_documents_url_path", "url_path", unique=True),
        Index("uq_owner_documents_org", "organization_id", "doc_type", "side",
              unique=True, postgresql_where=text("organization_id IS NOT NULL")),
        Index("uq_owner_documents_rr_company", "rr_company_id", "doc_type", "side",
              unique=True, postgresql_where=text("organization_id IS NULL")),
        Index("ix_owner_documents_uploader", "uploaded_by", text("uploaded_at DESC")),
        Index("ix_owner_documents_org", "uploader_org_id"),
        Index("ix_owner_documents_expiry", "expiry_date", postgresql_where=text("expiry_date IS NOT NULL")),
        Index("ix_owner_documents_number", "number"),
    )


class TripDocument(DocumentFileMixin, Base):
    """A document that belongs to one trip (loading slip, weight slip, POD and so on)."""

    __tablename__ = "trip_documents"

    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False)
    doc_type = Column(String(40), nullable=False)
    slot = Column(Integer, nullable=False, default=0, server_default="0")
    stage = Column(Integer, nullable=False)

    __table_args__ = (
        UniqueConstraint("trip_id", "doc_type", "slot", name="uq_trip_documents_slot"),
        Index("uq_trip_documents_url_path", "url_path", unique=True),
        Index("ix_trip_documents_uploader", "uploaded_by", text("uploaded_at DESC")),
        Index("ix_trip_documents_org", "uploader_org_id"),
    )


class DocumentHistory(Base):
    """Append-only record of one replacement. Text and numbers only, never the old file."""

    __tablename__ = "document_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    kind = Column(String(20), nullable=False)
    document_id = Column(UUID(as_uuid=True), nullable=False)
    owner_ref = Column(String(100), nullable=True)
    doc_type = Column(String(40), nullable=False)

    old_sha256 = Column(String(64), nullable=True)
    old_size_bytes = Column(Integer, nullable=True)
    old_uploaded_by = Column(UUID(as_uuid=True), nullable=True)
    old_uploader_username = Column(String(150), nullable=True)
    old_uploaded_at = Column(TIMESTAMP(timezone=True), nullable=True)

    replaced_by = Column(UUID(as_uuid=True), nullable=True)
    replaced_by_username = Column(String(150), nullable=True)
    replaced_by_role = Column(String(50), nullable=True)
    replaced_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
    reason = Column(String(100), nullable=True)
    reason_note = Column(Text, nullable=True)

    __table_args__ = (
        CheckConstraint(
            "kind IN ('driver', 'vehicle', 'owner', 'trip', 'receiving', 'logo')",
            name="ck_document_history_kind",
        ),
        Index("ix_document_history_document", "kind", "document_id", text("replaced_at DESC")),
        Index("ix_document_history_replaced_by", "replaced_by"),
    )
