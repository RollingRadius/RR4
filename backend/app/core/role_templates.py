"""
Predefined Role Templates
Maps the 11 predefined roles to their capabilities
"""

from typing import Dict, List
from app.models.capability import AccessLevel


class RoleTemplate:
    """Single role template definition"""
    def __init__(self, role_key: str, role_name: str, description: str, capabilities: Dict[str, str]):
        self.role_key = role_key
        self.role_name = role_name
        self.description = description
        self.capabilities = capabilities  # Dict[capability_key, access_level]


# ====================
# 1. SUPER ADMIN TEMPLATE
# ====================
SUPER_ADMIN_CAPABILITIES = {
    # All capabilities with FULL access
    # User Management
    "user.view": AccessLevel.FULL,
    "user.create": AccessLevel.FULL,
    "user.edit": AccessLevel.FULL,
    "user.delete": AccessLevel.FULL,
    "user.role.assign": AccessLevel.FULL,
    "user.role.revoke": AccessLevel.FULL,
    "user.password.reset": AccessLevel.FULL,
    "user.activate": AccessLevel.FULL,
    "user.deactivate": AccessLevel.FULL,
    "user.activity.view": AccessLevel.FULL,

    # Role Management
    "role.view": AccessLevel.FULL,
    "role.predefined.view": AccessLevel.FULL,
    "role.custom.view": AccessLevel.FULL,
    "role.custom.create": AccessLevel.FULL,
    "role.custom.edit": AccessLevel.FULL,
    "role.custom.delete": AccessLevel.FULL,
    "role.template.view": AccessLevel.FULL,
    "role.template.use": AccessLevel.FULL,
    "role.capability.assign": AccessLevel.FULL,
    "role.capability.revoke": AccessLevel.FULL,

    # Vehicle Management
    "vehicle.view": AccessLevel.FULL,
    "vehicle.create": AccessLevel.FULL,
    "vehicle.edit": AccessLevel.FULL,
    "vehicle.delete": AccessLevel.FULL,
    "vehicle.export": AccessLevel.FULL,
    "vehicle.import": AccessLevel.FULL,
    "vehicle.archive": AccessLevel.FULL,
    "vehicle.assign": AccessLevel.FULL,
    "vehicle.documents.view": AccessLevel.FULL,
    "vehicle.documents.upload": AccessLevel.FULL,
    "vehicle.documents.delete": AccessLevel.FULL,

    # Driver Management
    "driver.view": AccessLevel.FULL,
    "driver.view.all": AccessLevel.FULL,
    "driver.create": AccessLevel.FULL,
    "driver.edit": AccessLevel.FULL,
    "driver.delete": AccessLevel.FULL,
    "driver.license.view": AccessLevel.FULL,
    "driver.license.manage": AccessLevel.FULL,
    "driver.performance.view": AccessLevel.FULL,
    "driver.assign": AccessLevel.FULL,

    # Trip Management
    "trip.view": AccessLevel.FULL,
    "trip.view.all": AccessLevel.FULL,
    "trip.create": AccessLevel.FULL,
    "trip.edit": AccessLevel.FULL,
    "trip.delete": AccessLevel.FULL,
    "trip.assign": AccessLevel.FULL,
    "trip.status.update": AccessLevel.FULL,
    "trip.route.view": AccessLevel.FULL,
    "trip.route.modify": AccessLevel.FULL,
    "trip.waypoint.add": AccessLevel.FULL,
    "trip.waypoint.edit": AccessLevel.FULL,

    # Tracking
    "tracking.view.all": AccessLevel.FULL,
    "tracking.history.view": AccessLevel.FULL,
    "tracking.history.export": AccessLevel.FULL,
    "tracking.geofence.view": AccessLevel.FULL,
    "tracking.geofence.create": AccessLevel.FULL,
    "tracking.geofence.edit": AccessLevel.FULL,
    "tracking.alerts.manage": AccessLevel.FULL,

    # Financial
    "finance.view": AccessLevel.FULL,
    "finance.dashboard": AccessLevel.FULL,
    "expense.view": AccessLevel.FULL,
    "expense.create": AccessLevel.FULL,
    "expense.edit": AccessLevel.FULL,
    "expense.delete": AccessLevel.FULL,
    "expense.approve": AccessLevel.FULL,
    "expense.reject": AccessLevel.FULL,
    "invoice.view": AccessLevel.FULL,
    "invoice.create": AccessLevel.FULL,
    "invoice.edit": AccessLevel.FULL,
    "invoice.send": AccessLevel.FULL,
    "invoice.delete": AccessLevel.FULL,
    "payment.view": AccessLevel.FULL,
    "payment.record": AccessLevel.FULL,
    "budget.view": AccessLevel.FULL,
    "budget.manage": AccessLevel.FULL,
    "finance.export": AccessLevel.FULL,

    # Maintenance
    "maintenance.view": AccessLevel.FULL,
    "maintenance.schedule.view": AccessLevel.FULL,
    "maintenance.schedule.create": AccessLevel.FULL,
    "maintenance.schedule.edit": AccessLevel.FULL,
    "maintenance.record.create": AccessLevel.FULL,
    "maintenance.workorder.view": AccessLevel.FULL,
    "maintenance.workorder.create": AccessLevel.FULL,
    "maintenance.workorder.assign": AccessLevel.FULL,
    "maintenance.workorder.update": AccessLevel.FULL,
    "maintenance.workorder.complete": AccessLevel.FULL,
    "maintenance.inspection.perform": AccessLevel.FULL,
    "maintenance.inspection.view": AccessLevel.FULL,
    "parts.view": AccessLevel.FULL,
    "parts.request": AccessLevel.FULL,
    "parts.manage": AccessLevel.FULL,
    "parts.order": AccessLevel.FULL,
    "vendor.view": AccessLevel.FULL,
    "vendor.manage": AccessLevel.FULL,

    # Compliance
    "compliance.view": AccessLevel.FULL,
    "compliance.license.view": AccessLevel.FULL,
    "compliance.license.manage": AccessLevel.FULL,
    "compliance.document.view": AccessLevel.FULL,
    "compliance.document.upload": AccessLevel.FULL,
    "compliance.document.manage": AccessLevel.FULL,
    "compliance.inspection.view": AccessLevel.FULL,
    "compliance.inspection.schedule": AccessLevel.FULL,
    "compliance.inspection.perform": AccessLevel.FULL,
    "compliance.incident.view": AccessLevel.FULL,
    "compliance.incident.create": AccessLevel.FULL,
    "compliance.incident.manage": AccessLevel.FULL,
    "compliance.certification.view": AccessLevel.FULL,
    "compliance.certification.manage": AccessLevel.FULL,
    "compliance.hos.view": AccessLevel.FULL,
    "compliance.hos.manage": AccessLevel.FULL,
    "compliance.alerts.view": AccessLevel.FULL,

    # Customer
    "customer.view": AccessLevel.FULL,
    "customer.create": AccessLevel.FULL,
    "customer.edit": AccessLevel.FULL,
    "customer.delete": AccessLevel.FULL,
    "customer.contact.manage": AccessLevel.FULL,
    "support.ticket.view": AccessLevel.FULL,
    "support.ticket.create": AccessLevel.FULL,
    "support.ticket.assign": AccessLevel.FULL,
    "support.ticket.update": AccessLevel.FULL,
    "support.ticket.close": AccessLevel.FULL,
    "notification.send": AccessLevel.FULL,
    "communication.log.view": AccessLevel.FULL,

    # Reporting
    "reports.view": AccessLevel.FULL,
    "reports.fleet.view": AccessLevel.FULL,
    "reports.driver.view": AccessLevel.FULL,
    "reports.financial.view": AccessLevel.FULL,
    "reports.maintenance.view": AccessLevel.FULL,
    "reports.compliance.view": AccessLevel.FULL,
    "reports.custom.create": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
    "reports.schedule": AccessLevel.FULL,
    "analytics.dashboard.view": AccessLevel.FULL,
    "analytics.dashboard.customize": AccessLevel.FULL,
    "analytics.kpi.view": AccessLevel.FULL,

    # System
    "system.settings.view": AccessLevel.FULL,
    "system.settings.edit": AccessLevel.FULL,
    "system.config.view": AccessLevel.FULL,
    "system.config.edit": AccessLevel.FULL,
    "system.audit.view": AccessLevel.FULL,
    "system.backup.create": AccessLevel.FULL,
    "system.backup.restore": AccessLevel.FULL,
    "system.integration.manage": AccessLevel.FULL,
}


