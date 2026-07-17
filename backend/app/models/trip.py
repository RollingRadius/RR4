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
    # Whether Field Executives must fill Stage 1 for this trip. LP/RR-ops can
    # toggle this live at any point while the trip is active (e.g. when the
    # selected driver/vehicle already has KYC docs on file on RR web) — it
    # only gates FE's access to Stage 1, never LP/RR-ops'.
    s1_required = Column(Boolean, nullable=False, default=True)

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
    s1_permit               = Column(Text, nullable=True)
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
    s3_empty_truck_weight_unit  = Column(String(10),   nullable=True, default='kg')  # 'tons' or 'kg'
    s3_loaded_truck_weight_kg   = Column(String(20),   nullable=True)   # Dharma kanta — after loading (value)
    s3_loaded_truck_weight_unit = Column(String(10),   nullable=True, default='kg')  # 'tons' or 'kg'
    s3_loaded_weight_slip_url   = Column(String(500),  nullable=True)   # Kanta parchi — loaded weight slip photo
    s3_bilty_url                = Column(String(500),  nullable=True)   # legacy — replaced by e-way bill, no longer written
    s3_material_doc_urls        = Column(Text,         nullable=True)   # JSON list of material doc URL paths
    s3_completed_at             = Column(TIMESTAMP(timezone=True), nullable=True)
    # RR parcels.loading.{truck_reach_datetime,start_datetime}
    s3_vehicle_reach_datetime   = Column(TIMESTAMP(timezone=True), nullable=True)
    s3_loading_start_datetime   = Column(TIMESTAMP(timezone=True), nullable=True)
    # RR parcels.documents.eway_bill.{number,photos,issue_date,expiry_date}
    s3_eway_bill_number         = Column(String(50),   nullable=True)
    s3_eway_bill_url            = Column(String(500),  nullable=True)   # URL path to e-way bill photo
    s3_eway_bill_issue_date     = Column(TIMESTAMP(timezone=True), nullable=True)
    s3_eway_bill_expiry_date    = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 4 — Truck Exit From Factory
    s4_truck_moved      = Column(Boolean, nullable=True)
    s4_security_verified = Column(Boolean, nullable=True)
    s4_bilty_checked    = Column(Boolean, nullable=True)
    s4_weight_checked   = Column(Boolean, nullable=True)
    s4_material_checked = Column(Boolean, nullable=True)
    s4_completed_at       = Column(TIMESTAMP(timezone=True), nullable=True)
    s4_notified_at        = Column(TIMESTAMP(timezone=True), nullable=True)
    s4_diesel_receipt_url = Column(Text, nullable=True)   # uploaded after truck exits factory
    # RR parcels.loading.end_datetime
    s4_vehicle_exit_datetime = Column(TIMESTAMP(timezone=True), nullable=True)

    # Stage 5 — Unloading (Proof of Delivery + Halting Charge)
    s5_pod_url        = Column(Text,                    nullable=True)
    s5_halting_charge = Column(Numeric(12, 2),          nullable=True)
    s5_submitted_by   = Column(UUID(as_uuid=True),      nullable=True)
    s5_completed_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    # RR parcels.unloading.{truck_reach_datetime,start_datetime,end_datetime}
    s5_vehicle_reach_datetime   = Column(TIMESTAMP(timezone=True), nullable=True)
    s5_unloading_start_datetime = Column(TIMESTAMP(timezone=True), nullable=True)
    s5_unloading_end_datetime   = Column(TIMESTAMP(timezone=True), nullable=True)

    # ── Transporter Assignment ────────────────────────────────────────────────────
    # User ID of the transporter assigned by LP to upload the loading slip
    transporter_user_id = Column(UUID(as_uuid=True), nullable=True)
    # RR company ObjectId used as vehicle_provider_id in POST /create_trip.
    # Set at assign-transporter time: transporter org's rr_company_id if set,
    # else Rolling Radius default (62d66794e54f47829a886a1d).
    transporter_rr_company_id = Column(String(24), nullable=True)

    # ── Consignee (Load Receiver) ─────────────────────────────────────────────────
    # Exactly one is set: org-type consignee OR individual user-type consignee
    consignee_org_id  = Column(UUID(as_uuid=True), nullable=True)
    consignee_user_id = Column(UUID(as_uuid=True), nullable=True)
    # RR company ObjectIds — set directly when LP picks from the RR company picker
    consignor_rr_company_id = Column(String, nullable=True)   # sender / shipper
    consignee_rr_company_id = Column(String, nullable=True)   # receiver
    # RR Ops worker assigned to handle this trip's sync
    rr_ops_user_id    = Column(UUID(as_uuid=True), nullable=True)

