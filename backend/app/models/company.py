"""
Organization/Company Model
Represents companies in the fleet management system
"""

from sqlalchemy import Column, String, Text, Date, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Organization(Base):
    """
    Organization/Company model.

    Stores company information including optional GSTIN/PAN for Indian companies.
    GSTIN and PAN are validated at application level but format constraints exist at DB level.
    """
    __tablename__ = "organizations"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Company Information
    company_name = Column(String(255), nullable=False, index=True)
    business_type = Column(String(50), nullable=False)

    # Legal Information (Optional)
    gstin = Column(String(15), unique=True, nullable=True, index=True)
    pan_number = Column(String(10), nullable=True)
    registration_number = Column(String(100), nullable=True)
    registration_date = Column(Date, nullable=True)

    # Contact Information
    business_email = Column(String(255), nullable=False)
    business_phone = Column(String(20), nullable=False)

    # Address
    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    pincode = Column(String(10), nullable=False)
    country = Column(String(100), nullable=False, default='India')

    # Status
    status = Column(String(20), nullable=False, default='active')

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    user_organizations = relationship(
        "UserOrganization",
        back_populates="organization",
        cascade="all, delete-orphan"
    )
    vehicles = relationship(
        "Vehicle",
        back_populates="organization",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            r"gstin IS NULL OR gstin ~ '^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$'",
            name='check_gstin_format'
        ),
        CheckConstraint(
            r"pan_number IS NULL OR pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'",
            name='check_pan_format'
        ),
    )

    def __repr__(self):
        return f"<Organization(id={self.id}, name='{self.company_name}', city='{self.city}')>"

    def to_search_result(self):
        """Convert to search result format (for company search API)"""
        return {
            "company_id": str(self.id),
            "company_name": self.company_name,
            "city": self.city,
            "state": self.state,
            "business_type": self.business_type
        }
