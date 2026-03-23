"""
Trip Model
Represents an active or completed cargo trip with full logistics details.
"""

from sqlalchemy import Column, String, Text, Date, TIMESTAMP, Numeric, ForeignKey, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Trip(Base):
    __tablename__ = "trips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # ── Identification ───────────────────────────────────────────────────────────
    trip_number = Column(String(30), nullable=False, unique=True, index=True)   # e.g. RR-90422
    bilty_number = Column(String(50), nullable=True)                             # Consignment note number

    # ── Route ────────────────────────────────────────────────────────────────────
    origin = Column(String(200), nullable=False)
    origin_sub = Column(String(200), nullable=True)
    destination = Column(String(200), nullable=False)
    destination_sub = Column(String(200), nullable=True)

    # ── Cargo details ────────────────────────────────────────────────────────────
    load_item = Column(String(200), nullable=False)     # What is being transported
    weight = Column(String(50), nullable=True)           # e.g. "5000 kg"
    trip_amount = Column(Numeric(12, 2), nullable=True)  # Freight amount

    # ── Financial ────────────────────────────────────────────────────────────────
    invoice_number = Column(String(100), nullable=True)

    # ── Status ───────────────────────────────────────────────────────────────────
    status = Column(String(20), nullable=False, default='ongoing')
    # Values: pending | ongoing | completed | cancelled

    # ── Relations ────────────────────────────────────────────────────────────────
    # Fleet owner's organisation (who runs the vehicle)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"),
                              nullable=False, index=True)
    # Load owner's organisation (optional – who posted the load)
    load_owner_org_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="SET NULL"),
                                nullable=True, index=True)

    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="SET NULL"),
                         nullable=True, index=True)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id", ondelete="SET NULL"),
                        nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"),
                         nullable=True)
    # Load requirement this trip was created to fulfill (optional)
    load_requirement_id = Column(UUID(as_uuid=True),
                                  ForeignKey("load_requirements.id", ondelete="SET NULL"),
                                  nullable=True, index=True)

    # ── Trip Stages ──────────────────────────────────────────────────────────────
    current_stage = Column(Integer, nullable=False, default=0)

    # Stage 1 — Truck Detail Registration
    s1_driver_name      = Column(String(100), nullable=True)
    s1_driver_phone     = Column(String(20),  nullable=True)
    s1_driving_license  = Column(String(50),  nullable=True)
    s1_aadhaar          = Column(String(20),  nullable=True)
    s1_rc               = Column(String(50),  nullable=True)
    s1_insurance        = Column(String(50),  nullable=True)
    s1_pollution        = Column(String(50),  nullable=True)
    s1_fitness          = Column(String(50),  nullable=True)
    s1_pan              = Column(String(20),  nullable=True)
    s1_tax_declaration  = Column(String(100), nullable=True)
    s1_cancelled_cheque = Column(String(100), nullable=True)
    s1_submitted_at     = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 2 — Pre-Arrival Compliance Check
    s2_specs_verified    = Column(Boolean, nullable=True)
    s2_docs_verified     = Column(Boolean, nullable=True)
    s2_driver_docs_valid = Column(Boolean, nullable=True)
    s2_entry_permission  = Column(Boolean, nullable=True)
    s2_verified_at       = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 3 — Truck Arrival at Factory
    s3_driver_parked       = Column(Boolean, nullable=True)
    s3_docs_submitted      = Column(Boolean, nullable=True)
    s3_security_verified   = Column(Boolean, nullable=True)
    s3_driver_exited_cabin = Column(Boolean, nullable=True)
    s3_wheel_stoppers      = Column(Boolean, nullable=True)
    s3_safety_gear         = Column(Boolean, nullable=True)
    s3_completed_at        = Column(TIMESTAMP(timezone=True), nullable=True)

    # ── Dates ────────────────────────────────────────────────────────────────────
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(),
                        onupdate=func.now(), nullable=False)

    def to_dict(self):
        return {
            "id": str(self.id),
            "trip_number": self.trip_number,
            "bilty_number": self.bilty_number,
            "origin": self.origin,
            "origin_sub": self.origin_sub,
            "destination": self.destination,
            "destination_sub": self.destination_sub,
            "load_item": self.load_item,
            "weight": self.weight,
            "trip_amount": float(self.trip_amount) if self.trip_amount is not None else None,
            "invoice_number": self.invoice_number,
            "status": self.status,
            "organization_id": str(self.organization_id),
            "load_owner_org_id": str(self.load_owner_org_id) if self.load_owner_org_id else None,
            "vehicle_id": str(self.vehicle_id) if self.vehicle_id else None,
            "driver_id": str(self.driver_id) if self.driver_id else None,
            "created_by": str(self.created_by) if self.created_by else None,
            "start_date": str(self.start_date) if self.start_date else None,
            "end_date": str(self.end_date) if self.end_date else None,
            "load_requirement_id": str(self.load_requirement_id) if self.load_requirement_id else None,
            "current_stage": self.current_stage,
            # Stage 1
            "s1_driver_name": self.s1_driver_name,
            "s1_driver_phone": self.s1_driver_phone,
            "s1_driving_license": self.s1_driving_license,
            "s1_aadhaar": self.s1_aadhaar,
            "s1_rc": self.s1_rc,
            "s1_insurance": self.s1_insurance,
            "s1_pollution": self.s1_pollution,
            "s1_fitness": self.s1_fitness,
            "s1_pan": self.s1_pan,
            "s1_tax_declaration": self.s1_tax_declaration,
            "s1_cancelled_cheque": self.s1_cancelled_cheque,
            "s1_submitted_at": self.s1_submitted_at.isoformat() if self.s1_submitted_at else None,
            # Stage 2
            "s2_specs_verified": self.s2_specs_verified,
            "s2_docs_verified": self.s2_docs_verified,
            "s2_driver_docs_valid": self.s2_driver_docs_valid,
            "s2_entry_permission": self.s2_entry_permission,
            "s2_verified_at": self.s2_verified_at.isoformat() if self.s2_verified_at else None,
            # Stage 3
            "s3_driver_parked": self.s3_driver_parked,
            "s3_docs_submitted": self.s3_docs_submitted,
            "s3_security_verified": self.s3_security_verified,
            "s3_driver_exited_cabin": self.s3_driver_exited_cabin,
            "s3_wheel_stoppers": self.s3_wheel_stoppers,
            "s3_safety_gear": self.s3_safety_gear,
            "s3_completed_at": self.s3_completed_at.isoformat() if self.s3_completed_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
