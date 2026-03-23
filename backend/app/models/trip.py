"""
Trip Model
Represents an active or completed cargo trip with full logistics details.
"""

from sqlalchemy import Column, String, Text, Date, TIMESTAMP, Numeric, ForeignKey
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
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
