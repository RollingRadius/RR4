"""
Hardcoded Capability Definitions
These are the source of truth for all capabilities in the system.
"""

from typing import Dict, List
from app.models.capability import FeatureCategory


class CapabilityDefinition:
    """Single capability definition"""
    def __init__(self, key: str, category: FeatureCategory, name: str, description: str,
                 access_levels: List[str], is_system_critical: bool = False):
        self.key = key
        self.category = category
        self.name = name
        self.description = description
        self.access_levels = access_levels
        self.is_system_critical = is_system_critical


# Access level sets for convenience
ACCESS_NONE_VIEW_FULL = ["none", "view", "full"]
ACCESS_NONE_VIEW_LIMITED_FULL = ["none", "view", "limited", "full"]
ACCESS_NONE_VIEW = ["none", "view"]


# ====================
# USER MANAGEMENT CAPABILITIES
# ====================
USER_MANAGEMENT_CAPABILITIES = [
    CapabilityDefinition(
        "user.view", FeatureCategory.USER_MANAGEMENT,
        "View Users", "View user list and details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.create", FeatureCategory.USER_MANAGEMENT,
        "Create Users", "Create new user accounts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.edit", FeatureCategory.USER_MANAGEMENT,
        "Edit Users", "Modify user information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.delete", FeatureCategory.USER_MANAGEMENT,
        "Delete Users", "Delete user accounts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.role.assign", FeatureCategory.USER_MANAGEMENT,
        "Assign Roles", "Assign roles to users",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.role.revoke", FeatureCategory.USER_MANAGEMENT,
        "Revoke Roles", "Revoke user roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.password.reset", FeatureCategory.USER_MANAGEMENT,
        "Reset Passwords", "Reset user passwords",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.activate", FeatureCategory.USER_MANAGEMENT,
        "Activate Users", "Activate user accounts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.deactivate", FeatureCategory.USER_MANAGEMENT,
        "Deactivate Users", "Deactivate user accounts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "user.activity.view", FeatureCategory.USER_MANAGEMENT,
        "View Activity Logs", "View user activity logs",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# ROLE MANAGEMENT CAPABILITIES
# ====================
ROLE_MANAGEMENT_CAPABILITIES = [
    CapabilityDefinition(
        "role.view", FeatureCategory.ROLE_MANAGEMENT,
        "View Roles", "View all roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.predefined.view", FeatureCategory.ROLE_MANAGEMENT,
        "View Predefined Roles", "View predefined system roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.custom.view", FeatureCategory.ROLE_MANAGEMENT,
        "View Custom Roles", "View custom roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.custom.create", FeatureCategory.ROLE_MANAGEMENT,
        "Create Custom Roles", "Create new custom roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.custom.edit", FeatureCategory.ROLE_MANAGEMENT,
        "Edit Custom Roles", "Modify custom roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.custom.delete", FeatureCategory.ROLE_MANAGEMENT,
        "Delete Custom Roles", "Delete custom roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.template.view", FeatureCategory.ROLE_MANAGEMENT,
        "View Templates", "View role templates",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.template.use", FeatureCategory.ROLE_MANAGEMENT,
        "Use Templates", "Use templates to create roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.capability.assign", FeatureCategory.ROLE_MANAGEMENT,
        "Assign Capabilities", "Assign capabilities to roles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "role.capability.revoke", FeatureCategory.ROLE_MANAGEMENT,
        "Revoke Capabilities", "Revoke capabilities from roles",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# VEHICLE MANAGEMENT CAPABILITIES
# ====================
VEHICLE_MANAGEMENT_CAPABILITIES = [
    CapabilityDefinition(
        "vehicle.view", FeatureCategory.VEHICLE_MANAGEMENT,
        "View Vehicles", "View vehicle details and list",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.create", FeatureCategory.VEHICLE_MANAGEMENT,
        "Create Vehicles", "Add new vehicles to fleet",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.edit", FeatureCategory.VEHICLE_MANAGEMENT,
        "Edit Vehicles", "Modify vehicle information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.delete", FeatureCategory.VEHICLE_MANAGEMENT,
        "Delete Vehicles", "Remove vehicles from system",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.export", FeatureCategory.VEHICLE_MANAGEMENT,
        "Export Vehicles", "Export vehicle data",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.import", FeatureCategory.VEHICLE_MANAGEMENT,
        "Import Vehicles", "Import vehicles from file",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.archive", FeatureCategory.VEHICLE_MANAGEMENT,
        "Archive Vehicles", "Archive/deactivate vehicles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.assign", FeatureCategory.VEHICLE_MANAGEMENT,
        "Assign Vehicles", "Assign vehicles to drivers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.documents.view", FeatureCategory.VEHICLE_MANAGEMENT,
        "View Documents", "View vehicle documents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.documents.upload", FeatureCategory.VEHICLE_MANAGEMENT,
        "Upload Documents", "Upload vehicle documents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vehicle.documents.delete", FeatureCategory.VEHICLE_MANAGEMENT,
        "Delete Documents", "Delete vehicle documents",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# DRIVER MANAGEMENT CAPABILITIES
# ====================
DRIVER_MANAGEMENT_CAPABILITIES = [
    CapabilityDefinition(
        "driver.view", FeatureCategory.DRIVER_MANAGEMENT,
        "View Drivers", "View driver profiles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.view.all", FeatureCategory.DRIVER_MANAGEMENT,
        "View All Drivers", "View all drivers in system",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.view.own", FeatureCategory.DRIVER_MANAGEMENT,
        "View Own Profile", "View only assigned drivers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.create", FeatureCategory.DRIVER_MANAGEMENT,
        "Create Drivers", "Add new drivers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.edit", FeatureCategory.DRIVER_MANAGEMENT,
        "Edit Drivers", "Modify driver information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.delete", FeatureCategory.DRIVER_MANAGEMENT,
        "Delete Drivers", "Remove drivers from system",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.license.view", FeatureCategory.DRIVER_MANAGEMENT,
        "View Licenses", "View driver license details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.license.manage", FeatureCategory.DRIVER_MANAGEMENT,
        "Manage Licenses", "Manage license information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.performance.view", FeatureCategory.DRIVER_MANAGEMENT,
        "View Performance", "View driver performance metrics",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "driver.assign", FeatureCategory.DRIVER_MANAGEMENT,
        "Assign Drivers", "Assign drivers to vehicles/trips",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# TRIP MANAGEMENT CAPABILITIES
# ====================
TRIP_MANAGEMENT_CAPABILITIES = [
    CapabilityDefinition(
        "trip.view", FeatureCategory.TRIP_MANAGEMENT,
        "View Trips", "View trip details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.view.all", FeatureCategory.TRIP_MANAGEMENT,
        "View All Trips", "View all trips",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.view.own", FeatureCategory.TRIP_MANAGEMENT,
        "View Own Trips", "View only own assigned trips",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.create", FeatureCategory.TRIP_MANAGEMENT,
        "Create Trips", "Create new trips",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.edit", FeatureCategory.TRIP_MANAGEMENT,
        "Edit Trips", "Modify trip details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.delete", FeatureCategory.TRIP_MANAGEMENT,
        "Delete Trips", "Cancel/delete trips",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.assign", FeatureCategory.TRIP_MANAGEMENT,
        "Assign Trips", "Assign trips to drivers/vehicles",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.status.update", FeatureCategory.TRIP_MANAGEMENT,
        "Update Status", "Update trip status",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.route.view", FeatureCategory.TRIP_MANAGEMENT,
        "View Routes", "View trip routes",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.route.modify", FeatureCategory.TRIP_MANAGEMENT,
        "Modify Routes", "Modify trip routes",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.waypoint.add", FeatureCategory.TRIP_MANAGEMENT,
        "Add Waypoints", "Add waypoints to trip",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "trip.waypoint.edit", FeatureCategory.TRIP_MANAGEMENT,
        "Edit Waypoints", "Edit trip waypoints",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# TRACKING CAPABILITIES
# ====================
TRACKING_CAPABILITIES = [
    CapabilityDefinition(
        "tracking.view.all", FeatureCategory.TRACKING,
        "View All Locations", "View all vehicle locations",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.view.active", FeatureCategory.TRACKING,
        "View Active Trips", "View only active trip locations",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.view.own", FeatureCategory.TRACKING,
        "View Own Location", "View only own vehicle location",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.history.view", FeatureCategory.TRACKING,
        "View History", "View historical tracking data",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.history.export", FeatureCategory.TRACKING,
        "Export History", "Export tracking history",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.geofence.view", FeatureCategory.TRACKING,
        "View Geofences", "View geofence alerts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.geofence.create", FeatureCategory.TRACKING,
        "Create Geofences", "Create geofence zones",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.geofence.edit", FeatureCategory.TRACKING,
        "Edit Geofences", "Modify geofence zones",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "tracking.alerts.manage", FeatureCategory.TRACKING,
        "Manage Alerts", "Manage tracking alerts",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# FINANCIAL CAPABILITIES
# ====================
FINANCIAL_CAPABILITIES = [
    CapabilityDefinition(
        "finance.view", FeatureCategory.FINANCIAL,
        "View Financial Data", "View financial data",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "finance.dashboard", FeatureCategory.FINANCIAL,
        "Financial Dashboard", "Access financial dashboard",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.view", FeatureCategory.FINANCIAL,
        "View Expenses", "View expenses",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.create", FeatureCategory.FINANCIAL,
        "Create Expenses", "Submit new expenses",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.edit", FeatureCategory.FINANCIAL,
        "Edit Expenses", "Edit expense details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.delete", FeatureCategory.FINANCIAL,
        "Delete Expenses", "Delete expenses",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.approve", FeatureCategory.FINANCIAL,
        "Approve Expenses", "Approve expense claims",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "expense.reject", FeatureCategory.FINANCIAL,
        "Reject Expenses", "Reject expense claims",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "invoice.view", FeatureCategory.FINANCIAL,
        "View Invoices", "View invoices",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "invoice.create", FeatureCategory.FINANCIAL,
        "Create Invoices", "Create new invoices",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "invoice.edit", FeatureCategory.FINANCIAL,
        "Edit Invoices", "Edit invoice details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "invoice.send", FeatureCategory.FINANCIAL,
        "Send Invoices", "Send invoices to customers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "invoice.delete", FeatureCategory.FINANCIAL,
        "Delete Invoices", "Delete invoices",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "payment.view", FeatureCategory.FINANCIAL,
        "View Payments", "View payment records",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "payment.record", FeatureCategory.FINANCIAL,
        "Record Payments", "Record payments",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "budget.view", FeatureCategory.FINANCIAL,
        "View Budget", "View budget information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "budget.manage", FeatureCategory.FINANCIAL,
        "Manage Budget", "Manage budget allocations",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "finance.export", FeatureCategory.FINANCIAL,
        "Export Financial Data", "Export financial reports",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# MAINTENANCE CAPABILITIES
# ====================
MAINTENANCE_CAPABILITIES = [
    CapabilityDefinition(
        "maintenance.view", FeatureCategory.MAINTENANCE,
        "View Maintenance", "View maintenance records",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.schedule.view", FeatureCategory.MAINTENANCE,
        "View Schedules", "View maintenance schedules",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.schedule.create", FeatureCategory.MAINTENANCE,
        "Create Schedules", "Create maintenance schedules",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.schedule.edit", FeatureCategory.MAINTENANCE,
        "Edit Schedules", "Edit maintenance schedules",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.record.create", FeatureCategory.MAINTENANCE,
        "Log Maintenance", "Log maintenance activity",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.workorder.view", FeatureCategory.MAINTENANCE,
        "View Work Orders", "View work orders",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.workorder.create", FeatureCategory.MAINTENANCE,
        "Create Work Orders", "Create work orders",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.workorder.assign", FeatureCategory.MAINTENANCE,
        "Assign Work Orders", "Assign work orders",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.workorder.update", FeatureCategory.MAINTENANCE,
        "Update Work Orders", "Update work order status",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.workorder.complete", FeatureCategory.MAINTENANCE,
        "Complete Work Orders", "Complete work orders",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.inspection.perform", FeatureCategory.MAINTENANCE,
        "Perform Inspections", "Perform vehicle inspections",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "maintenance.inspection.view", FeatureCategory.MAINTENANCE,
        "View Inspections", "View inspection records",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "parts.view", FeatureCategory.MAINTENANCE,
        "View Parts", "View parts inventory",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "parts.request", FeatureCategory.MAINTENANCE,
        "Request Parts", "Request parts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "parts.manage", FeatureCategory.MAINTENANCE,
        "Manage Parts", "Manage parts inventory",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "parts.order", FeatureCategory.MAINTENANCE,
        "Order Parts", "Order new parts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vendor.view", FeatureCategory.MAINTENANCE,
        "View Vendors", "View vendor information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "vendor.manage", FeatureCategory.MAINTENANCE,
        "Manage Vendors", "Manage vendor relationships",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# COMPLIANCE CAPABILITIES
# ====================
COMPLIANCE_CAPABILITIES = [
    CapabilityDefinition(
        "compliance.view", FeatureCategory.COMPLIANCE,
        "View Compliance", "View compliance information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.license.view", FeatureCategory.COMPLIANCE,
        "View Licenses", "View licenses",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.license.manage", FeatureCategory.COMPLIANCE,
        "Manage Licenses", "Manage licenses and renewals",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.document.view", FeatureCategory.COMPLIANCE,
        "View Documents", "View compliance documents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.document.upload", FeatureCategory.COMPLIANCE,
        "Upload Documents", "Upload compliance documents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.document.manage", FeatureCategory.COMPLIANCE,
        "Manage Documents", "Manage compliance documents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.inspection.view", FeatureCategory.COMPLIANCE,
        "View Inspections", "View inspection records",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.inspection.schedule", FeatureCategory.COMPLIANCE,
        "Schedule Inspections", "Schedule inspections",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.inspection.perform", FeatureCategory.COMPLIANCE,
        "Perform Inspections", "Perform inspections",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.incident.view", FeatureCategory.COMPLIANCE,
        "View Incidents", "View incident reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.incident.create", FeatureCategory.COMPLIANCE,
        "Report Incidents", "Report incidents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.incident.manage", FeatureCategory.COMPLIANCE,
        "Manage Incidents", "Manage incident reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.certification.view", FeatureCategory.COMPLIANCE,
        "View Certifications", "View certifications",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.certification.manage", FeatureCategory.COMPLIANCE,
        "Manage Certifications", "Manage certifications",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.hos.view", FeatureCategory.COMPLIANCE,
        "View HOS Logs", "View Hours of Service logs",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.hos.manage", FeatureCategory.COMPLIANCE,
        "Manage HOS", "Manage HOS compliance",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "compliance.alerts.view", FeatureCategory.COMPLIANCE,
        "View Alerts", "View compliance alerts",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# CUSTOMER CAPABILITIES
# ====================
CUSTOMER_CAPABILITIES = [
    CapabilityDefinition(
        "customer.view", FeatureCategory.CUSTOMER,
        "View Customers", "View customer information",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "customer.create", FeatureCategory.CUSTOMER,
        "Create Customers", "Add new customers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "customer.edit", FeatureCategory.CUSTOMER,
        "Edit Customers", "Edit customer details",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "customer.delete", FeatureCategory.CUSTOMER,
        "Delete Customers", "Delete customers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "customer.contact.manage", FeatureCategory.CUSTOMER,
        "Manage Contacts", "Manage customer contacts",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "support.ticket.view", FeatureCategory.CUSTOMER,
        "View Tickets", "View support tickets",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "support.ticket.create", FeatureCategory.CUSTOMER,
        "Create Tickets", "Create support tickets",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "support.ticket.assign", FeatureCategory.CUSTOMER,
        "Assign Tickets", "Assign tickets to agents",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "support.ticket.update", FeatureCategory.CUSTOMER,
        "Update Tickets", "Update ticket status",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "support.ticket.close", FeatureCategory.CUSTOMER,
        "Close Tickets", "Close support tickets",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "notification.send", FeatureCategory.CUSTOMER,
        "Send Notifications", "Send notifications to customers",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "communication.log.view", FeatureCategory.CUSTOMER,
        "View Communication", "View communication history",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# REPORTING CAPABILITIES
# ====================
REPORTING_CAPABILITIES = [
    CapabilityDefinition(
        "reports.view", FeatureCategory.REPORTING,
        "View Reports", "View reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.fleet.view", FeatureCategory.REPORTING,
        "Fleet Reports", "View fleet performance reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.driver.view", FeatureCategory.REPORTING,
        "Driver Reports", "View driver performance reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.financial.view", FeatureCategory.REPORTING,
        "Financial Reports", "View financial reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.maintenance.view", FeatureCategory.REPORTING,
        "Maintenance Reports", "View maintenance reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.compliance.view", FeatureCategory.REPORTING,
        "Compliance Reports", "View compliance reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.custom.create", FeatureCategory.REPORTING,
        "Custom Reports", "Create custom reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.export", FeatureCategory.REPORTING,
        "Export Reports", "Export reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "reports.schedule", FeatureCategory.REPORTING,
        "Schedule Reports", "Schedule automated reports",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "analytics.dashboard.view", FeatureCategory.REPORTING,
        "View Dashboards", "View analytics dashboards",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "analytics.dashboard.customize", FeatureCategory.REPORTING,
        "Customize Dashboards", "Customize dashboards",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "analytics.kpi.view", FeatureCategory.REPORTING,
        "View KPIs", "View KPIs",
        ACCESS_NONE_VIEW_FULL
    ),
]


# ====================
# SYSTEM CAPABILITIES
# ====================
SYSTEM_CAPABILITIES = [
    CapabilityDefinition(
        "system.settings.view", FeatureCategory.SYSTEM,
        "View Settings", "View system settings",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.settings.edit", FeatureCategory.SYSTEM,
        "Edit Settings", "Modify system settings",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.config.view", FeatureCategory.SYSTEM,
        "View Configuration", "View system configuration",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.config.edit", FeatureCategory.SYSTEM,
        "Edit Configuration", "Modify system configuration",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.audit.view", FeatureCategory.SYSTEM,
        "View Audit Logs", "View audit logs",
        ACCESS_NONE_VIEW_FULL
    ),
    CapabilityDefinition(
        "system.backup.create", FeatureCategory.SYSTEM,
        "Create Backups", "Create system backups",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.backup.restore", FeatureCategory.SYSTEM,
        "Restore Backups", "Restore from backup",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
    CapabilityDefinition(
        "system.integration.manage", FeatureCategory.SYSTEM,
        "Manage Integrations", "Manage API integrations",
        ACCESS_NONE_VIEW_FULL, is_system_critical=True
    ),
]


# ====================
# ALL CAPABILITIES REGISTRY
# ====================
ALL_CAPABILITIES: List[CapabilityDefinition] = (
    USER_MANAGEMENT_CAPABILITIES +
    ROLE_MANAGEMENT_CAPABILITIES +
    VEHICLE_MANAGEMENT_CAPABILITIES +
    DRIVER_MANAGEMENT_CAPABILITIES +
    TRIP_MANAGEMENT_CAPABILITIES +
    TRACKING_CAPABILITIES +
    FINANCIAL_CAPABILITIES +
    MAINTENANCE_CAPABILITIES +
    COMPLIANCE_CAPABILITIES +
    CUSTOMER_CAPABILITIES +
    REPORTING_CAPABILITIES +
    SYSTEM_CAPABILITIES
)


# Create capability lookup dictionary
CAPABILITIES_DICT: Dict[str, CapabilityDefinition] = {
    cap.key: cap for cap in ALL_CAPABILITIES
}


def get_capability(key: str) -> CapabilityDefinition:
    """Get capability definition by key"""
    return CAPABILITIES_DICT.get(key)


def get_capabilities_by_category(category: FeatureCategory) -> List[CapabilityDefinition]:
    """Get all capabilities for a category"""
    return [cap for cap in ALL_CAPABILITIES if cap.category == category]


def get_all_capability_keys() -> List[str]:
    """Get all capability keys"""
    return list(CAPABILITIES_DICT.keys())


# Total count
TOTAL_CAPABILITIES = len(ALL_CAPABILITIES)  # Should be 100+
