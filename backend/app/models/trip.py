"""
Trip Model
Represents an active or completed cargo trip with full logistics details.
"""

from sqlalchemy import Column, String, Text, Date, TIMESTAMP, Numeric, ForeignKey, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID, JSONB
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
    s1_driver_name          = Column(String(100), nullable=True)
    s1_driver_phone         = Column(String(20),  nullable=True)
    s1_driving_license      = Column(String(50),  nullable=True)
    s1_aadhaar              = Column(String(20),  nullable=True)
    # Document upload URL paths (stored after file upload)
    s1_driving_license_url       = Column(Text, nullable=True)
    s1_driving_license_back_url  = Column(Text, nullable=True)
    s1_aadhaar_url               = Column(Text, nullable=True)
    s1_aadhaar_back_url          = Column(Text, nullable=True)
    s1_rc                   = Column(Text, nullable=True)
    s1_insurance            = Column(Text, nullable=True)
    s1_pollution            = Column(Text, nullable=True)
    s1_fitness              = Column(Text, nullable=True)
    s1_pan                  = Column(Text, nullable=True)
    s1_tax_declaration      = Column(Text, nullable=True)
    s1_cancelled_cheque     = Column(Text, nullable=True)
    s1_submitted_at         = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 2 — Pre-Arrival Compliance Check
    s2_specs_verified       = Column(Boolean,     nullable=True)
    s2_docs_verified        = Column(Boolean,     nullable=True)
    s2_driver_docs_valid    = Column(Boolean,     nullable=True)
    s2_entry_permission     = Column(Boolean,     nullable=True)
    s2_verified_at          = Column(TIMESTAMP(timezone=True), nullable=True)
    s2_loading_slip_url     = Column(Text,        nullable=True)
    s2_dharam_kanta_loc     = Column(String(20),  nullable=True)   # 'inside' | 'outside'
    s2_empty_weight_kg      = Column(String(20),  nullable=True)   # empty truck weight if captured at stage 2
    s2_empty_weight_unit    = Column(String(10),  nullable=True)   # 'tons' | 'kg'

    # Stage 3 — Truck Arrival at Factory
    s3_driver_parked            = Column(Boolean,      nullable=True)
    s3_docs_submitted           = Column(Boolean,      nullable=True)
    s3_security_verified        = Column(Boolean,      nullable=True)
    s3_driver_exited_cabin      = Column(Boolean,      nullable=True)
    s3_wheel_stoppers           = Column(Boolean,      nullable=True)
    s3_safety_gear              = Column(Boolean,      nullable=True)
    s3_empty_truck_weight_kg    = Column(String(20),   nullable=True)   # Dharma kanta — before loading (value)
    s3_empty_truck_weight_unit  = Column(String(10),   nullable=True, default='tons')  # 'tons' or 'kg'
    s3_loaded_truck_weight_kg   = Column(String(20),   nullable=True)   # Dharma kanta — after loading (value)
    s3_loaded_truck_weight_unit = Column(String(10),   nullable=True, default='tons')  # 'tons' or 'kg'
    s3_bilty_url                = Column(String(500),  nullable=True)   # URL path to bilty image
    s3_material_doc_urls        = Column(Text,         nullable=True)   # JSON list of material doc URL paths
    s3_completed_at             = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 4 — Truck Exit From Factory
    s4_truck_moved      = Column(Boolean, nullable=True)
    s4_security_verified = Column(Boolean, nullable=True)
    s4_bilty_checked    = Column(Boolean, nullable=True)
    s4_weight_checked   = Column(Boolean, nullable=True)
    s4_material_checked = Column(Boolean, nullable=True)
    s4_completed_at     = Column(TIMESTAMP(timezone=True), nullable=True)
    s4_notified_at      = Column(TIMESTAMP(timezone=True), nullable=True)

    # ── Stage Authorship (who submitted each stage) ──────────────────────────────
    s1_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s2_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s3_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s4_submitted_by = Column(UUID(as_uuid=True), nullable=True)

    # Stage claim columns removed (claim system disabled)

    # ── Draft (cross-device in-progress form data) ───────────────────────────────
    draft_data = Column(JSONB, nullable=True)

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
            "s1_driving_license_url": self.s1_driving_license_url,
            "s1_driving_license_back_url": self.s1_driving_license_back_url,
            "s1_aadhaar_url": self.s1_aadhaar_url,
            "s1_aadhaar_back_url": self.s1_aadhaar_back_url,
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
            "s2_loading_slip_url": self.s2_loading_slip_url,
            "s2_dharam_kanta_loc": self.s2_dharam_kanta_loc,
            "s2_empty_weight_kg": self.s2_empty_weight_kg,
            "s2_empty_weight_unit": self.s2_empty_weight_unit,
            # Stage 3
            "s3_driver_parked": self.s3_driver_parked,
            "s3_docs_submitted": self.s3_docs_submitted,
            "s3_security_verified": self.s3_security_verified,
            "s3_driver_exited_cabin": self.s3_driver_exited_cabin,
            "s3_wheel_stoppers": self.s3_wheel_stoppers,
            "s3_safety_gear": self.s3_safety_gear,
            "s3_empty_truck_weight_kg": self.s3_empty_truck_weight_kg,
            "s3_empty_truck_weight_unit": self.s3_empty_truck_weight_unit or 'tons',
            "s3_loaded_truck_weight_kg": self.s3_loaded_truck_weight_kg,
            "s3_loaded_truck_weight_unit": self.s3_loaded_truck_weight_unit or 'tons',
            "s3_bilty_url": self.s3_bilty_url,
            "s3_material_doc_urls": self.s3_material_doc_urls,
            "s3_completed_at": self.s3_completed_at.isoformat() if self.s3_completed_at else None,
            # Stage 4
            "s4_truck_moved": self.s4_truck_moved,
            "s4_security_verified": self.s4_security_verified,
            "s4_bilty_checked": self.s4_bilty_checked,
            "s4_weight_checked": self.s4_weight_checked,
            "s4_material_checked": self.s4_material_checked,
            "s4_completed_at": self.s4_completed_at.isoformat() if self.s4_completed_at else None,
            "s4_notified_at": self.s4_notified_at.isoformat() if self.s4_notified_at else None,
            # Stage authorship
            "s1_submitted_by": str(self.s1_submitted_by) if self.s1_submitted_by else None,
            "s2_submitted_by": str(self.s2_submitted_by) if self.s2_submitted_by else None,
            "s3_submitted_by": str(self.s3_submitted_by) if self.s3_submitted_by else None,
            "s4_submitted_by": str(self.s4_submitted_by) if self.s4_submitted_by else None,
            # Stage claims disabled
            # "s1_claimed_by": None,
            # "s2_claimed_by": None,
            # "s3_claimed_by": None,
            # "s4_claimed_by": None,
            # "s1_claimed_at": None,
            # "s2_claimed_at": None,
            # "s3_claimed_at": None,
            # "s4_claimed_at": None,
            "draft_data": self.draft_data,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
