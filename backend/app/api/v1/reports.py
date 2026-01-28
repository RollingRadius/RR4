"""
Reports API Endpoints
Generate and retrieve various reports
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.schemas.report import (
    DriverListReportResponse,
    LicenseExpiryReportResponse,
    OrganizationSummaryReportResponse,
    AuditLogReportResponse,
    UserActivityReportResponse
)
from app.services.report_service import ReportService

router = APIRouter()


@router.get("/driver-list", response_model=DriverListReportResponse)
async def get_driver_list_report(
    status_filter: Optional[str] = Query(None, description="Filter by status (active/inactive/on_leave/terminated)"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Generate driver list report.

    **Requires:**
    - Authentication
    - Active organization membership

    **Query Parameters:**
    - status_filter: Optional status filter

    **Returns:**
    - Complete list of drivers with license information
    - Statistics: total, active, inactive drivers
    - License expiry information for each driver

    **Use Cases:**
    - Overview of all drivers in organization
    - Quick check of driver status
    - License compliance monitoring
    """
    report_service = ReportService(db)
    result = report_service.get_driver_list_report(org_id, status_filter)
    return DriverListReportResponse(**result)


@router.get("/license-expiry", response_model=LicenseExpiryReportResponse)
async def get_license_expiry_report(
    days_ahead: int = Query(90, ge=1, le=365, description="Look ahead this many days"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Generate license expiry report.

    **Requires:**
    - Authentication
    - Active organization membership

    **Query Parameters:**
    - days_ahead: How many days to look ahead (default: 90)

    **Returns:**
    - Expired licenses count
    - Licenses expiring soon (within 30 days)
    - Valid licenses
    - Detailed list sorted by expiry date

    **Use Cases:**
    - Compliance monitoring
    - Proactive license renewal
    - Avoid operational disruptions
    - Regulatory compliance
    """
    report_service = ReportService(db)
    result = report_service.get_license_expiry_report(org_id, days_ahead)
    return LicenseExpiryReportResponse(**result)


@router.get("/organization-summary", response_model=OrganizationSummaryReportResponse)
async def get_organization_summary_report(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Generate organization summary report.

    **Requires:**
    - Authentication
    - Active organization membership

    **Returns:**
    - Driver statistics (total, active, inactive, on leave, terminated)
    - User statistics (total, active, pending)
    - License compliance (expiring soon, expired)
    - Recent activity log

    **Use Cases:**
    - Dashboard overview
    - Management summary
    - Quick health check of organization
    - KPI monitoring
    """
    report_service = ReportService(db)
    result = report_service.get_organization_summary_report(org_id)
    return OrganizationSummaryReportResponse(**result)


@router.get("/audit-log", response_model=AuditLogReportResponse)
async def get_audit_log_report(
    start_date: Optional[date] = Query(None, description="Start date (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date (default: today)"),
    action_filter: Optional[str] = Query(None, description="Filter by action type"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum entries to return"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Generate audit log report.

    **Requires:**
    - Authentication
    - Active organization membership

    **Query Parameters:**
    - start_date: Start date for logs (default: 30 days ago)
    - end_date: End date for logs (default: today)
    - action_filter: Filter by action type
    - limit: Maximum entries (default: 100, max: 1000)

    **Returns:**
    - Chronological list of audit log entries
    - User actions
    - System events
    - Timestamps and details

    **Use Cases:**
    - Security auditing
    - Compliance reporting
    - Troubleshooting user issues
    - Track system changes

    **Common Action Filters:**
    - user_login
    - user_logout
    - driver_created
    - driver_updated
    - user_approved
    - role_changed
    """
    report_service = ReportService(db)
    result = report_service.get_audit_log_report(
        org_id, start_date, end_date, action_filter, limit
    )
    return AuditLogReportResponse(**result)


@router.get("/user-activity", response_model=UserActivityReportResponse)
async def get_user_activity_report(
    start_date: Optional[date] = Query(None, description="Start date (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date (default: today)"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Generate user activity report.

    **Requires:**
    - Authentication
    - Active organization membership

    **Query Parameters:**
    - start_date: Start date for activity (default: 30 days ago)
    - end_date: End date for activity (default: today)

    **Returns:**
    - List of users with activity metrics
    - Total actions per user
    - Recent actions
    - Last login time
    - User status and role

    **Use Cases:**
    - User engagement analysis
    - Identify inactive users
    - Audit user productivity
    - License utilization tracking

    **Sorted By:**
    - Most active users first (by total actions)
    """
    report_service = ReportService(db)
    result = report_service.get_user_activity_report(
        org_id, start_date, end_date
    )
    return UserActivityReportResponse(**result)
