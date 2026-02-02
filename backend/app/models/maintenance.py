"""
Maintenance models for fleet management.
Includes MaintenanceSchedule, WorkOrder, Inspection, and InspectionChecklistItem.
"""

from sqlalchemy import Column, String, Text, Date, DateTime, Integer, Numeric, Boolean, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import date as date_type, timedelta
import uuid

from app.database import Base


class MaintenanceSchedule(Base):
    """
    MaintenanceSchedule model for preventive maintenance planning.

    Supports mileage-based, time-based, or both trigger types.
    """
    __tablename__ = "maintenance_schedules"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Vehicle Reference
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Schedule Details
    schedule_name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    maintenance_type = Column(String(50), nullable=False)  # preventive, corrective, etc.

    # Trigger Configuration
    trigger_type = Column(String(20), nullable=False)  # mileage, time, both

    # Mileage-based triggers
    mileage_interval = Column(Integer, nullable=True)  # Miles/KM between services
    last_service_mileage = Column(Integer, nullable=True)
    next_service_mileage = Column(Integer, nullable=True)

    # Time-based triggers
    time_interval_days = Column(Integer, nullable=True)  # Days between services
    last_service_date = Column(Date, nullable=True)
    next_service_date = Column(Date, nullable=True)

    # Status
    is_active = Column(Boolean, nullable=False, default=True)

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
    vehicle = relationship("Vehicle")
    creator = relationship("User", foreign_keys=[created_by])
    work_orders = relationship(
        "WorkOrder",
        back_populates="schedule",
        foreign_keys="WorkOrder.schedule_id"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "trigger_type IN ('mileage', 'time', 'both')",
            name='check_schedule_trigger_type'
        ),
        CheckConstraint(
            "maintenance_type IN ('preventive', 'corrective', 'inspection', 'emergency')",
            name='check_schedule_maintenance_type'
        ),
        Index('idx_schedule_vehicle_active', 'vehicle_id', 'is_active'),
        Index('idx_schedule_next_service_date', 'next_service_date'),
    )

    def __repr__(self):
        return f"<MaintenanceSchedule(id={self.id}, name='{self.schedule_name}', vehicle_id={self.vehicle_id})>"

    def is_due_by_mileage(self, current_mileage: int) -> bool:
        """Check if maintenance is due based on mileage"""
        if self.trigger_type in ['mileage', 'both'] and self.next_service_mileage:
            return current_mileage >= self.next_service_mileage
        return False

    def is_due_by_time(self) -> bool:
        """Check if maintenance is due based on time"""
        if self.trigger_type in ['time', 'both'] and self.next_service_date:
            return date_type.today() >= self.next_service_date
        return False

    def update_next_service(self, current_mileage: int = None):
        """Calculate next service date and mileage"""
        if self.trigger_type in ['mileage', 'both'] and current_mileage and self.mileage_interval:
            self.last_service_mileage = current_mileage
            self.next_service_mileage = current_mileage + self.mileage_interval

        if self.trigger_type in ['time', 'both'] and self.time_interval_days:
            self.last_service_date = date_type.today()
            self.next_service_date = date_type.today() + timedelta(days=self.time_interval_days)


