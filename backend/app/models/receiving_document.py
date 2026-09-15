"""
Receiving Document Model

Backs the "Receiving Documents" LP/RR-ops feature: a physical receiving
acknowledgment (photographed as a single image) is looked up by the date
it was uploaded for, not linked to specific trips.
"""

from sqlalchemy import Column, Text, Date, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class ReceivingDocument(Base):
    __tablename__ = "receiving_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    file_url = Column(Text, nullable=False)
    doc_date = Column(Date, nullable=False, index=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"),
                              nullable=False, index=True)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())
