"""
Receiving Document Model

Backs the "Receiving Documents" LP/RR-ops feature: a physical receiving
acknowledgment sometimes comes back as ONE sheet covering multiple trips
(photographed as a single image), unlike every other trip document (loading
slip, POD, e-way bill, ...) which is strictly one-document-per-trip. A
ReceivingDocument is the uploaded image; ReceivingDocumentTrip is the
many-to-many link connecting it to each trip it covers.
"""

from sqlalchemy import Column, Text, TIMESTAMP, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from app.database import Base


class ReceivingDocument(Base):
    __tablename__ = "receiving_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    file_url = Column(Text, nullable=False)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"),
                              nullable=False, index=True)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    trip_links = relationship("ReceivingDocumentTrip", backref="document", cascade="all, delete-orphan")


class ReceivingDocumentTrip(Base):
    """Many-to-many link: one ReceivingDocument -> many trips. trip_id is
    UNIQUE — a trip can only ever be linked to one receiving document at a
    time (a deliberate "one for now" product decision, enforced at the DB
    level so a second upload naming an already-linked trip fails cleanly
    instead of silently double-linking it)."""
    __tablename__ = "receiving_document_trips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    receiving_document_id = Column(UUID(as_uuid=True), ForeignKey("receiving_documents.id", ondelete="CASCADE"),
                                    nullable=False, index=True)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        UniqueConstraint('trip_id', name='uq_receiving_document_trips_trip_id'),
    )
