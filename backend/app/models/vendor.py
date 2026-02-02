"""
Vendor model for fleet management.
Represents suppliers, workshops, fuel stations, and other service providers.
"""

from sqlalchemy import Column, String, Text, DateTime, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Vendor(Base):
    """
    Vendor model for managing suppliers and service providers.

    Stores vendor information including contact details, business information,
    and relationships with the organization.
    """
    __tablename__ = "vendors"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Vendor Information
    vendor_name = Column(String(255), nullable=False)
    vendor_type = Column(String(50), nullable=False, index=True)

    # Contact Information
    contact_person = Column(String(255), nullable=True)
    email = Column(String(255), nullable=True)
    phone = Column(String(20), nullable=True)

    # Address Information
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(10), nullable=True)
    country = Column(String(100), nullable=False, default='India')

    # Business Information
    gstin = Column(String(15), nullable=True, index=True)
    pan = Column(String(10), nullable=True)

    # Banking Information
    bank_name = Column(String(255), nullable=True)
    bank_account_number = Column(String(50), nullable=True)
    bank_ifsc_code = Column(String(11), nullable=True)

    # Additional Information
    notes = Column(Text, nullable=True)
    status = Column(String(20), nullable=False, default='active', index=True)

    # Audit Fields
    created_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    organization = relationship("Organization")
    creator = relationship("User", foreign_keys=[created_by])

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "vendor_type IN ('supplier', 'workshop', 'fuel_station', 'insurance', 'other')",
            name='check_vendor_type'
        ),
        CheckConstraint(
            "status IN ('active', 'inactive')",
            name='check_vendor_status'
        ),
        CheckConstraint(
            r"email IS NULL OR email ~ '^[\w\.-]+@[\w\.-]+\.\w+$'",
            name='check_vendor_email_format'
        ),
        CheckConstraint(
            r"phone IS NULL OR phone ~ '^\+?[0-9]{10,20}$'",
            name='check_vendor_phone_format'
        ),
        CheckConstraint(
            r"pincode IS NULL OR pincode ~ '^\d{6}$'",
            name='check_vendor_pincode_format'
        ),
        CheckConstraint(
            r"gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[Z]{1}[0-9A-Z]{1}$'",
            name='check_vendor_gstin_format'
        ),
        CheckConstraint(
            r"pan IS NULL OR pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'",
            name='check_vendor_pan_format'
        ),
        Index('idx_vendor_org_name', 'organization_id', 'vendor_name'),
    )

    def __repr__(self):
        return f"<Vendor(id={self.id}, name='{self.vendor_name}', type='{self.vendor_type}')>"

    def is_active(self) -> bool:
        """Check if vendor is currently active"""
        return self.status == 'active'
