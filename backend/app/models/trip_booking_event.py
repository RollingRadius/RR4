"""
Trip Booking Event Model
One row per booking cancel / re-book / trip cancel done from the app (sent to RR at once).
See md/RR_BOOKING_CANCEL_RULES.md (migration 111).
"""

from sqlalchemy import Column, String, Text, Numeric, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base

BOOKING_CANCELLED = "booking_cancelled"
REBOOKED = "rebooked"
TRIP_CANCELLED = "trip_cancelled"
# Done on RR web; our trip followed (rr_follow_service, migration 113). created_by is NULL ("RR web").
RR_WEB_TRIP_CANCELLED = "rr_web_trip_cancelled"
RR_WEB_BOOKING_CANCELLED = "rr_web_booking_cancelled"
RR_WEB_REBOOKED = "rr_web_rebooked"
RR_WEB_DRIVER_CHANGED = "rr_web_driver_changed"


class TripBookingEvent(Base):
    __tablename__ = "trip_booking_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True)
    event = Column(String(30), nullable=False)            # booking_cancelled | rebooked | trip_cancelled
    reason = Column(Text, nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False, server_default=func.now())

    rr_trip_id = Column(String(24), nullable=True)
    rr_booking_id = Column(String(30), nullable=True)
    rr_purchase_order_no = Column(String(30), nullable=True)

    old_rr_vehicle_id = Column(String(24), nullable=True)
    old_vehicle_number = Column(String(30), nullable=True)
    old_rr_driver_id = Column(String(24), nullable=True)
    old_driver_name = Column(String(100), nullable=True)
    old_owner_rr_company_id = Column(String(24), nullable=True)

    new_rr_vehicle_id = Column(String(24), nullable=True)
    new_vehicle_number = Column(String(30), nullable=True)
    new_rr_driver_id = Column(String(24), nullable=True)
    new_driver_name = Column(String(100), nullable=True)
    new_owner_rr_company_id = Column(String(24), nullable=True)

    booking_amount = Column(Numeric(12, 2), nullable=True)