class WorkOrder(Base):
    """
    WorkOrder model for maintenance tasks.

    Tracks work orders from creation through completion.
    """
    __tablename__ = "work_orders"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Work Order Identification
    work_order_number = Column(String(50), nullable=False, unique=True, index=True)

    # Vehicle Reference
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Schedule Reference (if created from schedule)
    schedule_id = Column(
        UUID(as_uuid=True),
        ForeignKey("maintenance_schedules.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # Work Order Details
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    maintenance_type = Column(String(50), nullable=False, index=True)
    priority = Column(String(20), nullable=False, default='medium')

    # Assignment
    assigned_to_vendor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vendors.id", ondelete="SET NULL"),
        nullable=True
    )
    assigned_to_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Status and Workflow
    status = Column(String(20), nullable=False, default='pending', index=True)
    scheduled_date = Column(Date, nullable=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    # Cost Tracking
    estimated_cost = Column(Numeric(12, 2), nullable=True)
    actual_cost = Column(Numeric(12, 2), nullable=True)

    # Mileage at Service
    vehicle_mileage = Column(Integer, nullable=True)

    # Work Performed
    work_performed = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

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
    vehicle = relationship("Vehicle")
    schedule = relationship("MaintenanceSchedule", back_populates="work_orders")
    assigned_vendor = relationship("Vendor")
    assigned_user = relationship("User", foreign_keys=[assigned_to_user_id])
    creator = relationship("User", foreign_keys=[created_by])

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "maintenance_type IN ('preventive', 'corrective', 'inspection', 'emergency')",
            name='check_work_order_maintenance_type'
        ),
        CheckConstraint(
            "status IN ('pending', 'in_progress', 'completed', 'cancelled')",
            name='check_work_order_status'
        ),
        CheckConstraint(
            "priority IN ('low', 'medium', 'high', 'urgent')",
            name='check_work_order_priority'
        ),
        Index('idx_work_order_org_number', 'organization_id', 'work_order_number', unique=True),
        Index('idx_work_order_vehicle_status', 'vehicle_id', 'status'),
    )

    def __repr__(self):
        return f"<WorkOrder(id={self.id}, number='{self.work_order_number}', title='{self.title}', status='{self.status}')>"

    @property
    def is_pending(self) -> bool:
        return self.status == 'pending'

    @property
    def is_in_progress(self) -> bool:
        return self.status == 'in_progress'

    @property
    def is_completed(self) -> bool:
        return self.status == 'completed'

    @property
    def is_cancelled(self) -> bool:
        return self.status == 'cancelled'

    def can_start(self) -> bool:
        """Check if work order can be started"""
        return self.status == 'pending'

    def can_complete(self) -> bool:
        """Check if work order can be completed"""
        return self.status == 'in_progress'


class Inspection(Base):
    """
    Inspection model for vehicle inspections.

    Stores inspection results with checklist items.
    """
    __tablename__ = "inspections"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Inspection Identification
    inspection_number = Column(String(50), nullable=False, unique=True, index=True)

    # Vehicle Reference
    vehicle_id = Column(
        UUID(as_uuid=True),
        ForeignKey("vehicles.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Inspection Details
    inspection_type = Column(String(50), nullable=False)
    inspection_date = Column(Date, nullable=False, index=True)
    inspector_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Vehicle Condition
    vehicle_mileage = Column(Integer, nullable=True)
    overall_condition = Column(String(20), nullable=False)  # excellent, good, fair, poor

    # Results
    passed = Column(Boolean, nullable=False)
    notes = Column(Text, nullable=True)

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
    vehicle = relationship("Vehicle")
    inspector = relationship("User", foreign_keys=[inspector_id])
    creator = relationship("User", foreign_keys=[created_by])
    checklist_items = relationship(
        "InspectionChecklistItem",
        back_populates="inspection",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "overall_condition IN ('excellent', 'good', 'fair', 'poor')",
            name='check_inspection_condition'
        ),
        Index('idx_inspection_org_number', 'organization_id', 'inspection_number', unique=True),
        Index('idx_inspection_vehicle_date', 'vehicle_id', 'inspection_date'),
    )

    def __repr__(self):
        return f"<Inspection(id={self.id}, number='{self.inspection_number}', vehicle_id={self.vehicle_id}, passed={self.passed})>"


class InspectionChecklistItem(Base):
    """
    InspectionChecklistItem model for structured inspection checklist.
    """
    __tablename__ = "inspection_checklist_items"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Inspection Reference
    inspection_id = Column(
        UUID(as_uuid=True),
        ForeignKey("inspections.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Checklist Item Details
    item_category = Column(String(50), nullable=False)  # e.g., brakes, tires, lights
    item_name = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False)  # pass, fail, needs_attention
    notes = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    inspection = relationship("Inspection", back_populates="checklist_items")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "status IN ('pass', 'fail', 'needs_attention')",
            name='check_checklist_item_status'
        ),
    )

    def __repr__(self):
        return f"<InspectionChecklistItem(id={self.id}, inspection_id={self.inspection_id}, item='{self.item_name}', status='{self.status}')>"
