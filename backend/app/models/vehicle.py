"""
Vehicle and VehicleDocument models for fleet management.
"""
from datetime import date, datetime, timedelta
from sqlalchemy import Column, String, Integer, Date, DateTime, Text, Numeric, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.database import Base


class Vehicle(Base):
    """Vehicle model for storing vehicle information."""

    __tablename__ = "vehicles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    vehicle_number = Column(String(50), nullable=False)
    registration_number = Column(String(50), nullable=False, unique=True)
    manufacturer = Column(String(100), nullable=False)
    model = Column(String(100), nullable=False)
    year = Column(Integer, nullable=False)
    vehicle_type = Column(String(50), nullable=False)
    fuel_type = Column(String(20), nullable=False)
    capacity = Column(Integer, nullable=True)
    color = Column(String(50), nullable=True)
    vin_number = Column(String(17), nullable=True, unique=True)
    engine_number = Column(String(50), nullable=True)
    chassis_number = Column(String(50), nullable=True)
    purchase_date = Column(Date, nullable=True)
    purchase_price = Column(Numeric(12, 2), nullable=True)
    current_driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id", ondelete="SET NULL"), nullable=True)
    current_odometer = Column(Integer, nullable=False, default=0)
    status = Column(String(20), nullable=False, default="active")

    # Insurance and compliance
    insurance_provider = Column(String(255), nullable=True)
    insurance_policy_number = Column(String(100), nullable=True)
    insurance_expiry_date = Column(Date, nullable=True)
    registration_expiry_date = Column(Date, nullable=True)
    pollution_certificate_expiry = Column(Date, nullable=True)
    fitness_certificate_expiry = Column(Date, nullable=True)

    notes = Column(Text, nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    organization = relationship("Organization", back_populates="vehicles")
    current_driver = relationship("Driver", foreign_keys=[current_driver_id], back_populates="assigned_vehicles")
    documents = relationship("VehicleDocument", back_populates="vehicle", cascade="all, delete-orphan")
    creator = relationship("User", foreign_keys=[created_by])

    # Check constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'inactive', 'maintenance', 'decommissioned')",
            name="check_vehicle_status"
        ),
        CheckConstraint(
            "vehicle_type IN ('truck', 'bus', 'van', 'car', 'motorcycle', 'other')",
            name="check_vehicle_type"
        ),
        CheckConstraint(
            "fuel_type IN ('petrol', 'diesel', 'electric', 'hybrid', 'cng', 'lpg')",
            name="check_fuel_type"
        ),
        CheckConstraint(
            "year >= 1900 AND year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1",
            name="check_vehicle_year"
        ),
        CheckConstraint(
            "current_odometer >= 0",
            name="check_odometer_positive"
        ),
    )

    @property
    def full_vehicle_name(self) -> str:
        """Return formatted vehicle name."""
        return f"{self.manufacturer} {self.model} ({self.registration_number})"

    def is_active(self) -> bool:
        """Check if vehicle is in active status."""
        return self.status == "active"

    def is_available_for_assignment(self) -> bool:
        """Check if vehicle is available for driver assignment."""
        return self.status == "active" and self.current_driver_id is None

    def needs_maintenance(self, days: int = 30) -> bool:
        """Check if any certificate is expiring within specified days."""
        expiry_dates = [
            self.insurance_expiry_date,
            self.registration_expiry_date,
            self.pollution_certificate_expiry,
            self.fitness_certificate_expiry,
        ]

        threshold_date = date.today() + timedelta(days=days)

        for expiry_date in expiry_dates:
            if expiry_date and expiry_date <= threshold_date:
                return True

        return False

    def get_expiring_documents(self, days: int = 30) -> list:
        """Get list of expiring documents/certificates."""
        threshold_date = date.today() + timedelta(days=days)
        expiring = []

        if self.insurance_expiry_date and self.insurance_expiry_date <= threshold_date:
            expiring.append({
                "type": "insurance",
                "expiry_date": self.insurance_expiry_date,
                "days_remaining": (self.insurance_expiry_date - date.today()).days
            })

        if self.registration_expiry_date and self.registration_expiry_date <= threshold_date:
            expiring.append({
                "type": "registration",
                "expiry_date": self.registration_expiry_date,
                "days_remaining": (self.registration_expiry_date - date.today()).days
            })

        if self.pollution_certificate_expiry and self.pollution_certificate_expiry <= threshold_date:
            expiring.append({
                "type": "pollution_certificate",
                "expiry_date": self.pollution_certificate_expiry,
                "days_remaining": (self.pollution_certificate_expiry - date.today()).days
            })

        if self.fitness_certificate_expiry and self.fitness_certificate_expiry <= threshold_date:
            expiring.append({
                "type": "fitness_certificate",
                "expiry_date": self.fitness_certificate_expiry,
                "days_remaining": (self.fitness_certificate_expiry - date.today()).days
            })

        return expiring

    def to_dict(self) -> dict:
        """Convert vehicle to dictionary."""
        return {
            "id": str(self.id),
            "organization_id": str(self.organization_id),
            "vehicle_number": self.vehicle_number,
            "registration_number": self.registration_number,
            "manufacturer": self.manufacturer,
            "model": self.model,
            "year": self.year,
            "vehicle_type": self.vehicle_type,
            "fuel_type": self.fuel_type,
            "capacity": self.capacity,
            "color": self.color,
            "vin_number": self.vin_number,
            "status": self.status,
            "current_driver_id": str(self.current_driver_id) if self.current_driver_id else None,
            "current_odometer": self.current_odometer,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class VehicleDocument(Base):
    """Vehicle document model for storing vehicle-related documents."""

    __tablename__ = "vehicle_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False)
    document_type = Column(String(50), nullable=False)
    document_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(Integer, nullable=False)
    mime_type = Column(String(100), nullable=False)
    expiry_date = Column(Date, nullable=True)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    uploaded_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    notes = Column(Text, nullable=True)

    # Relationships
    vehicle = relationship("Vehicle", back_populates="documents")
    uploader = relationship("User", foreign_keys=[uploaded_by])

    # Check constraints
    __table_args__ = (
        CheckConstraint(
            "document_type IN ('registration', 'insurance', 'pollution_cert', 'fitness_cert', 'permit', 'tax_receipt', 'other')",
            name="check_document_type"
        ),
    )

    def is_expired(self) -> bool:
        """Check if document has expired."""
        if not self.expiry_date:
            return False
        return self.expiry_date < date.today()

    def is_expiring_soon(self, days: int = 30) -> bool:
        """Check if document is expiring within specified days."""
        if not self.expiry_date:
            return False
        threshold_date = date.today() + timedelta(days=days)
        return self.expiry_date <= threshold_date

    def days_until_expiry(self) -> int:
        """Get number of days until expiry."""
        if not self.expiry_date:
            return None
        return (self.expiry_date - date.today()).days

    def to_dict(self) -> dict:
        """Convert document to dictionary."""
        return {
            "id": str(self.id),
            "vehicle_id": str(self.vehicle_id),
            "document_type": self.document_type,
            "document_name": self.document_name,
            "file_path": self.file_path,
            "file_size": self.file_size,
            "mime_type": self.mime_type,
            "expiry_date": self.expiry_date.isoformat() if self.expiry_date else None,
            "uploaded_by": str(self.uploaded_by) if self.uploaded_by else None,
            "uploaded_at": self.uploaded_at.isoformat() if self.uploaded_at else None,
            "is_expired": self.is_expired(),
            "days_until_expiry": self.days_until_expiry(),
        }
