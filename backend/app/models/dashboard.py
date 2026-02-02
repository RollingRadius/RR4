"""
Dashboard and DashboardWidget models for fleet management.
Supports customizable dashboards with multiple widget types.
"""

from sqlalchemy import Column, String, Text, DateTime, Integer, Boolean, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Dashboard(Base):
    """
    Dashboard model for customizable user dashboards.

    Stores dashboard configuration and layout.
    """
    __tablename__ = "dashboards"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization Reference
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Dashboard Details
    dashboard_name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # Layout Configuration
    layout_config = Column(JSONB, nullable=True)
    # Example layout_config:
    # {
    #   "columns": 3,
    #   "widget_positions": {
    #     "widget_id_1": {"row": 0, "col": 0, "width": 1, "height": 2},
    #     "widget_id_2": {"row": 0, "col": 1, "width": 2, "height": 1}
    #   }
    # }

    # Sharing
    is_default = Column(Boolean, nullable=False, default=False)
    is_shared = Column(Boolean, nullable=False, default=False)

    # Owner
    owner_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    organization = relationship("Organization")
    owner = relationship("User", foreign_keys=[owner_id])
    widgets = relationship(
        "DashboardWidget",
        back_populates="dashboard",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        Index('idx_dashboard_org_owner', 'organization_id', 'owner_id'),
        Index('idx_dashboard_default', 'organization_id', 'is_default'),
    )

    def __repr__(self):
        return f"<Dashboard(id={self.id}, name='{self.dashboard_name}', owner_id={self.owner_id})>"


class DashboardWidget(Base):
    """
    DashboardWidget model for individual dashboard widgets.

    Supports multiple widget types with custom configurations.
    """
    __tablename__ = "dashboard_widgets"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Dashboard Reference
    dashboard_id = Column(
        UUID(as_uuid=True),
        ForeignKey("dashboards.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Widget Details
    widget_name = Column(String(255), nullable=False)
    widget_type = Column(String(50), nullable=False)  # kpi, chart, table, gauge, map

    # Widget Configuration
    widget_config = Column(JSONB, nullable=False)
    # Example widget_config for KPI:
    # {
    #   "metric": "total_vehicles",
    #   "filters": {"status": "active"},
    #   "display": {"icon": "truck", "color": "blue"}
    # }
    # Example widget_config for Chart:
    # {
    #   "chart_type": "line",
    #   "data_source": "expenses",
    #   "x_axis": "date",
    #   "y_axis": "amount",
    #   "filters": {"category": "fuel"}
    # }

    # Display Order
    display_order = Column(Integer, nullable=False, default=0)

    # Refresh Settings
    auto_refresh = Column(Boolean, nullable=False, default=True)
    refresh_interval_seconds = Column(Integer, nullable=True, default=300)  # 5 minutes

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    dashboard = relationship("Dashboard", back_populates="widgets")

    # Constraints
    __table_args__ = (
        Index('idx_widget_dashboard_order', 'dashboard_id', 'display_order'),
    )

    def __repr__(self):
        return f"<DashboardWidget(id={self.id}, name='{self.widget_name}', type='{self.widget_type}')>"
