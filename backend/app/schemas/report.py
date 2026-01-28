"""
Report Schemas
Pydantic models for various report types
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from enum import Enum


class ReportType(str, Enum):
    """Available report types"""
    DRIVER_LIST = "driver_list"
    DRIVER_PERFORMANCE = "driver_performance"
    LICENSE_EXPIRY = "license_expiry"
    ORGANIZATION_SUMMARY = "organization_summary"
    AUDIT_LOG = "audit_log"
    USER_ACTIVITY = "user_activity"


class ReportFormat(str, Enum):
    """Report output formats"""
    JSON = "json"
    PDF = "pdf"
    CSV = "csv"
    EXCEL = "excel"


class ReportRequest(BaseModel):
    """Base report request"""
    report_type: ReportType
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    format: ReportFormat = ReportFormat.JSON
    filters: Optional[Dict[str, Any]] = None


# Driver Reports

class DriverListItem(BaseModel):
    """Single driver in list report"""
    driver_id: str
    employee_id: str
    full_name: str
    phone: str
    status: str
    license_number: str
    license_type: str
    license_expiry: date
    join_date: date
    days_until_expiry: Optional[int]
    is_license_expired: bool
    is_license_expiring_soon: bool


class DriverListReportResponse(BaseModel):
    """Driver list report"""
    success: bool
    report_type: str = "driver_list"
    organization_id: str
    organization_name: str
    generated_at: datetime
    total_drivers: int
    active_drivers: int
    inactive_drivers: int
    drivers: List[DriverListItem]


class LicenseExpiryItem(BaseModel):
    """License expiry item"""
    driver_id: str
    employee_id: str
    full_name: str
    phone: str
    license_number: str
    license_type: str
    expiry_date: date
    days_until_expiry: int
    status: str  # "expired", "expiring_soon", "valid"


class LicenseExpiryReportResponse(BaseModel):
    """License expiry report"""
    success: bool
    report_type: str = "license_expiry"
    organization_id: str
    organization_name: str
    generated_at: datetime
    expired_count: int
    expiring_soon_count: int  # Within 30 days
    valid_count: int
    licenses: List[LicenseExpiryItem]


# Organization Reports

class OrganizationStats(BaseModel):
    """Organization statistics"""
    total_drivers: int
    active_drivers: int
    inactive_drivers: int
    on_leave_drivers: int
    terminated_drivers: int
    total_users: int
    active_users: int
    pending_users: int
    licenses_expiring_soon: int
    expired_licenses: int


class OrganizationSummaryReportResponse(BaseModel):
    """Organization summary report"""
    success: bool
    report_type: str = "organization_summary"
    organization_id: str
    organization_name: str
    generated_at: datetime
    stats: OrganizationStats
    recent_activity: List[Dict[str, Any]]


# Audit Log Reports

class AuditLogItem(BaseModel):
    """Audit log entry"""
    id: str
    timestamp: datetime
    user_id: str
    username: str
    action: str
    entity_type: str
    entity_id: Optional[str]
    details: Optional[Dict[str, Any]]
    ip_address: Optional[str]


class AuditLogReportResponse(BaseModel):
    """Audit log report"""
    success: bool
    report_type: str = "audit_log"
    organization_id: str
    organization_name: str
    generated_at: datetime
    start_date: date
    end_date: date
    total_entries: int
    entries: List[AuditLogItem]


# User Activity Reports

class UserActivityItem(BaseModel):
    """User activity summary"""
    user_id: str
    username: str
    full_name: str
    role: str
    status: str
    last_login: Optional[datetime]
    total_actions: int
    recent_actions: List[str]


class UserActivityReportResponse(BaseModel):
    """User activity report"""
    success: bool
    report_type: str = "user_activity"
    organization_id: str
    organization_name: str
    generated_at: datetime
    start_date: date
    end_date: date
    total_users: int
    active_users: int
    users: List[UserActivityItem]


# Export Response

class ReportExportResponse(BaseModel):
    """Report export response"""
    success: bool
    report_type: str
    format: str
    file_name: str
    file_url: Optional[str]
    download_url: Optional[str]
    expires_at: Optional[datetime]
