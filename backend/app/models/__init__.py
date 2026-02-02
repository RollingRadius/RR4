"""
SQLAlchemy Models
Database table definitions
"""

from .user import User
from .company import Organization
from .role import Role
from .security_question import SecurityQuestion
from .user_security_answer import UserSecurityAnswer
from .user_organization import UserOrganization
from .verification_token import VerificationToken
from .recovery_attempt import RecoveryAttempt
from .audit_log import AuditLog
from .driver import Driver, DriverLicense
from .zone import Zone
from .capability import Capability, AccessLevel, FeatureCategory
from .role_capability import RoleCapability
from .custom_role import CustomRole
from .vehicle import Vehicle, VehicleDocument
from .vendor import Vendor
from .expense import Expense, ExpenseAttachment
from .invoice import Invoice, InvoiceLineItem
from .payment import Payment
from .budget import Budget
from .maintenance import MaintenanceSchedule, WorkOrder, Inspection, InspectionChecklistItem
from .part import Part, PartUsage
from .report import Report, ReportExecution
from .dashboard import Dashboard, DashboardWidget
from .kpi import KPI, KPIHistory

__all__ = [
    "User",
    "Organization",
    "Role",
    "SecurityQuestion",
    "UserSecurityAnswer",
    "UserOrganization",
    "VerificationToken",
    "RecoveryAttempt",
    "AuditLog",
    "Driver",
    "DriverLicense",
    "Zone",
    "Capability",
    "AccessLevel",
    "FeatureCategory",
    "RoleCapability",
    "CustomRole",
    "Vehicle",
    "VehicleDocument",
    "Vendor",
    "Expense",
    "ExpenseAttachment",
    "Invoice",
    "InvoiceLineItem",
    "Payment",
    "Budget",
    "MaintenanceSchedule",
    "WorkOrder",
    "Inspection",
    "InspectionChecklistItem",
    "Part",
    "PartUsage",
    "Report",
    "ReportExecution",
    "Dashboard",
    "DashboardWidget",
    "KPI",
    "KPIHistory",
]