# ── Stage Authorship (who submitted each stage) ──────────────────────────────
    s1_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s2_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s3_submitted_by = Column(UUID(as_uuid=True), nullable=True)
    s4_submitted_by = Column(UUID(as_uuid=True), nullable=True)

    # Stage claim columns removed (claim system disabled)

    # ── RR Sync ──────────────────────────────────────────────────────────────────
    # City ObjectIds resolved via RR city proxy at form-fill time
    origin_rr_city_id      = Column(String(24), nullable=True)
    destination_rr_city_id = Column(String(24), nullable=True)

    # Material ObjectId resolved via RR /material_types proxy at form-fill time
    material_rr_id = Column(String(24), nullable=True)

    # Structured weight (old free-text `weight` column kept for compatibility)
    weight_value      = Column(Numeric(10, 3), nullable=True)
    weight_unit       = Column(String(20),     nullable=True)   # RR-native: TONNES | KILOGRAMS | LITRES | BOX | CUBIC METERS
    vehicle_body_type = Column(String(50),     nullable=True)   # RR VehicleBodyTypes enum value

    # Required by RR, not yet in RR4 form (short-term: defaults to trip_amount)
    invoice_value = Column(Numeric(12, 2), nullable=True)

    # ── RR Consignor / Consignee details ─────────────────────────────────────────
    consignor_name  = Column(String(100), nullable=True)
    consignor_gstin = Column(String(20),  nullable=True)
    consignee_name  = Column(String(100), nullable=True)
    consignee_gstin = Column(String(20),  nullable=True)

    # ── Pickup address ────────────────────────────────────────────────────────────
    pickup_address_line1 = Column(String(200), nullable=True)
    pickup_address_line2 = Column(String(200), nullable=True)
    pickup_pin           = Column(String(10),  nullable=True)
    pickup_no_entry_zone = Column(Boolean,     nullable=True)

    # ── Unload address ────────────────────────────────────────────────────────────
    unload_address_line1 = Column(String(200), nullable=True)
    unload_address_line2 = Column(String(200), nullable=True)
    unload_pin           = Column(String(10),  nullable=True)
    unload_no_entry_zone = Column(Boolean,     nullable=True)
    depot_code           = Column(String(50),  nullable=True)

    # ── Parcel info ───────────────────────────────────────────────────────────────
    parcel_description = Column(String(100), nullable=True)
    part_load          = Column(Boolean,     nullable=True, default=False)

    # ── Vehicle requirements ──────────────────────────────────────────────────────
    vehicle_number   = Column(String(30),    nullable=True)   # manually entered reg. number (no fleet link)
    rr_vehicle_id    = Column(String(24),    nullable=True)   # RR vehicle ObjectId selected via picker
    rr_driver_id     = Column(String(24),    nullable=True)   # RR driver user ObjectId (from vehicle crew)

    # RR identity-doc file ids — cache for trips using the RR picker (rr_vehicle_id/
    # rr_driver_id above) where there's no local Driver/Vehicle row to cache on.
    # Mirrors drivers.rr_*_file_id / vehicles.rr_*_file_id, used as the fallback
    # entity by _sync_stage1_docs / get_identity_status / identity-override.
    rr_dl_file_id              = Column(String(100), nullable=True)
    rr_dl_back_file_id         = Column(String(100), nullable=True)
    rr_aadhaar_file_id         = Column(String(100), nullable=True)
    rr_aadhaar_back_file_id    = Column(String(100), nullable=True)
    rr_pan_file_id             = Column(String(100), nullable=True)
    rr_tax_declaration_file_id = Column(String(100), nullable=True)
    rr_rc_file_id              = Column(String(100), nullable=True)
    rr_puc_file_id             = Column(String(100), nullable=True)
    rr_fitness_file_id         = Column(String(100), nullable=True)
    rr_permit_file_id          = Column(String(100), nullable=True)
    axle_type        = Column(String(20),    nullable=True)   # Single | Double | Triple | Multiple
    number_of_wheels = Column(Integer,       nullable=True)   # 4|6|8|10|12|14|16|18|22
    expected_freight = Column(Numeric(12,2), nullable=True)
    booking_amount   = Column(Numeric(12,2), nullable=True)  # LP offline bid price sent to vehicle provider via create_trip

    # RR trip cross-reference
    rr_trip_id     = Column(String(24), nullable=True)   # RR MongoDB trip _id
    rr_trip_number = Column(String(30), nullable=True)   # RR generated number e.g. "rr1235"

    # RR parcel reference (auto-created by RR alongside trip)
    rr_parcel_id   = Column(String(24),  nullable=True)
    rr_parcel_etag = Column(String(100), nullable=True)  # must be sent with every PATCH
    rr_booking_id  = Column(String(30),  nullable=True)  # PO booking_id from create_trip response

    # Loading slip (RR web flow)
    rr_loading_slip_file_id = Column(String(100), nullable=True)  # ObjectId from RR /files
    rr_loading_slip_url     = Column(String(500), nullable=True)  # our local saved copy

    # Sync state (overall/legacy — stage 2 loading slip still reported here)
    rr_sync_status = Column(String(30), nullable=True, default='not_synced')
    # Values: not_synced | trip_created | loading_slip_synced | bilty_synced | pod_synced | failed
    rr_sync_error  = Column(Text,                        nullable=True)
    rr_synced_at   = Column(TIMESTAMP(timezone=True),    nullable=True)

    # Per-stage RR sync tracking (each stage's own status — see sync_stage() /
    # rr_sync_service.py. rr_sync_status above stays as a legacy "overall/latest"
    # indicator other screens read, but is NOT authoritative per-stage: it gets
    # overwritten by whichever stage's sync last completed, so relying on it to
    # judge one specific stage's success is wrong — use these columns instead.)
    # Values: not_synced | pending_trip_creation | synced | failed | auth_required
    rr_s1_sync_status = Column(String(30), nullable=False, default='not_synced')
    rr_s1_synced_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_s1_sync_error  = Column(Text, nullable=True)

    rr_s2_sync_status = Column(String(30), nullable=False, default='not_synced')
    rr_s2_synced_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_s2_sync_error  = Column(Text, nullable=True)

    rr_s3_sync_status = Column(String(30), nullable=False, default='not_synced')
    rr_s3_synced_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_s3_sync_error  = Column(Text, nullable=True)

    rr_s4_sync_status = Column(String(30), nullable=False, default='not_synced')
    rr_s4_synced_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_s4_sync_error  = Column(Text, nullable=True)

    rr_s5_sync_status = Column(String(30), nullable=False, default='not_synced')
    rr_s5_synced_at   = Column(TIMESTAMP(timezone=True), nullable=True)
    rr_s5_sync_error  = Column(Text, nullable=True)

    # ── Draft (cross-device in-progress form data) ───────────────────────────────
    draft_data = Column(JSONB, nullable=True)

    # ── Per-field attribution (fieldKey → @username, persists across submits) ──
    field_attributions = Column(JSONB, nullable=True)

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
            "s1_required": self.s1_required,
            "transporter_user_id": str(self.transporter_user_id) if self.transporter_user_id else None,
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
            "s1_permit": self.s1_permit,
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
            "s3_empty_truck_weight_unit": self.s3_empty_truck_weight_unit or 'kg',
            "s3_loaded_truck_weight_kg": self.s3_loaded_truck_weight_kg,
            "s3_loaded_truck_weight_unit": self.s3_loaded_truck_weight_unit or 'kg',
            "s3_loaded_weight_slip_url": self.s3_loaded_weight_slip_url,
            "s3_bilty_url": self.s3_bilty_url,
            "s3_material_doc_urls": self.s3_material_doc_urls,
            "s3_completed_at": self.s3_completed_at.isoformat() if self.s3_completed_at else None,
            "s3_vehicle_reach_datetime": self.s3_vehicle_reach_datetime.isoformat() if self.s3_vehicle_reach_datetime else None,
            "s3_loading_start_datetime": self.s3_loading_start_datetime.isoformat() if self.s3_loading_start_datetime else None,
            "s3_eway_bill_number": self.s3_eway_bill_number,
            "s3_eway_bill_url": self.s3_eway_bill_url,
            "s3_eway_bill_issue_date": self.s3_eway_bill_issue_date.isoformat() if self.s3_eway_bill_issue_date else None,
            "s3_eway_bill_expiry_date": self.s3_eway_bill_expiry_date.isoformat() if self.s3_eway_bill_expiry_date else None,
            # Stage 4
            "s4_truck_moved": self.s4_truck_moved,
            "s4_security_verified": self.s4_security_verified,
            "s4_bilty_checked": self.s4_bilty_checked,
            "s4_weight_checked": self.s4_weight_checked,
            "s4_material_checked": self.s4_material_checked,
            "s4_completed_at": self.s4_completed_at.isoformat() if self.s4_completed_at else None,
            "s4_notified_at": self.s4_notified_at.isoformat() if self.s4_notified_at else None,
            "s4_diesel_receipt_url": self.s4_diesel_receipt_url,
            "s4_vehicle_exit_datetime": self.s4_vehicle_exit_datetime.isoformat() if self.s4_vehicle_exit_datetime else None,
            # Stage 5 — Unloading
            "s5_pod_url": self.s5_pod_url,
            "s5_halting_charge": float(self.s5_halting_charge) if self.s5_halting_charge is not None else None,
            "s5_submitted_by": str(self.s5_submitted_by) if self.s5_submitted_by else None,
            "s5_completed_at": self.s5_completed_at.isoformat() if self.s5_completed_at else None,
            "s5_vehicle_reach_datetime": self.s5_vehicle_reach_datetime.isoformat() if self.s5_vehicle_reach_datetime else None,
            "s5_unloading_start_datetime": self.s5_unloading_start_datetime.isoformat() if self.s5_unloading_start_datetime else None,
            "s5_unloading_end_datetime": self.s5_unloading_end_datetime.isoformat() if self.s5_unloading_end_datetime else None,
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
            "field_attributions": self.field_attributions,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            # RR sync state
            "rr_trip_id":     self.rr_trip_id,
            "rr_trip_number": self.rr_trip_number,
            "rr_parcel_id":   self.rr_parcel_id,
            "rr_booking_id":           self.rr_booking_id,
            "rr_loading_slip_file_id": self.rr_loading_slip_file_id,
            "rr_loading_slip_url":     self.rr_loading_slip_url,
            "rr_sync_status":          self.rr_sync_status,
            "rr_sync_error":  self.rr_sync_error,
            "rr_synced_at":   self.rr_synced_at.isoformat() if self.rr_synced_at else None,
            # Per-stage RR sync tracking
            "rr_s1_sync_status": self.rr_s1_sync_status,
            "rr_s1_sync_error":  self.rr_s1_sync_error,
            "rr_s1_synced_at":   self.rr_s1_synced_at.isoformat() if self.rr_s1_synced_at else None,
            "rr_s2_sync_status": self.rr_s2_sync_status,
            "rr_s2_sync_error":  self.rr_s2_sync_error,
            "rr_s2_synced_at":   self.rr_s2_synced_at.isoformat() if self.rr_s2_synced_at else None,
            "rr_s3_sync_status": self.rr_s3_sync_status,
            "rr_s3_sync_error":  self.rr_s3_sync_error,
            "rr_s3_synced_at":   self.rr_s3_synced_at.isoformat() if self.rr_s3_synced_at else None,
            "rr_s4_sync_status": self.rr_s4_sync_status,
            "rr_s4_sync_error":  self.rr_s4_sync_error,
            "rr_s4_synced_at":   self.rr_s4_synced_at.isoformat() if self.rr_s4_synced_at else None,
            "rr_s5_sync_status": self.rr_s5_sync_status,
            "rr_s5_sync_error":  self.rr_s5_sync_error,
            "rr_s5_synced_at":   self.rr_s5_synced_at.isoformat() if self.rr_s5_synced_at else None,
            # RR party fields
            "consignor_rr_company_id": self.consignor_rr_company_id,
            "consignee_rr_company_id": self.consignee_rr_company_id,
            "rr_ops_user_id": str(self.rr_ops_user_id) if self.rr_ops_user_id else None,
            # RR route/cargo fields
            "origin_rr_city_id":      self.origin_rr_city_id,
            "destination_rr_city_id": self.destination_rr_city_id,
            "material_rr_id":         self.material_rr_id,
            "weight_value":           float(self.weight_value) if self.weight_value is not None else None,
            "weight_unit":            self.weight_unit,
            "vehicle_body_type":      self.vehicle_body_type,
            "invoice_value":          float(self.invoice_value) if self.invoice_value is not None else None,
            "consignee_org_id":       str(self.consignee_org_id) if self.consignee_org_id else None,
            "consignee_user_id":      str(self.consignee_user_id) if self.consignee_user_id else None,
            # RR consignor/consignee details
            "consignor_name":  self.consignor_name,
            "consignor_gstin": self.consignor_gstin,
            "consignee_name":  self.consignee_name,
            "consignee_gstin": self.consignee_gstin,
            # Pickup address
            "pickup_address_line1": self.pickup_address_line1,
            "pickup_address_line2": self.pickup_address_line2,
            "pickup_pin":           self.pickup_pin,
            "pickup_no_entry_zone": self.pickup_no_entry_zone,
            # Unload address
            "unload_address_line1": self.unload_address_line1,
            "unload_address_line2": self.unload_address_line2,
            "unload_pin":           self.unload_pin,
            "unload_no_entry_zone": self.unload_no_entry_zone,
            "depot_code":           self.depot_code,
            # Parcel info
            "parcel_description": self.parcel_description,
            "part_load":          self.part_load,
            # Vehicle requirements
            "vehicle_number":   self.vehicle_number,
            "rr_vehicle_id":    self.rr_vehicle_id,
            "rr_driver_id":     self.rr_driver_id,
            "axle_type":        self.axle_type,
            "number_of_wheels": self.number_of_wheels,
            "expected_freight": float(self.expected_freight) if self.expected_freight is not None else None,
            "booking_amount":   float(self.booking_amount)   if self.booking_amount   is not None else None,
        }
