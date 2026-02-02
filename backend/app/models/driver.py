"""
Driver and DriverLicense Models
Represents drivers and their license information in the fleet management system
"""

from sqlalchemy import Column, String, Text, Date, DateTime, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Driver(Base):
    """
    Driver model for fleet management.

    Stores driver information including personal details, address,
    emergency contact, and employment information.
    """
    __tablename__ = "drivers"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # User Account Reference (1-to-1 relationship)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
        index=True
    )

    # Employment Information
    employee_id = Column(String(50), nullable=False)
    join_date = Column(Date, nullable=False)
    status = Column(
        String(20),
        nullable=False,
        default='active',
        index=True
    )

    # Basic Information
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=True, index=True)
    phone = Column(String(20), nullable=False)
    date_of_birth = Column(Date, nullable=True)

    # Address Information
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(10), nullable=True)
    country = Column(String(100), nullable=False, default='India')

    # Emergency Contact
    emergency_contact_name = Column(String(255), nullable=True)
    emergency_contact_phone = Column(String(20), nullable=True)
    emergency_contact_relationship = Column(String(50), nullable=True)

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
    user = relationship("User", foreign_keys=[user_id])
    creator = relationship("User", foreign_keys=[created_by])
    license = relationship(
        "DriverLicense",
        back_populates="driver",
        uselist=False,
        cascade="all, delete-orphan"
    )
    assigned_vehicles = relationship(
        "Vehicle",
        back_populates="current_driver",
        foreign_keys="Vehicle.current_driver_id"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'inactive', 'on_leave', 'terminated')",
            name='check_driver_status'
        ),
        CheckConstraint(
            r"email IS NULL OR email ~ '^[\w\.-]+@[\w\.-]+\.\w+$'",
            name='check_driver_email_format'
        ),
        CheckConstraint(
            r"phone ~ '^\+?[0-9]{10,20}$'",
            name='check_driver_phone_format'
        ),
        CheckConstraint(
            r"pincode IS NULL OR pincode ~ '^\d{6}$'",
            name='check_driver_pincode_format'
        ),
        CheckConstraint(
            r"emergency_contact_phone IS NULL OR emergency_contact_phone ~ '^\+?[0-9]{10,20}$'",
            name='check_emergency_phone_format'
        ),
        Index('idx_driver_org_employee', 'organization_id', 'employee_id', unique=True),
    )

    def __repr__(self):
        return f"<Driver(id={self.id}, name='{self.first_name} {self.last_name}', employee_id='{self.employee_id}')>"

    @property
    def full_name(self) -> str:
        """Get driver's full name"""
        return f"{self.first_name} {self.last_name}"

    def is_active(self) -> bool:
        """Check if driver is currently active"""
        return self.status == 'active'


class DriverLicense(Base):
    """
    Driver License model.

    Stores license information for drivers with a 1-to-1 relationship.
    """
    __tablename__ = "driver_licenses"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Driver Reference (1-to-1)
    driver_id = Column(
        UUID(as_uuid=True),
        ForeignKey("drivers.id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    # License Information
    license_number = Column(String(50), nullable=False, unique=True, index=True)
    license_type = Column(String(10), nullable=False)
    issue_date = Column(Date, nullable=False)
    expiry_date = Column(Date, nullable=False, index=True)
    issuing_authority = Column(String(255), nullable=True)
    issuing_state = Column(String(100), nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    driver = relationship("Driver", back_populates="license")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "license_type IN ('LMV', 'HMV', 'MCWG', 'HPMV')",
            name='check_license_type'
        ),
        CheckConstraint(
            "expiry_date > issue_date",
            name='check_expiry_after_issue'
        ),
        CheckConstraint(
            r"license_number ~ '^[A-Z0-9\-]{10,50}$'",
            name='check_license_number_format'
        ),
    )

    def __repr__(self):
        return f"<DriverLicense(id={self.id}, number='{self.license_number}', type='{self.license_type}')>"

    def is_expired(self) -> bool:
        """Check if license is expired"""
        from datetime import date
        return self.expiry_date < date.today()

    def is_expiring_soon(self, days: int = 30) -> bool:
        """Check if license is expiring within specified days"""
        from datetime import date, timedelta
        return date.today() <= self.expiry_date <= date.today() + timedelta(days=days)
