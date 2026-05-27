"""
MaterialType Model
Local cache of RR's material_types collection.
Used for trip form autocomplete and resolving rr_material_id at form-fill time.
"""

from sqlalchemy import Column, String, TIMESTAMP, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class MaterialType(Base):
    __tablename__ = "material_types"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name           = Column(String(100), nullable=False, unique=True)
    rr_material_id = Column(String(24), nullable=True)   # MongoDB ObjectId from RR
    created_at     = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    def to_dict(self):
        return {
            "id":             str(self.id),
            "name":           self.name,
            "rr_material_id": self.rr_material_id,
            "created_at":     self.created_at.isoformat() if self.created_at else None,
        }