# ====================
# 2. FLEET MANAGER TEMPLATE
# ====================
FLEET_MANAGER_CAPABILITIES = {
    # User Management - Limited
    "user.view": AccessLevel.VIEW,

    # Vehicle Management - Full
    "vehicle.view": AccessLevel.FULL,
    "vehicle.create": AccessLevel.FULL,
    "vehicle.edit": AccessLevel.FULL,
    "vehicle.export": AccessLevel.FULL,
    "vehicle.assign": AccessLevel.FULL,
    "vehicle.documents.view": AccessLevel.FULL,
    "vehicle.documents.upload": AccessLevel.FULL,

    # Driver Management - Full
    "driver.view": AccessLevel.FULL,
    "driver.view.all": AccessLevel.FULL,
    "driver.create": AccessLevel.FULL,
    "driver.edit": AccessLevel.FULL,
    "driver.license.view": AccessLevel.FULL,
    "driver.performance.view": AccessLevel.FULL,
    "driver.assign": AccessLevel.FULL,

    # Trip Management - Full
    "trip.view": AccessLevel.FULL,
    "trip.view.all": AccessLevel.FULL,
    "trip.create": AccessLevel.FULL,
    "trip.edit": AccessLevel.FULL,
    "trip.assign": AccessLevel.FULL,
    "trip.status.update": AccessLevel.FULL,
    "trip.route.view": AccessLevel.FULL,
    "trip.route.modify": AccessLevel.FULL,
    "trip.waypoint.add": AccessLevel.FULL,
    "trip.waypoint.edit": AccessLevel.FULL,

    # Tracking - Full
    "tracking.view.all": AccessLevel.FULL,
    "tracking.history.view": AccessLevel.FULL,
    "tracking.history.export": AccessLevel.FULL,
    "tracking.geofence.view": AccessLevel.FULL,

    # Financial - View Only
    "finance.view": AccessLevel.VIEW,
    "expense.view": AccessLevel.VIEW,

    # Maintenance - View and Schedule
    "maintenance.view": AccessLevel.FULL,
    "maintenance.schedule.view": AccessLevel.FULL,
    "maintenance.schedule.create": AccessLevel.FULL,
    "maintenance.schedule.edit": AccessLevel.FULL,
    "maintenance.workorder.view": AccessLevel.FULL,

    # Compliance - View
    "compliance.view": AccessLevel.VIEW,
    "compliance.license.view": AccessLevel.VIEW,
    "compliance.document.view": AccessLevel.VIEW,

    # Reporting
    "reports.view": AccessLevel.FULL,
    "reports.fleet.view": AccessLevel.FULL,
    "reports.driver.view": AccessLevel.FULL,
    "reports.maintenance.view": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
    "analytics.dashboard.view": AccessLevel.FULL,
    "analytics.kpi.view": AccessLevel.FULL,
}


