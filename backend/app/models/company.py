"""
Organization/Company Model
Represents companies in the fleet management system
"""

from sqlalchemy import Column, String, Text, Date, DateTime, TIMESTAMP, CheckConstraint, ForeignKey
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

    # RR Sync
    rr_company_id = Column(String(24), nullable=True)  # MongoDB ObjectId in RR — set once by admin

    # RR persisted session — populated on LP/RR-ops login, silently refreshed by
    # rr_org_token_service so background stage-sync tasks don't need a human logged in.
    rr_access_token     = Column(Text, nullable=True)
    rr_refresh_token    = Column(Text, nullable=True)
    rr_token_expires_at = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_token_updated_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    # The RR refresh token's own real ~30-day expiry (distinct from
    # rr_token_expires_at above, which is just the derived access token's
    # ~15min lifetime) — lets us warn LP/RR-ops before the session actually
    # lapses, which nothing tracked before this.
    rr_session_expires_at = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_expiry_notified_at = Column(TIMESTAMP(timezone=True), nullable=True)

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
    branding = relationship(
        "OrganizationBranding",
        back_populates="organization",
        uselist=False,
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

    @property
    def name(self) -> str:
        """Convenience property to access company_name as name"""
        return self.company_name

    def to_search_result(self):
        """Convert to search result format (for company search API)"""
        return {
            "company_id": str(self.id),
            "company_name": self.company_name,
            "city": self.city,
            "state": self.state,
            "business_type": self.business_type
        }
