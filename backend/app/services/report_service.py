"""
Report Service
Business logic for generating various reports
"""

from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, and_, or_
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
import uuid

from app.models.driver import Driver
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.audit_log import AuditLog
from app.models.role import Role


class ReportService:
    """Service for generating reports"""

    def __init__(self, db: Session):
        self.db = db

    def _get_organization(self, org_id: str) -> Organization:
        """Get organization by ID"""
        org = self.db.query(Organization).filter(
            Organization.id == org_id
        ).first()

        if not org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        return org

    def get_driver_list_report(
        self,
        org_id: str,
        status_filter: Optional[str] = None
    ) -> dict:
        """
        Generate driver list report with license information.

        Args:
            org_id: Organization ID
            status_filter: Optional status filter (active, inactive, etc.)

        Returns:
            Driver list report data
        """
        org = self._get_organization(org_id)

        # Query drivers
        query = self.db.query(Driver).filter(
            Driver.organization_id == org_id
        )

        if status_filter:
            query = query.filter(Driver.status == status_filter)

        drivers = query.order_by(Driver.full_name).all()

        # Calculate statistics
        total_drivers = len(drivers)
        active_drivers = sum(1 for d in drivers if d.status == 'active')
        inactive_drivers = sum(1 for d in drivers if d.status != 'active')

        # Format driver data
        driver_list = []
        today = date.today()

        for driver in drivers:
            license = driver.license
            if license:
                days_until_expiry = (license.expiry_date - today).days
                is_expired = license.expiry_date < today
                is_expiring_soon = 0 < days_until_expiry <= 30
            else:
                days_until_expiry = None
                is_expired = False
                is_expiring_soon = False

            driver_list.append({
                "driver_id": str(driver.id),
                "employee_id": driver.employee_id,
                "full_name": driver.full_name,
                "phone": driver.phone,
                "status": driver.status,
                "license_number": license.license_number if license else None,
                "license_type": license.license_type if license else None,
                "license_expiry": license.expiry_date if license else None,
                "join_date": driver.join_date,
                "days_until_expiry": days_until_expiry,
                "is_license_expired": is_expired,
                "is_license_expiring_soon": is_expiring_soon
            })

        return {
            "success": True,
            "report_type": "driver_list",
            "organization_id": str(org_id),
            "organization_name": org.company_name,
            "generated_at": datetime.utcnow(),
            "total_drivers": total_drivers,
            "active_drivers": active_drivers,
            "inactive_drivers": inactive_drivers,
            "drivers": driver_list
        }

    def get_license_expiry_report(
        self,
        org_id: str,
        days_ahead: int = 90
    ) -> dict:
        """
        Generate license expiry report.

        Args:
            org_id: Organization ID
            days_ahead: Look ahead this many days (default 90)

        Returns:
            License expiry report data
        """
        org = self._get_organization(org_id)

        # Query active drivers with licenses
        drivers = self.db.query(Driver).filter(
            Driver.organization_id == org_id,
            Driver.status == 'active'
        ).all()

        today = date.today()
        cutoff_date = today + timedelta(days=days_ahead)

        expired_licenses = []
        expiring_soon_licenses = []
        valid_licenses = []

        for driver in drivers:
            license = driver.license
            if not license:
                continue

            days_until_expiry = (license.expiry_date - today).days

            license_item = {
                "driver_id": str(driver.id),
                "employee_id": driver.employee_id,
                "full_name": driver.full_name,
                "phone": driver.phone,
                "license_number": license.license_number,
                "license_type": license.license_type,
                "expiry_date": license.expiry_date,
                "days_until_expiry": days_until_expiry
            }

            if license.expiry_date < today:
                license_item["status"] = "expired"
                expired_licenses.append(license_item)
            elif 0 < days_until_expiry <= 30:
                license_item["status"] = "expiring_soon"
                expiring_soon_licenses.append(license_item)
            elif license.expiry_date <= cutoff_date:
                license_item["status"] = "expiring_later"
                valid_licenses.append(license_item)
            else:
                license_item["status"] = "valid"
                valid_licenses.append(license_item)

        # Combine and sort by expiry date
        all_licenses = expired_licenses + expiring_soon_licenses + valid_licenses
        all_licenses.sort(key=lambda x: x['expiry_date'])

        return {
            "success": True,
            "report_type": "license_expiry",
            "organization_id": str(org_id),
            "organization_name": org.company_name,
            "generated_at": datetime.utcnow(),
            "expired_count": len(expired_licenses),
            "expiring_soon_count": len(expiring_soon_licenses),
            "valid_count": len(valid_licenses),
            "licenses": all_licenses
        }

    def get_organization_summary_report(self, org_id: str) -> dict:
        """
        Generate organization summary report.

        Args:
            org_id: Organization ID

        Returns:
            Organization summary report data
        """
        org = self._get_organization(org_id)

        # Driver statistics
        driver_stats = self.db.query(
            Driver.status,
            func.count(Driver.id).label('count')
        ).filter(
            Driver.organization_id == org_id
        ).group_by(Driver.status).all()

        driver_counts = {stat.status: stat.count for stat in driver_stats}
        total_drivers = sum(driver_counts.values())

        # User statistics
        user_stats = self.db.query(
            UserOrganization.status,
            func.count(UserOrganization.id).label('count')
        ).filter(
            UserOrganization.organization_id == org_id
        ).group_by(UserOrganization.status).all()

        user_counts = {stat.status: stat.count for stat in user_stats}
        total_users = sum(user_counts.values())

        # License expiry stats
        today = date.today()
        thirty_days = today + timedelta(days=30)

        active_drivers = self.db.query(Driver).filter(
            Driver.organization_id == org_id,
            Driver.status == 'active'
        ).all()

        licenses_expiring_soon = 0
        expired_licenses = 0

        for driver in active_drivers:
            if driver.license:
                if driver.license.expiry_date < today:
                    expired_licenses += 1
                elif driver.license.expiry_date <= thirty_days:
                    licenses_expiring_soon += 1

        # Recent activity (last 10 audit logs)
        recent_logs = self.db.query(AuditLog).filter(
            AuditLog.organization_id == org_id
        ).order_by(AuditLog.timestamp.desc()).limit(10).all()

        recent_activity = []
        for log in recent_logs:
            recent_activity.append({
                "timestamp": log.timestamp.isoformat(),
                "action": log.action,
                "entity_type": log.entity_type,
                "details": log.details
            })

        stats = {
            "total_drivers": total_drivers,
            "active_drivers": driver_counts.get('active', 0),
            "inactive_drivers": driver_counts.get('inactive', 0),
            "on_leave_drivers": driver_counts.get('on_leave', 0),
            "terminated_drivers": driver_counts.get('terminated', 0),
            "total_users": total_users,
            "active_users": user_counts.get('active', 0),
            "pending_users": user_counts.get('pending', 0),
            "licenses_expiring_soon": licenses_expiring_soon,
            "expired_licenses": expired_licenses
        }

        return {
            "success": True,
            "report_type": "organization_summary",
            "organization_id": str(org_id),
            "organization_name": org.company_name,
            "generated_at": datetime.utcnow(),
            "stats": stats,
            "recent_activity": recent_activity
        }

    def get_audit_log_report(
        self,
        org_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        action_filter: Optional[str] = None,
        limit: int = 100
    ) -> dict:
        """
        Generate audit log report.

        Args:
            org_id: Organization ID
            start_date: Start date for logs
            end_date: End date for logs
            action_filter: Filter by action type
            limit: Maximum number of entries

        Returns:
            Audit log report data
        """
        org = self._get_organization(org_id)

        # Default date range (last 30 days)
        if not end_date:
            end_date = date.today()
        if not start_date:
            start_date = end_date - timedelta(days=30)

        # Query audit logs
        query = self.db.query(AuditLog).options(
            joinedload(AuditLog.user)
        ).filter(
            AuditLog.organization_id == org_id,
            AuditLog.timestamp >= start_date,
            AuditLog.timestamp <= end_date
        )

        if action_filter:
            query = query.filter(AuditLog.action == action_filter)

        logs = query.order_by(AuditLog.timestamp.desc()).limit(limit).all()

        # Format audit log entries
        entries = []
        for log in logs:
            entries.append({
                "id": str(log.id),
                "timestamp": log.timestamp,
                "user_id": str(log.user_id) if log.user_id else None,
                "username": log.user.username if log.user else "System",
                "action": log.action,
                "entity_type": log.entity_type,
                "entity_id": str(log.entity_id) if log.entity_id else None,
                "details": log.details,
                "ip_address": None  # Could be added if IP tracking implemented
            })

        return {
            "success": True,
            "report_type": "audit_log",
            "organization_id": str(org_id),
            "organization_name": org.company_name,
            "generated_at": datetime.utcnow(),
            "start_date": start_date,
            "end_date": end_date,
            "total_entries": len(entries),
            "entries": entries
        }

    def get_user_activity_report(
        self,
        org_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> dict:
        """
        Generate user activity report.

        Args:
            org_id: Organization ID
            start_date: Start date for activity
            end_date: End date for activity

        Returns:
            User activity report data
        """
        org = self._get_organization(org_id)

        # Default date range (last 30 days)
        if not end_date:
            end_date = date.today()
        if not start_date:
            start_date = end_date - timedelta(days=30)

        # Get organization users
        user_orgs = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user),
            joinedload(UserOrganization.role)
        ).filter(
            UserOrganization.organization_id == org_id
        ).all()

        users_data = []
        active_users_count = 0

        for user_org in user_orgs:
            if not user_org.user:
                continue

            user = user_org.user

            # Count actions in date range
            action_count = self.db.query(func.count(AuditLog.id)).filter(
                AuditLog.user_id == user.id,
                AuditLog.organization_id == org_id,
                AuditLog.timestamp >= start_date,
                AuditLog.timestamp <= end_date
            ).scalar()

            # Get recent actions
            recent_actions_query = self.db.query(AuditLog.action).filter(
                AuditLog.user_id == user.id,
                AuditLog.organization_id == org_id,
                AuditLog.timestamp >= start_date,
                AuditLog.timestamp <= end_date
            ).order_by(AuditLog.timestamp.desc()).limit(5).all()

            recent_actions = [action[0] for action in recent_actions_query]

            if user_org.status == 'active':
                active_users_count += 1

            users_data.append({
                "user_id": str(user.id),
                "username": user.username,
                "full_name": user.full_name,
                "role": user_org.role.name if user_org.role else None,
                "status": user_org.status,
                "last_login": user.last_login,
                "total_actions": action_count,
                "recent_actions": recent_actions
            })

        # Sort by total actions
        users_data.sort(key=lambda x: x['total_actions'], reverse=True)

        return {
            "success": True,
            "report_type": "user_activity",
            "organization_id": str(org_id),
            "organization_name": org.company_name,
            "generated_at": datetime.utcnow(),
            "start_date": start_date,
            "end_date": end_date,
            "total_users": len(users_data),
            "active_users": active_users_count,
            "users": users_data
        }