# ====================
# 3. DISPATCHER TEMPLATE
# ====================
DISPATCHER_CAPABILITIES = {
    # Vehicle Management - View Only
    "vehicle.view": AccessLevel.VIEW,

    # Driver Management - View Only
    "driver.view": AccessLevel.VIEW,
    "driver.view.all": AccessLevel.VIEW,

    # Trip Management - Full
    "trip.view": AccessLevel.FULL,
    "trip.view.all": AccessLevel.FULL,
    "trip.create": AccessLevel.FULL,
    "trip.edit": AccessLevel.FULL,
    "trip.assign": AccessLevel.FULL,
    "trip.status.update": AccessLevel.FULL,
    "trip.route.view": AccessLevel.FULL,
    "trip.route.modify": AccessLevel.FULL,
    "trip.waypoint.add": AccessLevel.FULL,
    "trip.waypoint.edit": AccessLevel.FULL,

    # Tracking - Active Only
    "tracking.view.active": AccessLevel.FULL,
    "tracking.history.view": AccessLevel.LIMITED,
    "tracking.geofence.view": AccessLevel.FULL,

    # Customer - Limited
    "customer.view": AccessLevel.VIEW,
    "notification.send": AccessLevel.FULL,
    "communication.log.view": AccessLevel.VIEW,

    # Reporting - Limited
    "reports.view": AccessLevel.VIEW,
    "reports.fleet.view": AccessLevel.VIEW,
    "reports.driver.view": AccessLevel.VIEW,
}


