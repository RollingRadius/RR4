"""
Report and ReportExecution models for fleet management.
Supports custom and standard reports with execution history.
"""

from sqlalchemy import Column, String, Text, DateTime, Boolean, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Report(Base):
    """
    Report model for saved custom and standard reports.

    Stores report configuration and scheduling settings.
    """
    __tablename__ = "reports"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Report Details
    report_name = Column(String(255), nullable=False)
    report_type = Column(String(50), nullable=False, index=True)
    description = Column(Text, nullable=True)

    # Report Configuration (stored as JSON)
    report_config = Column(JSONB, nullable=False)
    # Example config:
    # {
    #   "filters": {"status": "active", "date_range": {"from": "2024-01-01", "to": "2024-12-31"}},
    #   "columns": ["vehicle_number", "driver_name", "expense_total"],
    #   "grouping": "category",
    #   "sorting": {"column": "expense_total", "order": "desc"}
    # }

    # Scheduling (optional)
    is_scheduled = Column(Boolean, nullable=False, default=False)
    schedule_config = Column(JSONB, nullable=True)
    # Example schedule_config:
    # {
    #   "frequency": "daily|weekly|monthly",
    #   "day_of_week": 1,  # For weekly
    #   "day_of_month": 1,  # For monthly
    #   "time": "09:00",
    #   "recipients": ["email1@example.com", "email2@example.com"]
    # }

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
    creator = relationship("User", foreign_keys=[created_by])
    executions = relationship(
        "ReportExecution",
        back_populates="report",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        Index('idx_report_org_type', 'organization_id', 'report_type'),
        Index('idx_report_active_scheduled', 'is_active', 'is_scheduled'),
    )

    def __repr__(self):
        return f"<Report(id={self.id}, name='{self.report_name}', type='{self.report_type}')>"


class ReportExecution(Base):
    """
    ReportExecution model for tracking report execution history.

    Stores execution results and metadata.
    """
    __tablename__ = "report_executions"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Report Reference
    report_id = Column(
        UUID(as_uuid=True),
        ForeignKey("reports.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Execution Details
    execution_status = Column(String(20), nullable=False, default='running')  # running, completed, failed
    started_at = Column(DateTime, nullable=False, server_default=func.now())
    completed_at = Column(DateTime, nullable=True)

    # Results (cached)
    result_data = Column(JSONB, nullable=True)  # Cached results for quick retrieval
    row_count = Column(String, nullable=True)  # Number of rows in result
    error_message = Column(Text, nullable=True)

    # Export Information
    export_format = Column(String(20), nullable=True)  # csv, pdf, excel
    export_file_path = Column(String(500), nullable=True)

    # Execution Context
    executed_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    execution_parameters = Column(JSONB, nullable=True)  # Parameters used for this execution

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    report = relationship("Report", back_populates="executions")
    executor = relationship("User")

    # Constraints
    __table_args__ = (
        Index('idx_report_execution_report_date', 'report_id', 'started_at'),
        Index('idx_report_execution_status', 'execution_status'),
    )

    def __repr__(self):
        return f"<ReportExecution(id={self.id}, report_id={self.report_id}, status='{self.execution_status}')>"

    @property
    def is_completed(self) -> bool:
        return self.execution_status == 'completed'

    @property
    def is_failed(self) -> bool:
        return self.execution_status == 'failed'

    @property
    def is_running(self) -> bool:
        return self.execution_status == 'running'
