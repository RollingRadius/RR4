"""
Capability Model - Hardcoded permission identifiers
"""
from sqlalchemy import Column, String, Boolean, JSON, Text, DateTime, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid
import enum

from app.database import Base


class AccessLevel(str, enum.Enum):
    """Access levels for capabilities"""
    NONE = "none"
    VIEW = "view"
    LIMITED = "limited"
    FULL = "full"


class FeatureCategory(str, enum.Enum):
    """Feature categories for grouping capabilities"""
    USER_MANAGEMENT = "user_management"
    ROLE_MANAGEMENT = "role_management"
    VEHICLE_MANAGEMENT = "vehicle_management"
    DRIVER_MANAGEMENT = "driver_management"
    TRIP_MANAGEMENT = "trip_management"
    TRACKING = "tracking"
    FINANCIAL = "financial"
    MAINTENANCE = "maintenance"
    COMPLIANCE = "compliance"
    CUSTOMER = "customer"
    REPORTING = "reporting"
    SYSTEM = "system"


class Capability(Base):
    """
    Capability model - stores hardcoded capability definitions.
    These are defined in code and seeded into database.
    """
    __tablename__ = "capabilities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    capability_key = Column(String(100), unique=True, nullable=False, index=True)
    feature_category = Column(SQLEnum(FeatureCategory), nullable=False, index=True)
    capability_name = Column(String(100), nullable=False)
    description = Column(Text)
    access_levels = Column(JSON, nullable=False)  # List of allowed access levels
    is_system_critical = Column(Boolean, default=False)  # Reserved for Super Admin
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Capability {self.capability_key}>"

    def to_dict(self):
        return {
            "id": str(self.id),
            "capability_key": self.capability_key,
            "feature_category": self.feature_category.value,
            "capability_name": self.capability_name,
            "description": self.description,
            "access_levels": self.access_levels,
            "is_system_critical": self.is_system_critical,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