# ====================
# 4. DRIVER TEMPLATE
# ====================
DRIVER_CAPABILITIES = {
    # Vehicle Management - Own Vehicle Only
    "vehicle.view": AccessLevel.LIMITED,

    # Driver Management - Own Profile Only
    "driver.view.own": AccessLevel.FULL,
    "driver.license.view": AccessLevel.LIMITED,

    # Trip Management - Own Trips Only
    "trip.view.own": AccessLevel.FULL,
    "trip.status.update": AccessLevel.FULL,
    "trip.route.view": AccessLevel.FULL,

    # Tracking - Own Location Only
    "tracking.view.own": AccessLevel.FULL,

    # Maintenance - Report Issues
    "maintenance.workorder.view": AccessLevel.LIMITED,
    "maintenance.inspection.view": AccessLevel.LIMITED,

    # Compliance - Own Documents
    "compliance.document.view": AccessLevel.LIMITED,
    "compliance.document.upload": AccessLevel.LIMITED,
    "compliance.incident.create": AccessLevel.FULL,

    # Expense - Submit Own
    "expense.create": AccessLevel.FULL,
    "expense.view": AccessLevel.LIMITED,

    # Support
    "support.ticket.create": AccessLevel.FULL,

    # Reporting - Own Only
    "reports.view": AccessLevel.LIMITED,
}


# ====================
# 5. ACCOUNTANT TEMPLATE
# ====================
ACCOUNTANT_CAPABILITIES = {
    # Financial - Full Access
    "finance.view": AccessLevel.FULL,
    "finance.dashboard": AccessLevel.FULL,
    "expense.view": AccessLevel.FULL,
    "expense.create": AccessLevel.FULL,
    "expense.edit": AccessLevel.FULL,
    "expense.delete": AccessLevel.FULL,
    "expense.approve": AccessLevel.FULL,
    "expense.reject": AccessLevel.FULL,
    "invoice.view": AccessLevel.FULL,
    "invoice.create": AccessLevel.FULL,
    "invoice.edit": AccessLevel.FULL,
    "invoice.send": AccessLevel.FULL,
    "invoice.delete": AccessLevel.FULL,
    "payment.view": AccessLevel.FULL,
    "payment.record": AccessLevel.FULL,
    "budget.view": AccessLevel.FULL,
    "budget.manage": AccessLevel.FULL,
    "finance.export": AccessLevel.FULL,

    # Limited Operational View
    "vehicle.view": AccessLevel.VIEW,
    "driver.view": AccessLevel.VIEW,
    "trip.view": AccessLevel.VIEW,
    "maintenance.view": AccessLevel.VIEW,

    # Reporting - Financial
    "reports.view": AccessLevel.FULL,
    "reports.financial.view": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
    "analytics.dashboard.view": AccessLevel.FULL,

    # System - Audit Logs
    "system.audit.view": AccessLevel.LIMITED,
}


# ====================
# 6. MAINTENANCE MANAGER TEMPLATE
# ====================
MAINTENANCE_MANAGER_CAPABILITIES = {
    # Vehicle Management - View
    "vehicle.view": AccessLevel.VIEW,
    "vehicle.documents.view": AccessLevel.VIEW,

    # Driver Management - Limited View
    "driver.view": AccessLevel.VIEW,

    # Maintenance - Full Access
    "maintenance.view": AccessLevel.FULL,
    "maintenance.schedule.view": AccessLevel.FULL,
    "maintenance.schedule.create": AccessLevel.FULL,
    "maintenance.schedule.edit": AccessLevel.FULL,
    "maintenance.record.create": AccessLevel.FULL,
    "maintenance.workorder.view": AccessLevel.FULL,
    "maintenance.workorder.create": AccessLevel.FULL,
    "maintenance.workorder.assign": AccessLevel.FULL,
    "maintenance.workorder.update": AccessLevel.FULL,
    "maintenance.workorder.complete": AccessLevel.FULL,
    "maintenance.inspection.perform": AccessLevel.FULL,
    "maintenance.inspection.view": AccessLevel.FULL,
    "parts.view": AccessLevel.FULL,
    "parts.request": AccessLevel.FULL,
    "parts.manage": AccessLevel.FULL,
    "parts.order": AccessLevel.FULL,
    "vendor.view": AccessLevel.FULL,
    "vendor.manage": AccessLevel.FULL,

    # Financial - Limited
    "expense.view": AccessLevel.VIEW,
    "expense.create": AccessLevel.FULL,

    # Compliance - Limited
    "compliance.inspection.view": AccessLevel.VIEW,
    "compliance.inspection.schedule": AccessLevel.FULL,
    "compliance.document.upload": AccessLevel.FULL,

    # Reporting
    "reports.view": AccessLevel.FULL,
    "reports.maintenance.view": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
}


# ====================
# 7. COMPLIANCE OFFICER TEMPLATE
# ====================
COMPLIANCE_OFFICER_CAPABILITIES = {
    # Vehicle/Driver - View for Compliance
    "vehicle.view": AccessLevel.VIEW,
    "driver.view": AccessLevel.VIEW,
    "driver.view.all": AccessLevel.VIEW,
    "driver.license.view": AccessLevel.FULL,

    # Compliance - Full Access
    "compliance.view": AccessLevel.FULL,
    "compliance.license.view": AccessLevel.FULL,
    "compliance.license.manage": AccessLevel.FULL,
    "compliance.document.view": AccessLevel.FULL,
    "compliance.document.upload": AccessLevel.FULL,
    "compliance.document.manage": AccessLevel.FULL,
    "compliance.inspection.view": AccessLevel.FULL,
    "compliance.inspection.schedule": AccessLevel.FULL,
    "compliance.inspection.perform": AccessLevel.FULL,
    "compliance.incident.view": AccessLevel.FULL,
    "compliance.incident.create": AccessLevel.FULL,
    "compliance.incident.manage": AccessLevel.FULL,
    "compliance.certification.view": AccessLevel.FULL,
    "compliance.certification.manage": AccessLevel.FULL,
    "compliance.hos.view": AccessLevel.FULL,
    "compliance.hos.manage": AccessLevel.FULL,
    "compliance.alerts.view": AccessLevel.FULL,

    # Maintenance - View for Inspections
    "maintenance.inspection.view": AccessLevel.VIEW,

    # Reporting
    "reports.view": AccessLevel.FULL,
    "reports.compliance.view": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,

    # System - Audit
    "system.audit.view": AccessLevel.FULL,
}


# ====================
# 8. OPERATIONS MANAGER TEMPLATE
# ====================
OPERATIONS_MANAGER_CAPABILITIES = {
    # User Management - Limited
    "user.view": AccessLevel.VIEW,
    "user.activity.view": AccessLevel.FULL,

    # Vehicle/Driver - View and Limited Edit
    "vehicle.view": AccessLevel.FULL,
    "vehicle.assign": AccessLevel.FULL,
    "driver.view": AccessLevel.FULL,
    "driver.view.all": AccessLevel.FULL,
    "driver.performance.view": AccessLevel.FULL,
    "driver.assign": AccessLevel.FULL,

    # Trip Management - Full
    "trip.view": AccessLevel.FULL,
    "trip.view.all": AccessLevel.FULL,
    "trip.assign": AccessLevel.FULL,
    "trip.edit": AccessLevel.FULL,
    "trip.route.view": AccessLevel.FULL,
    "trip.route.modify": AccessLevel.FULL,

    # Tracking - Full
    "tracking.view.all": AccessLevel.FULL,
    "tracking.history.view": AccessLevel.FULL,
    "tracking.history.export": AccessLevel.FULL,
    "tracking.geofence.view": AccessLevel.FULL,
    "tracking.geofence.create": AccessLevel.FULL,
    "tracking.alerts.manage": AccessLevel.FULL,

    # Financial - View Summary
    "finance.view": AccessLevel.VIEW,
    "expense.view": AccessLevel.VIEW,
    "expense.approve": AccessLevel.LIMITED,
    "budget.view": AccessLevel.VIEW,

    # Maintenance - View
    "maintenance.view": AccessLevel.VIEW,
    "maintenance.schedule.view": AccessLevel.VIEW,

    # Compliance - View
    "compliance.view": AccessLevel.VIEW,
    "compliance.alerts.view": AccessLevel.VIEW,

    # Customer - View
    "customer.view": AccessLevel.VIEW,
    "support.ticket.view": AccessLevel.VIEW,

    # Reporting - Full
    "reports.view": AccessLevel.FULL,
    "reports.fleet.view": AccessLevel.FULL,
    "reports.driver.view": AccessLevel.FULL,
    "reports.financial.view": AccessLevel.VIEW,
    "reports.maintenance.view": AccessLevel.VIEW,
    "reports.compliance.view": AccessLevel.VIEW,
    "reports.custom.create": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
    "analytics.dashboard.view": AccessLevel.FULL,
    "analytics.dashboard.customize": AccessLevel.FULL,
    "analytics.kpi.view": AccessLevel.FULL,

    # System - Audit
    "system.audit.view": AccessLevel.FULL,
}


# ====================
# 9. MAINTENANCE TECHNICIAN TEMPLATE
# ====================
MAINTENANCE_TECHNICIAN_CAPABILITIES = {
    # Vehicle - Limited View
    "vehicle.view": AccessLevel.LIMITED,

    # Maintenance - Limited to Assigned Work
    "maintenance.workorder.view": AccessLevel.LIMITED,
    "maintenance.workorder.update": AccessLevel.FULL,
    "maintenance.workorder.complete": AccessLevel.FULL,
    "maintenance.inspection.perform": AccessLevel.FULL,
    "maintenance.inspection.view": AccessLevel.LIMITED,
    "maintenance.record.create": AccessLevel.FULL,
    "parts.view": AccessLevel.VIEW,
    "parts.request": AccessLevel.FULL,

    # Reporting - Own Work
    "reports.view": AccessLevel.LIMITED,
}


# ====================
# 10. CUSTOMER SERVICE TEMPLATE
# ====================
CUSTOMER_SERVICE_CAPABILITIES = {
    # Customer - Full Access
    "customer.view": AccessLevel.FULL,
    "customer.create": AccessLevel.FULL,
    "customer.edit": AccessLevel.FULL,
    "customer.contact.manage": AccessLevel.FULL,
    "support.ticket.view": AccessLevel.FULL,
    "support.ticket.create": AccessLevel.FULL,
    "support.ticket.update": AccessLevel.FULL,
    "support.ticket.close": AccessLevel.FULL,
    "notification.send": AccessLevel.FULL,
    "communication.log.view": AccessLevel.FULL,

    # Operational View for Customer Support
    "vehicle.view": AccessLevel.VIEW,
    "driver.view": AccessLevel.VIEW,
    "trip.view": AccessLevel.VIEW,
    "tracking.view.active": AccessLevel.VIEW,

    # Reporting - Customer Service
    "reports.view": AccessLevel.VIEW,
    "reports.export": AccessLevel.LIMITED,
}


# ====================
# 11. VIEWER/ANALYST TEMPLATE
# ====================
VIEWER_ANALYST_CAPABILITIES = {
    # All View Access
    "user.view": AccessLevel.VIEW,
    "vehicle.view": AccessLevel.VIEW,
    "driver.view": AccessLevel.VIEW,
    "driver.view.all": AccessLevel.VIEW,
    "trip.view": AccessLevel.VIEW,
    "trip.view.all": AccessLevel.VIEW,
    "tracking.view.all": AccessLevel.VIEW,
    "tracking.history.view": AccessLevel.VIEW,
    "finance.view": AccessLevel.VIEW,
    "expense.view": AccessLevel.VIEW,
    "maintenance.view": AccessLevel.VIEW,
    "compliance.view": AccessLevel.VIEW,
    "customer.view": AccessLevel.VIEW,

    # Reporting - Full
    "reports.view": AccessLevel.FULL,
    "reports.fleet.view": AccessLevel.FULL,
    "reports.driver.view": AccessLevel.FULL,
    "reports.financial.view": AccessLevel.FULL,
    "reports.maintenance.view": AccessLevel.FULL,
    "reports.compliance.view": AccessLevel.FULL,
    "reports.custom.create": AccessLevel.FULL,
    "reports.export": AccessLevel.FULL,
    "reports.schedule": AccessLevel.FULL,
    "analytics.dashboard.view": AccessLevel.FULL,
    "analytics.dashboard.customize": AccessLevel.FULL,
    "analytics.kpi.view": AccessLevel.FULL,
}


# ====================
# ALL ROLE TEMPLATES
# ====================
ROLE_TEMPLATES: List[RoleTemplate] = [
    RoleTemplate(
        "super_admin",
        "Super Admin",
        "Highest level of access with full system control",
        SUPER_ADMIN_CAPABILITIES
    ),
    RoleTemplate(
        "fleet_manager",
        "Fleet Manager",
        "Manages day-to-day fleet operations",
        FLEET_MANAGER_CAPABILITIES
    ),
    RoleTemplate(
        "dispatcher",
        "Dispatcher",
        "Coordinates vehicle assignments and schedules",
        DISPATCHER_CAPABILITIES
    ),
    RoleTemplate(
        "driver",
        "Driver",
        "Operates vehicles and completes assigned trips",
        DRIVER_CAPABILITIES
    ),
    RoleTemplate(
        "accountant",
        "Accountant/Finance Manager",
        "Manages financial aspects of fleet operations",
        ACCOUNTANT_CAPABILITIES
    ),
    RoleTemplate(
        "maintenance_manager",
        "Maintenance Manager",
        "Oversees vehicle maintenance and repairs",
        MAINTENANCE_MANAGER_CAPABILITIES
    ),
    RoleTemplate(
        "compliance_officer",
        "Compliance Officer",
        "Ensures regulatory compliance and documentation",
        COMPLIANCE_OFFICER_CAPABILITIES
    ),
    RoleTemplate(
        "operations_manager",
        "Operations Manager",
        "Oversees overall fleet operations and strategy",
        OPERATIONS_MANAGER_CAPABILITIES
    ),
    RoleTemplate(
        "maintenance_technician",
        "Maintenance Technician",
        "Performs vehicle maintenance and repairs",
        MAINTENANCE_TECHNICIAN_CAPABILITIES
    ),
    RoleTemplate(
        "customer_service",
        "Customer Service Representative",
        "Handles customer inquiries and support",
        CUSTOMER_SERVICE_CAPABILITIES
    ),
    RoleTemplate(
        "viewer_analyst",
        "Viewer/Analyst",
        "Read-only access for monitoring and reporting",
        VIEWER_ANALYST_CAPABILITIES
    ),
]


# Create template lookup dictionary
ROLE_TEMPLATES_DICT: Dict[str, RoleTemplate] = {
    template.role_key: template for template in ROLE_TEMPLATES
}


def get_role_template(role_key: str) -> RoleTemplate:
    """Get role template by key"""
    return ROLE_TEMPLATES_DICT.get(role_key)


def get_all_template_keys() -> List[str]:
    """Get all role template keys"""
    return list(ROLE_TEMPLATES_DICT.keys())
