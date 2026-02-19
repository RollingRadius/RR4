# Fleet Management System

A comprehensive fleet management application built with Flutter and PostgreSQL for managing vehicles, drivers, and real-time tracking.

## Overview

This system provides a sophisticated **capability-based role access control** for managing fleet operations efficiently. The platform combines **100+ hardcoded capability identifiers** with **11 predefined role templates** and a powerful **Custom Role Builder**, giving administrators complete freedom to create precise access control.

### Dual-Layer Permission System

**Layer 1: Capability-Based Permissions (Hardcoded)**
- 100+ granular capability identifiers (e.g., `vehicle.create`, `driver.view.all`)
- Defined in code for type safety and consistency
- Each capability represents a specific action in the system
- Cannot be modified by users, ensuring system integrity

**Layer 2: Template-Based Roles (Configurable)**
- 11 predefined roles as ready-to-use templates
- Each template is a curated collection of capabilities
- Administrators can use templates as-is or customize them
- Mix capabilities from multiple templates
- Create unlimited custom roles

**Key Features:**
- **11 Predefined Role Templates:** Ready-to-use roles covering all fleet management aspects
- **100+ Hardcoded Capabilities:** Granular control at the feature level
- **Template-Based Customization:** Each predefined role serves as a customizable template
- **Mix & Match:** Combine capabilities from multiple templates into one custom role
- **Start from Scratch:** Build completely custom roles by selecting individual capabilities
- **Reusable Templates:** Save your custom roles as templates for future use
- **Access Levels:** Set capabilities to None/View/Limited/Full
- **Custom Constraints:** Add regional, time-based, or other constraints to capabilities
- **Unlimited Custom Roles:** Create as many custom roles as needed
- **Real-time Updates:** Modify capabilities without disrupting active users
- **Impact Analysis:** See which users will be affected before making changes
- **Complete Audit Trail:** Track all role and capability changes
- **Type-Safe:** Hardcoded identifiers prevent typos and ensure API consistency
- **User Freedom:** Empower administrators to create roles without developer intervention

**How It Works:**
1. **Developers** define hardcoded capabilities in code (e.g., `vehicle.create`)
2. **System** groups capabilities into 11 predefined role templates
3. **Administrators** select template(s) to start with
4. **Administrators** customize by adding/removing capabilities
5. **Administrators** save as custom role or reusable template
6. **Users** get assigned roles and receive exact capabilities needed
7. **System** enforces capabilities on every API call

This dual-layer approach provides:
- **For Developers:** Clean, maintainable, type-safe capability definitions
- **For Administrators:** Flexible template system that doesn't require coding
- **For Users:** Precise access control tailored to their specific needs
- **For Organizations:** Maximum flexibility without sacrificing security or consistency

---

## System Roles and Permissions

### 1. Super Admin
**Description:** Highest level of access with full system control

**Abilities & Features:**
- **User Management**
  - Create, edit, and delete all user accounts
  - Assign and modify user roles
  - Reset user passwords
  - View user activity logs

- **Vehicle Management**
  - Add, edit, and delete vehicles
  - View complete vehicle details and history
  - Manage vehicle maintenance schedules
  - Archive/activate vehicles
  - Import/export vehicle data

- **Real-time Tracking**
  - View live location of all vehicles
  - Access historical tracking data
  - Set up geofencing and alerts
  - Generate location reports
  - Configure tracking parameters

- **System Configuration**
  - Manage system settings
  - Configure database parameters
  - Set up integrations and APIs
  - Access system logs and analytics
  - Backup and restore data

- **Organization Management**
  - Create and manage multiple organizations (if multi-tenant)
  - View cross-organization reports
  - Manage subscription and billing

---

### 2. Fleet Manager
**Description:** Manages day-to-day fleet operations

**Abilities & Features:**
- **Vehicle Management**
  - Add and edit vehicles
  - View vehicle details and status
  - Schedule and track maintenance
  - Assign vehicles to drivers

- **Driver Management**
  - Add, edit driver profiles
  - Assign drivers to vehicles
  - View driver performance metrics
  - Manage driver schedules

- **Real-time Tracking**
  - View live location of fleet vehicles
  - Monitor vehicle status and alerts
  - Generate trip reports
  - Set up notifications for specific events

- **Trip Management**
  - Create and assign trips
  - Monitor ongoing trips
  - View trip history and reports

- **Reports & Analytics**
  - Generate fleet performance reports
  - View fuel consumption data
  - Access maintenance history
  - Export data for analysis

---

### 3. Dispatcher
**Description:** Coordinates vehicle assignments and schedules

**Abilities & Features:**
- **Trip Management**
  - Create and schedule trips
  - Assign vehicles and drivers
  - Modify trip details
  - Cancel or reschedule trips

- **Real-time Tracking**
  - View live location of active vehicles
  - Monitor trip progress
  - Receive real-time alerts

- **Driver Communication**
  - Send notifications to drivers
  - Update trip instructions
  - Receive status updates from drivers

- **Limited Vehicle Access**
  - View vehicle availability
  - Check vehicle status (read-only)
  - View basic vehicle information

---

### 4. Driver
**Description:** Operates vehicles and completes assigned trips

**Abilities & Features:**
- **Trip Access**
  - View assigned trips
  - Update trip status (started, in-progress, completed)
  - Mark delivery/pickup points

- **Vehicle Information**
  - View assigned vehicle details (read-only)
  - Report vehicle issues
  - View maintenance reminders

- **Location Sharing**
  - Automatic GPS tracking during trips
  - Share real-time location

- **Limited Reporting**
  - Submit trip reports
  - Report incidents or issues
  - View personal trip history

---

### 5. Accountant/Finance Manager
**Description:** Manages financial aspects of fleet operations

**Abilities & Features:**
- **Financial Management**
  - View and manage all expenses (fuel, maintenance, tolls, etc.)
  - Process driver reimbursements
  - Generate invoices for clients
  - Manage payment records
  - Track revenue and costs per vehicle/trip

- **Billing & Invoicing**
  - Create and send invoices
  - Track payment status
  - Manage client billing information
  - Generate tax reports

- **Budget Management**
  - Set and monitor budget allocations
  - Track departmental expenses
  - Generate financial forecasts
  - View profit/loss reports

- **Expense Tracking**
  - Approve/reject expense claims
  - Categorize expenses
  - Export financial data for accounting software
  - Manage vendor payments

- **Limited Operational Access**
  - View vehicle and trip details (read-only)
  - Access driver information for payroll
  - View maintenance records for cost analysis

---

### 6. Maintenance Manager
**Description:** Oversees vehicle maintenance and repairs

**Abilities & Features:**
- **Maintenance Scheduling**
  - Create and manage maintenance schedules
  - Set up preventive maintenance plans
  - Schedule vehicle inspections
  - Assign maintenance tasks to technicians

- **Vehicle Health Monitoring**
  - View vehicle diagnostics and alerts
  - Track vehicle health metrics
  - Monitor odometer readings
  - Set up maintenance reminders

- **Repair Management**
  - Create and manage repair orders
  - Track repair history
  - Manage spare parts inventory
  - Approve repair estimates

- **Vendor Management**
  - Maintain vendor/workshop database
  - Track service provider performance
  - Manage warranty information

- **Compliance**
  - Track vehicle certifications and inspections
  - Ensure vehicles meet safety standards
  - Generate maintenance compliance reports

- **Limited Access**
  - View vehicle information (read-only)
  - Cannot modify trip assignments
  - View driver reports related to vehicle issues

---

### 7. Compliance Officer
**Description:** Ensures regulatory compliance and documentation

**Abilities & Features:**
- **License Management**
  - Track driver licenses and expiration dates
  - Manage vehicle registration and permits
  - Monitor insurance policies
  - Set up renewal reminders

- **Regulatory Compliance**
  - Ensure adherence to transportation regulations
  - Track Hours of Service (HOS) compliance
  - Monitor weight restrictions and permits
  - Maintain DOT compliance records

- **Document Management**
  - Upload and manage legal documents
  - Track document expiration dates
  - Generate compliance reports
  - Maintain audit trails

- **Safety & Inspections**
  - Schedule safety inspections
  - Track accident and incident reports
  - Manage driver training certifications
  - Monitor safety violations

- **Reporting**
  - Generate compliance reports for authorities
  - Export data for audits
  - Track non-compliance incidents

- **Limited Operational Access**
  - View driver and vehicle information (read-only)
  - Access trip history for compliance checks
  - Cannot modify operational data

---

### 8. Operations Manager
**Description:** Oversees overall fleet operations and strategy

**Abilities & Features:**
- **Strategic Planning**
  - View comprehensive operational dashboards
  - Access all performance metrics
  - Monitor KPIs and targets
  - Analyze operational efficiency

- **Resource Allocation**
  - Approve vehicle and driver assignments
  - Optimize route planning
  - Balance workload distribution
  - Monitor resource utilization

- **Performance Management**
  - Review team performance
  - Monitor SLA compliance
  - Track customer satisfaction
  - Approve operational changes

- **Full Visibility**
  - Access all fleet data (read-only for most)
  - View financial summaries
  - Monitor maintenance status
  - Review compliance reports

- **Decision Making**
  - Approve major operational decisions
  - Set operational policies
  - Manage escalations
  - Configure business rules

- **Partial Edit Rights**
  - Can override assignments in emergencies
  - Approve/reject major changes
  - Cannot modify system settings

---

### 9. Maintenance Technician
**Description:** Performs vehicle maintenance and repairs

**Abilities & Features:**
- **Work Order Management**
  - View assigned maintenance tasks
  - Update task status (pending, in-progress, completed)
  - Record work performed
  - Log parts used

- **Vehicle Inspection**
  - Conduct vehicle inspections
  - Report inspection results
  - Log defects and issues
  - Update vehicle health status

- **Parts Management**
  - Request spare parts
  - Update parts inventory after use
  - View parts availability

- **Time Tracking**
  - Log work hours
  - Track time per job
  - Submit completed work for approval

- **Limited Access**
  - View assigned vehicle information only
  - Cannot access financial data
  - Cannot modify maintenance schedules

---

### 10. Customer Service Representative
**Description:** Handles customer inquiries and support

**Abilities & Features:**
- **Customer Management**
  - View customer information
  - Update customer details
  - Track customer communication history
  - Manage customer inquiries

- **Trip Monitoring**
  - View active and scheduled trips
  - Track shipment/delivery status
  - Provide ETA to customers
  - Monitor real-time vehicle locations (customer trips only)

- **Issue Resolution**
  - Log customer complaints
  - Create support tickets
  - Track issue resolution
  - Escalate critical issues

- **Communication**
  - Send notifications to customers
  - Update customers on trip status
  - Coordinate with dispatchers for updates

- **Reporting**
  - Generate customer service reports
  - View customer satisfaction metrics
  - Access trip history for customer inquiries

- **Limited Access**
  - Cannot modify trip assignments
  - Cannot access financial data
  - Cannot manage vehicles or drivers
  - Read-only access to operational data

---

### 11. Viewer/Analyst
**Description:** Read-only access for monitoring and reporting

**Abilities & Features:**
- **View-Only Access**
  - View all vehicles and their status
  - Access historical data and reports
  - Monitor real-time tracking

- **Reports & Analytics**
  - Generate custom reports
  - Export data
  - View dashboards and analytics

- **No Modification Rights**
  - Cannot add, edit, or delete any data
  - Cannot assign trips or vehicles

---

### 12. Custom Role
**Description:** Flexible role with customizable permissions tailored to specific organizational needs

**Overview:**
Custom roles allow administrators to create specialized roles by selecting specific features and permissions from all available system capabilities. Each of the 11 predefined roles serves as a ready-to-use template, giving users complete freedom to start with any existing role and customize it, or build a role from scratch.

**How It Works:**
- **Start with Templates:** Use any of the 11 predefined roles (Super Admin, Fleet Manager, Dispatcher, etc.) as a starting template
- **Mix and Match:** Combine permissions from multiple predefined roles into one custom role
- **Build from Scratch:** Start with a blank role and add permissions individually
- **Granular Control:** Select specific access levels for each feature (None, View Only, Limited, Full)
- **Multiple Custom Roles:** Create unlimited custom roles
- **Save as Template:** Save your custom roles as reusable templates for future use
- **Dynamic Updates:** Modify custom role permissions at any time without affecting users

**Template System:**
All 11 predefined roles are available as templates when creating custom roles:

1. **Super Admin Template** - Start with full access, then restrict specific areas
2. **Fleet Manager Template** - Operational management base
3. **Dispatcher Template** - Trip coordination base
4. **Driver Template** - Field operations base
5. **Accountant Template** - Financial management base
6. **Maintenance Manager Template** - Maintenance operations base
7. **Compliance Officer Template** - Regulatory compliance base
8. **Operations Manager Template** - Strategic oversight base
9. **Maintenance Technician Template** - Hands-on work base
10. **Customer Service Template** - Customer interaction base
11. **Viewer/Analyst Template** - Read-only reporting base

**User Workflow:**
1. Navigate to "Custom Roles" in admin dashboard
2. Click "Create New Custom Role"
3. Choose starting point:
   - Select a predefined role template
   - Start from blank (no permissions)
   - Clone an existing custom role
4. Customize permissions as needed
5. Save and assign to users

**Configuration Features:**
- **User Management**
  - None / View Only / Limited / Full

- **Vehicle Management**
  - None / View Only / Add/Edit / Full (including delete)

- **Driver Management**
  - None / View Only / Add/Edit / Full

- **Trip Management**
  - None / View Only / Create / Assign / Full

- **Tracking & Monitoring**
  - None / View Own / View Active / Full Access

- **Financial Operations**
  - None / View Only / Submit Expenses / Approve Expenses / Full Financial Access

- **Maintenance Operations**
  - None / View Only / Schedule / Execute / Full Management

- **Compliance & Documentation**
  - None / View Only / Upload Documents / Full Compliance Management

- **Customer Management**
  - None / View Only / Limited Interaction / Full Management

- **Reporting & Analytics**
  - None / View Own Reports / View All Reports / Generate Custom Reports / Full Analytics

- **System Configuration**
  - None / View Settings / Modify Settings (Super Admin only by default)

**Example Use Cases (Using Templates):**

1. **Regional Manager (West Coast):**
   - **Template Used:** Fleet Manager + partial Operations Manager
   - **Customization:**
     - Start with Fleet Manager template
     - Add emergency trip assignment from Operations Manager
     - Add financial summary view from Accountant
     - Restrict to vehicles/drivers tagged "West Coast"
   - **Result:** Full operational control for west coast fleet with financial oversight

2. **Junior Accountant:**
   - **Template Used:** Accountant (restricted)
   - **Customization:**
     - Start with Accountant template
     - Change "Approve Expenses" from Full to None
     - Change "Manage Invoices" from Full to View Only
     - Keep expense tracking and reporting
   - **Result:** Can track and report expenses but needs senior approval

3. **Safety Inspector:**
   - **Template Used:** Compliance Officer + Viewer/Analyst
   - **Customization:**
     - Start with Compliance Officer template
     - Add report generation from Viewer/Analyst
     - Remove license management permissions
     - Keep full incident and inspection access
   - **Result:** Focused safety and inspection role with reporting capabilities

4. **Contract Driver Supervisor:**
   - **Template Used:** Dispatcher (modified) + Driver (limited)
   - **Customization:**
     - Start with Dispatcher template
     - Limit driver management to "Contract" driver type only
     - Remove financial visibility
     - Add driver performance view from Fleet Manager
   - **Result:** Manages and assigns contract drivers without full fleet access

5. **Night Shift Manager:**
   - **Template Used:** Operations Manager (time-restricted)
   - **Customization:**
     - Start with Operations Manager template
     - Add emergency vehicle assignment capability
     - Add full access to tracking during night hours
     - Limited financial access (view only)
   - **Result:** Full operational control during night shift with appropriate restrictions

6. **Finance Auditor:**
   - **Template Used:** Accountant + Viewer/Analyst + Compliance Officer
   - **Customization:**
     - Start with Accountant template (view only mode)
     - Add compliance document access from Compliance Officer
     - Add advanced analytics from Viewer/Analyst
     - Remove all edit/create/delete permissions
   - **Result:** Complete financial visibility for audit purposes without modification rights

**Benefits:**
- **Template-Based Speed:** Start with a predefined role and customize in minutes instead of building from scratch
- **Flexibility:** Mix permissions from multiple roles to create exactly what you need
- **Security:** Principle of least privilege - start restrictive and add permissions as needed
- **Scalability:** Create unlimited custom roles as your organization grows
- **Consistency:** Use predefined templates to maintain standard permission patterns
- **Compliance:** Meet specific regulatory or audit requirements with tailored access
- **Efficiency:** Reduce administrative overhead with reusable templates
- **User Freedom:** Empower admins to create roles without developer intervention

**Management Interface:**
Custom roles are managed through the admin dashboard with an intuitive template-based builder:

**Template Selection Screen:**
- Browse all 11 predefined role templates with permission previews
- Compare templates side-by-side
- Select single template or merge multiple templates
- "Start from Scratch" option for completely custom builds

**Permission Builder:**
- Visual permission matrix showing all features
- Toggle switches for each permission (None/View/Limited/Full)
- Color-coded indicators showing permission levels
- Template inheritance indicators (shows which permissions came from which template)
- Drag-and-drop permission groups
- Bulk actions (enable/disable entire categories)

**Advanced Features:**
- Real-time permission preview (see exactly what users will access)
- Permission conflict detection and warnings
- Impact analysis (shows how many users will be affected)
- Role comparison tool (compare with other roles/templates)
- Permission search and filter
- Role assignment to multiple users
- Audit trail of all role changes with template tracking
- Version history (rollback to previous configurations)
- Template marketplace (share templates across organizations - future feature)

---

## Capability-Based Permission System

### Overview

The system uses a **capability-based permission model** where each feature has hardcoded capability identifiers. When creating or customizing roles, administrators select specific capabilities to grant users precise access control.

### Architecture

```
Feature (e.g., Vehicle Management)
    ↓
Capabilities (Hardcoded Identifiers)
    ├── vehicle.view
    ├── vehicle.create
    ├── vehicle.edit
    ├── vehicle.delete
    └── vehicle.export
        ↓
User Role Assignment
    ├── Fleet Manager gets: [vehicle.view, vehicle.create, vehicle.edit, vehicle.export]
    ├── Dispatcher gets: [vehicle.view]
    └── Custom Role gets: [vehicle.view, vehicle.edit] (configurable)
```

### Hardcoded Capability Identifiers

All capabilities are predefined in the system with unique identifiers. These cannot be modified but can be assigned to any role.

#### Vehicle Management Capabilities
```python
VEHICLE_CAPABILITIES = {
    "vehicle.view": "View vehicle details and list",
    "vehicle.create": "Add new vehicles to fleet",
    "vehicle.edit": "Modify vehicle information",
    "vehicle.delete": "Remove vehicles from system",
    "vehicle.export": "Export vehicle data",
    "vehicle.import": "Import vehicles from file",
    "vehicle.archive": "Archive/deactivate vehicles",
    "vehicle.assign": "Assign vehicles to drivers",
    "vehicle.documents.view": "View vehicle documents",
    "vehicle.documents.upload": "Upload vehicle documents",
    "vehicle.documents.delete": "Delete vehicle documents"
}
```

#### Driver Management Capabilities
```python
DRIVER_CAPABILITIES = {
    "driver.view": "View driver profiles",
    "driver.view.all": "View all drivers in system",
    "driver.view.own": "View only assigned drivers",
    "driver.create": "Add new drivers",
    "driver.edit": "Modify driver information",
    "driver.delete": "Remove drivers from system",
    "driver.license.view": "View driver license details",
    "driver.license.manage": "Manage license information",
    "driver.performance.view": "View driver performance metrics",
    "driver.assign": "Assign drivers to vehicles/trips"
}
```

#### Trip Management Capabilities
```python
TRIP_CAPABILITIES = {
    "trip.view": "View trip details",
    "trip.view.all": "View all trips",
    "trip.view.own": "View only own assigned trips",
    "trip.create": "Create new trips",
    "trip.edit": "Modify trip details",
    "trip.delete": "Cancel/delete trips",
    "trip.assign": "Assign trips to drivers/vehicles",
    "trip.status.update": "Update trip status",
    "trip.route.view": "View trip routes",
    "trip.route.modify": "Modify trip routes",
    "trip.waypoint.add": "Add waypoints to trip",
    "trip.waypoint.edit": "Edit trip waypoints"
}
```

#### Tracking & Monitoring Capabilities
```python
TRACKING_CAPABILITIES = {
    "tracking.view.all": "View all vehicle locations",
    "tracking.view.active": "View only active trip locations",
    "tracking.view.own": "View only own vehicle location",
    "tracking.history.view": "View historical tracking data",
    "tracking.history.export": "Export tracking history",
    "tracking.geofence.view": "View geofence alerts",
    "tracking.geofence.create": "Create geofence zones",
    "tracking.geofence.edit": "Modify geofence zones",
    "tracking.alerts.manage": "Manage tracking alerts"
}
```

#### Financial Management Capabilities
```python
FINANCIAL_CAPABILITIES = {
    "finance.view": "View financial data",
    "finance.dashboard": "Access financial dashboard",
    "expense.view": "View expenses",
    "expense.create": "Submit new expenses",
    "expense.edit": "Edit expense details",
    "expense.delete": "Delete expenses",
    "expense.approve": "Approve expense claims",
    "expense.reject": "Reject expense claims",
    "invoice.view": "View invoices",
    "invoice.create": "Create new invoices",
    "invoice.edit": "Edit invoice details",
    "invoice.send": "Send invoices to customers",
    "invoice.delete": "Delete invoices",
    "payment.view": "View payment records",
    "payment.record": "Record payments",
    "budget.view": "View budget information",
    "budget.manage": "Manage budget allocations",
    "finance.export": "Export financial reports"
}
```

#### Maintenance Management Capabilities
```python
MAINTENANCE_CAPABILITIES = {
    "maintenance.view": "View maintenance records",
    "maintenance.schedule.view": "View maintenance schedules",
    "maintenance.schedule.create": "Create maintenance schedules",
    "maintenance.schedule.edit": "Edit maintenance schedules",
    "maintenance.record.create": "Log maintenance activity",
    "maintenance.workorder.view": "View work orders",
    "maintenance.workorder.create": "Create work orders",
    "maintenance.workorder.assign": "Assign work orders",
    "maintenance.workorder.update": "Update work order status",
    "maintenance.workorder.complete": "Complete work orders",
    "maintenance.inspection.perform": "Perform vehicle inspections",
    "maintenance.inspection.view": "View inspection records",
    "parts.view": "View parts inventory",
    "parts.request": "Request parts",
    "parts.manage": "Manage parts inventory",
    "parts.order": "Order new parts",
    "vendor.view": "View vendor information",
    "vendor.manage": "Manage vendor relationships"
}
```

#### Compliance & Safety Capabilities
```python
COMPLIANCE_CAPABILITIES = {
    "compliance.view": "View compliance information",
    "compliance.license.view": "View licenses",
    "compliance.license.manage": "Manage licenses and renewals",
    "compliance.document.view": "View compliance documents",
    "compliance.document.upload": "Upload compliance documents",
    "compliance.document.manage": "Manage compliance documents",
    "compliance.inspection.view": "View inspection records",
    "compliance.inspection.schedule": "Schedule inspections",
    "compliance.inspection.perform": "Perform inspections",
    "compliance.incident.view": "View incident reports",
    "compliance.incident.create": "Report incidents",
    "compliance.incident.manage": "Manage incident reports",
    "compliance.certification.view": "View certifications",
    "compliance.certification.manage": "Manage certifications",
    "compliance.hos.view": "View Hours of Service logs",
    "compliance.hos.manage": "Manage HOS compliance",
    "compliance.alerts.view": "View compliance alerts"
}
```

#### Customer Management Capabilities
```python
CUSTOMER_CAPABILITIES = {
    "customer.view": "View customer information",
    "customer.create": "Add new customers",
    "customer.edit": "Edit customer details",
    "customer.delete": "Delete customers",
    "customer.contact.manage": "Manage customer contacts",
    "support.ticket.view": "View support tickets",
    "support.ticket.create": "Create support tickets",
    "support.ticket.assign": "Assign tickets to agents",
    "support.ticket.update": "Update ticket status",
    "support.ticket.close": "Close support tickets",
    "notification.send": "Send notifications to customers",
    "communication.log.view": "View communication history"
}
```

#### Reporting & Analytics Capabilities
```python
REPORTING_CAPABILITIES = {
    "reports.view": "View reports",
    "reports.fleet.view": "View fleet performance reports",
    "reports.driver.view": "View driver performance reports",
    "reports.financial.view": "View financial reports",
    "reports.maintenance.view": "View maintenance reports",
    "reports.compliance.view": "View compliance reports",
    "reports.custom.create": "Create custom reports",
    "reports.export": "Export reports",
    "reports.schedule": "Schedule automated reports",
    "analytics.dashboard.view": "View analytics dashboards",
    "analytics.dashboard.customize": "Customize dashboards",
    "analytics.kpi.view": "View KPIs"
}
```

#### User Management Capabilities
```python
USER_MANAGEMENT_CAPABILITIES = {
    "user.view": "View user list and details",
    "user.create": "Create new users",
    "user.edit": "Edit user information",
    "user.delete": "Delete users",
    "user.role.assign": "Assign roles to users",
    "user.role.revoke": "Revoke user roles",
    "user.password.reset": "Reset user passwords",
    "user.activate": "Activate user accounts",
    "user.deactivate": "Deactivate user accounts",
    "user.activity.view": "View user activity logs"
}
```

#### Role Management Capabilities
```python
ROLE_MANAGEMENT_CAPABILITIES = {
    "role.view": "View roles",
    "role.predefined.view": "View predefined roles",
    "role.custom.view": "View custom roles",
    "role.custom.create": "Create custom roles",
    "role.custom.edit": "Edit custom roles",
    "role.custom.delete": "Delete custom roles",
    "role.template.view": "View role templates",
    "role.template.use": "Use templates to create roles",
    "role.capability.assign": "Assign capabilities to roles",
    "role.capability.revoke": "Revoke capabilities from roles"
}
```

#### System Settings Capabilities
```python
SYSTEM_CAPABILITIES = {
    "system.settings.view": "View system settings",
    "system.settings.edit": "Modify system settings",
    "system.config.view": "View system configuration",
    "system.config.edit": "Modify system configuration",
    "system.audit.view": "View audit logs",
    "system.backup.create": "Create system backups",
    "system.backup.restore": "Restore from backup",
    "system.integration.manage": "Manage API integrations"
}
```

### How Capabilities Work in Roles

#### Predefined Role Capability Mapping

**Example: Fleet Manager Role**
```python
FLEET_MANAGER_CAPABILITIES = [
    # Vehicle Management
    "vehicle.view", "vehicle.create", "vehicle.edit", "vehicle.export",
    "vehicle.assign", "vehicle.documents.view", "vehicle.documents.upload",

    # Driver Management
    "driver.view.all", "driver.create", "driver.edit", "driver.assign",
    "driver.license.view", "driver.performance.view",

    # Trip Management
    "trip.view.all", "trip.create", "trip.edit", "trip.assign",
    "trip.status.update", "trip.route.view", "trip.route.modify",

    # Tracking
    "tracking.view.all", "tracking.history.view", "tracking.history.export",

    # Maintenance
    "maintenance.view", "maintenance.schedule.view",
    "maintenance.schedule.create", "maintenance.schedule.edit",

    # Reports
    "reports.view", "reports.fleet.view", "reports.driver.view",
    "reports.maintenance.view", "reports.export"
]
```

**Example: Driver Role**
```python
DRIVER_CAPABILITIES = [
    # Limited Vehicle View
    "vehicle.view",  # Only assigned vehicle

    # Self Management
    "driver.view.own", "driver.license.view",  # Own license only

    # Trip Management
    "trip.view.own", "trip.status.update",  # Only assigned trips

    # Tracking
    "tracking.view.own",  # Share own location

    # Maintenance
    "maintenance.workorder.view",  # View assigned work
    "maintenance.inspection.view",  # View inspections for assigned vehicle

    # Reports
    "reports.view"  # Own trip reports only
]
```

### Custom Role Capability Assignment

When creating a custom role, administrators select from all available capabilities:

```python
# Example: Create custom "Regional Manager - West" role
CUSTOM_REGIONAL_MANAGER_CAPABILITIES = [
    # From Fleet Manager Template
    "vehicle.view", "vehicle.create", "vehicle.edit",  # No delete
    "driver.view.all", "driver.create", "driver.edit",
    "trip.view.all", "trip.create", "trip.assign",

    # From Accountant Template
    "finance.view", "expense.view",  # View only, no approval

    # From Operations Manager Template
    "analytics.dashboard.view", "analytics.kpi.view",

    # Custom additions
    "reports.custom.create",  # Custom reporting capability

    # With additional constraints
    {
        "capabilities": ["vehicle.view", "vehicle.edit"],
        "constraints": {"region": "west_coast"}  # Regional restriction
    }
]
```

### Database Schema for Capabilities

```sql
-- Capabilities table (hardcoded definitions)
CREATE TABLE capabilities (
    id UUID PRIMARY KEY,
    capability_key VARCHAR(100) UNIQUE NOT NULL,  -- e.g., "vehicle.view"
    feature_category VARCHAR(50) NOT NULL,         -- e.g., "vehicle_management"
    capability_name VARCHAR(100) NOT NULL,         -- e.g., "View Vehicles"
    description TEXT,
    access_levels JSON,                             -- ["none", "view", "full"]
    is_system_critical BOOLEAN DEFAULT FALSE,      -- Reserved for Super Admin
    created_at TIMESTAMP DEFAULT NOW()
);

-- Role capabilities mapping
CREATE TABLE role_capabilities (
    id UUID PRIMARY KEY,
    role_id UUID REFERENCES roles(id),
    capability_key VARCHAR(100) REFERENCES capabilities(capability_key),
    access_level VARCHAR(20),                      -- "none", "view", "limited", "full"
    constraints JSON,                               -- Additional constraints (region, time, etc.)
    granted_at TIMESTAMP DEFAULT NOW(),
    granted_by UUID REFERENCES users(id)
);

-- User effective capabilities (computed view)
CREATE VIEW user_effective_capabilities AS
SELECT
    u.id as user_id,
    c.capability_key,
    rc.access_level,
    rc.constraints
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN role_capabilities rc ON ur.role_id = rc.role_id
JOIN capabilities c ON rc.capability_key = c.capability_key;
```

### API Endpoints for Capabilities

```python
# Get all available capabilities
GET /api/capabilities

# Get capabilities by category
GET /api/capabilities/category/{category}

# Get role's capabilities
GET /api/roles/{role_id}/capabilities

# Assign capability to custom role
POST /api/custom-roles/{role_id}/capabilities
{
    "capability_key": "vehicle.view",
    "access_level": "full",
    "constraints": {"region": "west_coast"}
}

# Remove capability from custom role
DELETE /api/custom-roles/{role_id}/capabilities/{capability_key}

# Get user's effective capabilities
GET /api/users/{user_id}/capabilities

# Check if user has specific capability
GET /api/users/{user_id}/capabilities/{capability_key}/check
```

### Capability-Based Permission Check

```python
from fastapi import Depends, HTTPException

def require_capability(capability_key: str, access_level: str = "view"):
    """
    Dependency to check if user has specific capability.
    """
    async def check_capability(
        current_user = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        # Get user's effective capabilities
        user_capabilities = get_user_capabilities(current_user.id, db)

        # Check if user has the required capability
        user_cap = user_capabilities.get(capability_key)

        if not user_cap:
            raise HTTPException(
                status_code=403,
                detail=f"Missing capability: {capability_key}"
            )

        # Check access level
        if not has_sufficient_access(user_cap.access_level, access_level):
            raise HTTPException(
                status_code=403,
                detail=f"Insufficient access level for: {capability_key}"
            )

        return current_user

    return check_capability


# Usage in endpoint
@router.post("/vehicles")
async def create_vehicle(
    vehicle: VehicleCreate,
    db: Session = Depends(get_db),
    current_user = Depends(require_capability("vehicle.create", "full"))
):
    """
    Create vehicle endpoint.
    Requires: vehicle.create capability with full access.
    """
    # Create vehicle logic
    pass
```

### Benefits of Capability-Based System

1. **Granular Control:** Each action has a specific capability identifier
2. **Flexibility:** Mix any combination of capabilities in custom roles
3. **Clarity:** Clear, hardcoded identifiers that are easy to understand (e.g., `vehicle.create`)
4. **Maintainability:** Capabilities are defined in code, roles are configured in database
5. **Auditability:** Track exactly which capabilities are granted to which roles
6. **Scalability:** Easy to add new capabilities without changing role structure
7. **Template-Friendly:** Predefined roles are just collections of capabilities
8. **Custom Constraints:** Add additional rules (region, time, etc.) to capabilities
9. **Type Safety:** Hardcoded identifiers prevent typos and ensure consistency
10. **Developer-Friendly:** Clear naming convention makes API development easier

### Complete System Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    HARDCODED CAPABILITIES                    │
│  (Defined in Code - Cannot be Modified by Users)            │
├─────────────────────────────────────────────────────────────┤
│  vehicle.view │ vehicle.create │ vehicle.edit │ vehicle.delete│
│  driver.view.all │ driver.create │ trip.create │ etc...      │
└────────────┬────────────────────────────────────────────────┘
             │
             │ GROUPED INTO
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    11 PREDEFINED ROLES                       │
│         (Templates - Collections of Capabilities)            │
├─────────────────────────────────────────────────────────────┤
│  Fleet Manager = [vehicle.view, vehicle.create, ...]        │
│  Dispatcher = [trip.create, trip.assign, ...]               │
│  Driver = [trip.view.own, tracking.view.own, ...]           │
└────────────┬────────────────────────────────────────────────┘
             │
             │ USED AS TEMPLATES
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    CUSTOM ROLES                              │
│     (User-Created - Select Capabilities from Templates)     │
├─────────────────────────────────────────────────────────────┤
│  Regional Manager = Fleet Manager capabilities +             │
│                     Some Accountant capabilities +           │
│                     Custom constraints (region filter)       │
└────────────┬────────────────────────────────────────────────┘
             │
             │ ASSIGNED TO
             ▼
┌─────────────────────────────────────────────────────────────┐
│                         USERS                                │
│              (Get Effective Capabilities)                    │
├─────────────────────────────────────────────────────────────┤
│  User X → Regional Manager Role →                           │
│           [vehicle.view, vehicle.create, driver.view.all,    │
│            trip.create, finance.view] with region=west       │
└─────────────────────────────────────────────────────────────┘
```

### Summary: Capabilities + Templates = Maximum Flexibility

**The System Combines Two Powerful Concepts:**

1. **Capability-Based Permissions (Hardcoded)**
   - 100+ granular capability identifiers
   - Defined in code, cannot be changed by users
   - Each represents a specific action (e.g., `vehicle.create`)
   - Used by all roles (predefined and custom)

2. **Template-Based Role Creation (Configurable)**
   - 11 predefined roles serve as ready-to-use templates
   - Each template is a curated collection of capabilities
   - Users can select any template and customize it
   - Mix capabilities from multiple templates
   - Save custom roles as reusable templates

**Result:**
- **For Developers:** Clear, maintainable, type-safe capability system
- **For Administrators:** Easy-to-use template system that doesn't require coding
- **For Users:** Precise access control tailored to their needs
- **For Organizations:** Maximum flexibility without sacrificing security

**Example Workflow:**
1. Developer defines: `"vehicle.create": "Add new vehicles to fleet"` (hardcoded)
2. System groups capabilities into Fleet Manager template (predefined)
3. Admin selects Fleet Manager template (uses predefined capabilities)
4. Admin removes `vehicle.delete` capability (customizes)
5. Admin adds `finance.view` from Accountant template (mixes templates)
6. Admin saves as "Regional Manager" template (reusable)
7. Admin assigns to users (they get exact capabilities needed)
8. System checks `vehicle.create` capability on API calls (enforces)

---

## Template-Based Custom Role System Workflow

### How Templates Work

```
┌─────────────────────────────────────────────────────────────────┐
│                    11 PREDEFINED ROLE TEMPLATES                  │
├─────────────────────────────────────────────────────────────────┤
│  Super Admin  │  Fleet Manager  │  Dispatcher  │  Driver        │
│  Accountant   │  Maintenance M. │  Compliance  │  Operations M. │
│  Technician   │  Customer Svc   │  Viewer      │                │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ SELECT ONE OR MORE TEMPLATES
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TEMPLATE SELECTION                            │
├─────────────────────────────────────────────────────────────────┤
│  ☑ Fleet Manager (base operations)                              │
│  ☑ Accountant (financial view only)                             │
│  ☐ Operations Manager                                           │
│                                                                  │
│  Merge Strategy:  ⦿ Union  ○ Intersection                       │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ AUTOMATIC PERMISSION MERGE
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MERGED PERMISSIONS                            │
├─────────────────────────────────────────────────────────────────┤
│  Vehicle Management:        Full (from Fleet Manager)           │
│  Driver Management:         Full (from Fleet Manager)           │
│  Trip Management:           Full (from Fleet Manager)           │
│  Financial View:            View Only (from Accountant)         │
│  Expense Tracking:          View Only (from Accountant)         │
│  ...                                                             │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ CUSTOMIZE AS NEEDED
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMIZATION LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  Vehicle Management:        Full → Limited (West Coast only)    │
│  Driver Management:         Full (keep from template)           │
│  Trip Management:           Full (keep from template)           │
│  Financial View:            View Only → View (summary only)     │
│  Expense Tracking:          View Only → None (remove)           │
│  Reports:                   Add Custom Reports access            │
└────────────┬────────────────────────────────────────────────────┘
             │
             │ SAVE AS NEW TEMPLATE (OPTIONAL)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│              CUSTOM ROLE: "Regional Manager - West"              │
├─────────────────────────────────────────────────────────────────┤
│  Template Sources: Fleet Manager + Accountant (partial)         │
│  Custom Restrictions: West Coast region only                    │
│  Custom Additions: Custom reports access                        │
│                                                                  │
│  Can be saved as reusable template for other regions            │
└─────────────────────────────────────────────────────────────────┘
```

### Template Creation Examples

**Example 1: Simple Template Usage**
```
Start: Dispatcher Template
↓
Customize: Remove vehicle management
↓
Result: Trip Coordinator (assign trips only)
```

**Example 2: Multi-Template Merge**
```
Templates: Fleet Manager + Compliance Officer
↓
Merge Strategy: Union (all permissions)
↓
Customize: Remove vehicle delete, add custom reports
↓
Result: Operations & Safety Manager
```

**Example 3: Restrictive Template**
```
Start: Accountant Template
↓
Customize: Set all to "View Only" mode
↓
Result: Junior Accountant / Financial Auditor
```

**Example 4: Building from Scratch**
```
Start: Blank (no template)
↓
Add: Vehicle view, Trip view, Real-time tracking
↓
Result: Monitoring Dashboard User
```

---

## Permission Matrix

| Feature | Super Admin | Fleet Manager | Dispatcher | Driver | Accountant | Maintenance Manager | Compliance Officer | Operations Manager | Technician | Customer Service | Viewer | Custom Role |
|---------|-------------|---------------|------------|--------|------------|-------------------|-------------------|-------------------|-----------|-----------------|--------|-------------|
| **User Management** | Full | Limited | None | None | None | None | None | Limited | None | None | None | Configurable |
| **Add/Edit Vehicles** | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | Limited | ✗ | ✗ | ✗ | Configurable |
| **View Vehicles** | ✓ | ✓ | ✓ | Limited | ✓ | ✓ | ✓ | ✓ | Limited | ✓ | ✓ | Configurable |
| **Delete Vehicles** | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | Configurable |
| **Add/Edit Drivers** | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | Configurable |
| **View Driver Details** | ✓ | ✓ | Limited | Own Only | Limited | Limited | ✓ | ✓ | ✗ | Limited | ✓ | Configurable |
| **Create Trips** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | Configurable |
| **Assign Trips** | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | Emergency | ✗ | ✗ | ✗ | Configurable |
| **Update Trip Status** | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | View Only | ✗ | Configurable |
| **Real-time Tracking** | Full | Full | Active Only | Own Only | View Only | View Only | View Only | Full | ✗ | Customer Trips | Full | Configurable |
| **Historical Data** | ✓ | ✓ | Limited | Own Only | ✓ | ✓ | ✓ | ✓ | Limited | Limited | ✓ | Configurable |
| **Financial Management** | ✓ | View Only | ✗ | ✗ | Full | View Only | ✗ | Summary | ✗ | ✗ | View Only | Configurable |
| **Billing & Invoicing** | ✓ | View Only | ✗ | ✗ | Full | ✗ | ✗ | View Only | ✗ | ✗ | ✗ | Configurable |
| **Expense Tracking** | ✓ | Submit | ✗ | Submit | Full | Submit | ✗ | Approve | Submit | ✗ | View Only | Configurable |
| **Maintenance Scheduling** | ✓ | ✓ | ✗ | ✗ | ✗ | Full | View Only | Approve | View Only | ✗ | View Only | Configurable |
| **Maintenance Execution** | ✓ | View Only | ✗ | Report Issues | ✗ | Assign/Monitor | ✗ | View Only | Full | ✗ | View Only | Configurable |
| **Parts Inventory** | ✓ | View Only | ✗ | ✗ | View Costs | Full | ✗ | View Only | Request/Update | ✗ | View Only | Configurable |
| **License Management** | ✓ | View Only | ✗ | View Own | ✗ | View Only | Full | View Only | ✗ | ✗ | View Only | Configurable |
| **Compliance Tracking** | ✓ | View Only | ✗ | View Own | ✗ | Limited | Full | View Only | ✗ | ✗ | View Only | Configurable |
| **Document Management** | ✓ | Upload | ✗ | Upload Own | Upload | Upload | Full | View All | Upload | Upload | View Only | Configurable |
| **Customer Management** | ✓ | Limited | ✗ | ✗ | View Only | ✗ | ✗ | View Only | ✗ | Full | View Only | Configurable |
| **Support Tickets** | ✓ | View Only | ✗ | Create | ✗ | Create | ✗ | View Only | Create | Full | ✗ | Configurable |
| **System Settings** | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | Configurable* |
| **Reports & Analytics** | Full | Full | Limited | Own Only | Financial | Maintenance | Compliance | Full | Own Work | Customer Service | Full | Configurable |
| **Audit Logs** | ✓ | ✗ | ✗ | ✗ | Financial Only | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ | Configurable |

**Note:** *System Settings modification typically restricted to Super Admin only, even in custom roles.

---

## Role Hierarchy & Summary

### Administrative Roles
1. **Super Admin** - Complete system control, all permissions
2. **Operations Manager** - Strategic oversight, emergency overrides, cross-functional visibility

### Operational Roles
3. **Fleet Manager** - Day-to-day fleet operations, vehicle and driver management
4. **Dispatcher** - Trip coordination, real-time assignment and monitoring
5. **Driver** - Field operations, trip execution

### Specialized Roles
6. **Accountant/Finance Manager** - Financial management, billing, budgets
7. **Maintenance Manager** - Vehicle maintenance, repairs, parts inventory
8. **Compliance Officer** - Regulatory compliance, licenses, documentation
9. **Maintenance Technician** - Hands-on maintenance and repairs

### Support Roles
10. **Customer Service Representative** - Customer interaction, support tickets
11. **Viewer/Analyst** - Read-only access, reporting and analytics

### Flexible Roles
12. **Custom Role** - Configurable permissions based on specific organizational needs

### Quick Feature Access Guide

**Want to...**
- **Manage finances?** → Accountant role
- **Handle maintenance?** → Maintenance Manager or Technician role
- **Ensure compliance?** → Compliance Officer role
- **Coordinate trips?** → Dispatcher role
- **Oversee operations?** → Operations Manager or Fleet Manager role
- **Help customers?** → Customer Service role
- **View analytics?** → Viewer/Analyst role
- **Drive vehicles?** → Driver role
- **Need unique permissions?** → Custom Role (configure exactly what you need)

---

## Technology Stack

### Frontend
- **Framework:** Flutter
- **State Management:** [Provider/Riverpod/Bloc - to be specified]
- **Maps:** Google Maps / OpenStreetMap
- **Real-time:** WebSocket / Firebase

### Backend
- **API Framework:** FastAPI (Python)
- **Database:** PostgreSQL
- **ORM:** SQLAlchemy / Tortoise ORM
- **Authentication:** JWT (JSON Web Tokens)
- **Authorization:** OAuth 2.0 with Password Flow
- **Real-time Communication:** WebSocket (FastAPI WebSocket support)
- **API Documentation:** Automatic with Swagger UI / ReDoc (built-in FastAPI)
- **Validation:** Pydantic models
- **Migration:** Alembic

---

## Database Schema Overview

### Key Tables

#### Authentication & Authorization
1. **users** - Store user accounts and authentication
2. **roles** - Define system roles (predefined + custom)
3. **capabilities** - Hardcoded capability identifiers and definitions
4. **role_capabilities** - Map capabilities to roles with access levels and constraints
5. **user_roles** - Assign roles to users
6. **custom_roles** - Store custom role configurations
7. **role_templates** - Store reusable custom role templates
8. **template_sources** - Track which predefined templates were used to create custom roles
9. **capability_categories** - Group capabilities by feature area
10. **user_effective_capabilities** - Computed view of user's actual capabilities
11. **audit_logs** - Track all system activities including role and capability changes

#### Fleet Management
12. **organizations** - Multi-tenant organization data (if applicable)
13. **vehicles** - Vehicle information and status
14. **vehicle_documents** - Registration, insurance, permits
15. **drivers** - Driver profiles and licenses
16. **driver_licenses** - License details and expiration
17. **trips** - Trip details and assignments
18. **trip_waypoints** - Delivery/pickup locations
19. **tracking_data** - GPS location history and real-time data

#### Financial Management
20. **expenses** - All fleet expenses (fuel, tolls, maintenance, etc.)
21. **expense_categories** - Categorization of expenses
22. **invoices** - Customer invoices
23. **payments** - Payment tracking
24. **budgets** - Budget allocations and monitoring
25. **reimbursements** - Driver reimbursement requests
26. **vendor_payments** - Payments to vendors and service providers

#### Maintenance Management
27. **maintenance_schedules** - Preventive maintenance plans
28. **maintenance_records** - Historical maintenance data
29. **work_orders** - Maintenance and repair tasks
30. **vehicle_inspections** - Inspection records
31. **parts_inventory** - Spare parts stock
32. **parts_usage** - Parts used in repairs
33. **vendors** - Service providers and workshops
34. **warranties** - Vehicle and parts warranty information

#### Compliance & Safety
35. **compliance_documents** - Legal and regulatory documents
36. **certifications** - Driver training and certifications
37. **insurance_policies** - Insurance policy details
38. **incidents** - Accident and incident reports
39. **safety_inspections** - Safety inspection records
40. **hos_logs** - Hours of Service compliance logs
41. **violations** - Traffic and safety violations

#### Customer Management
42. **customers** - Customer information
43. **customer_contacts** - Customer contact details
44. **support_tickets** - Customer support requests
45. **notifications** - System notifications and alerts
46. **communication_logs** - Customer communication history

#### Reporting & Analytics
47. **performance_metrics** - KPI and performance data
48. **reports** - Saved report configurations
49. **alerts** - System alerts and geofencing
50. **schedules** - Work schedules and shifts

---

## Getting Started

### Prerequisites

#### Backend Requirements
- Python (>= 3.10)
- PostgreSQL (>= 14.0)
- pip (Python package manager)
- virtualenv or venv (recommended)

#### Frontend Requirements
- Flutter SDK (>= 3.0.0)
- Dart (>= 3.0.0)
- Android Studio / Xcode (for mobile development)

### Installation

#### Backend Setup (FastAPI)
```bash
# Clone the repository
git clone [repository-url]
cd RR4

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install backend dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials and configuration

# Run database migrations
alembic upgrade head

# Start FastAPI development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# API Documentation will be available at:
# http://localhost:8000/docs (Swagger UI)
# http://localhost:8000/redoc (ReDoc)
```

#### Frontend Setup (Flutter)
```bash
# Navigate to Flutter project directory
cd flutter_app

# Install Flutter dependencies
flutter pub get

# Run the application
flutter run

# Or for specific platform:
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS
```

#### Key Backend Dependencies (requirements.txt)
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
alembic>=1.12.0
pydantic>=2.5.0
pydantic-settings>=2.1.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6
websockets>=12.0
redis>=5.0.0
celery>=5.3.0
python-dotenv>=1.0.0
```

---

## Project Structure

```
RR4/
├── backend/                      # FastAPI Backend
│   ├── app/
│   │   ├── main.py              # FastAPI application entry point
│   │   ├── config.py            # Configuration and environment variables
│   │   ├── database.py          # Database connection and session
│   │   ├── dependencies.py      # Dependency injection functions
│   │   │
│   │   ├── models/              # SQLAlchemy models
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── vehicle.py
│   │   │   ├── driver.py
│   │   │   ├── trip.py
│   │   │   ├── expense.py
│   │   │   └── ...
│   │   │
│   │   ├── schemas/             # Pydantic schemas (request/response)
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── vehicle.py
│   │   │   ├── driver.py
│   │   │   └── ...
│   │   │
│   │   ├── api/                 # API routes
│   │   │   ├── __init__.py
│   │   │   ├── deps.py          # Route dependencies
│   │   │   ├── v1/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py
│   │   │   │   ├── users.py
│   │   │   │   ├── vehicles.py
│   │   │   │   ├── drivers.py
│   │   │   │   ├── trips.py
│   │   │   │   ├── tracking.py
│   │   │   │   ├── financial.py
│   │   │   │   ├── maintenance.py
│   │   │   │   ├── compliance.py
│   │   │   │   └── ...
│   │   │
│   │   ├── services/            # Business logic layer
│   │   │   ├── __init__.py
│   │   │   ├── auth_service.py
│   │   │   ├── vehicle_service.py
│   │   │   ├── tracking_service.py
│   │   │   └── ...
│   │   │
│   │   ├── core/                # Core functionality
│   │   │   ├── __init__.py
│   │   │   ├── security.py      # Password hashing, JWT
│   │   │   ├── permissions.py   # Role-based access control
│   │   │   └── config.py
│   │   │
│   │   └── utils/               # Utility functions
│   │       ├── __init__.py
│   │       ├── email.py
│   │       ├── notifications.py
│   │       └── helpers.py
│   │
│   ├── alembic/                 # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   │
│   ├── tests/                   # Backend tests
│   │   ├── __init__.py
│   │   ├── test_auth.py
│   │   ├── test_vehicles.py
│   │   └── ...
│   │
│   ├── requirements.txt         # Python dependencies
│   ├── .env.example            # Environment variables template
│   ├── alembic.ini             # Alembic configuration
│   └── README.md
│
├── flutter_app/                 # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/             # Data models
│   │   ├── screens/            # UI screens
│   │   ├── widgets/            # Reusable widgets
│   │   ├── services/           # API services
│   │   ├── providers/          # State management
│   │   └── utils/              # Utility functions
│   │
│   ├── assets/                 # Images, fonts, etc.
│   ├── test/                   # Flutter tests
│   ├── pubspec.yaml           # Flutter dependencies
│   └── README.md
│
├── docs/                       # Documentation
│   ├── api/                   # API documentation
│   ├── deployment/            # Deployment guides
│   └── architecture/          # Architecture diagrams
│
├── .gitignore
└── README.md                  # Main project README
```

---

## API Endpoints

### Authentication
- POST `/api/auth/login` - User login
- POST `/api/auth/logout` - User logout
- POST `/api/auth/refresh` - Refresh token
- POST `/api/auth/forgot-password` - Request password reset
- POST `/api/auth/reset-password` - Reset password

### User Management
- GET `/api/users` - List all users
- POST `/api/users` - Create new user
- GET `/api/users/:id` - Get user details
- PUT `/api/users/:id` - Update user
- DELETE `/api/users/:id` - Delete user
- PUT `/api/users/:id/role` - Assign role to user

### Role Management
- GET `/api/roles` - List all roles (predefined + custom)
- GET `/api/roles/:id` - Get role details with permissions
- GET `/api/roles/predefined` - List predefined system roles

### Custom Role Management
- GET `/api/custom-roles` - List all custom roles
- POST `/api/custom-roles` - Create new custom role
- POST `/api/custom-roles/from-template` - Create custom role from template(s)
- GET `/api/custom-roles/:id` - Get custom role details
- PUT `/api/custom-roles/:id` - Update custom role
- DELETE `/api/custom-roles/:id` - Delete custom role
- GET `/api/custom-roles/:id/capabilities` - Get custom role capabilities
- POST `/api/custom-roles/:id/capabilities` - Assign capability to custom role
- PUT `/api/custom-roles/:id/capabilities/{capability_key}` - Update capability access level
- DELETE `/api/custom-roles/:id/capabilities/{capability_key}` - Remove capability from custom role
- POST `/api/custom-roles/:id/capabilities/bulk` - Assign multiple capabilities at once
- POST `/api/custom-roles/:id/clone` - Clone existing custom role
- GET `/api/custom-roles/:id/impact-analysis` - Analyze impact of role changes on users

### Template Management
- GET `/api/templates/predefined` - Get all 11 predefined role templates with permissions
- GET `/api/templates/predefined/:roleType` - Get specific predefined role template
- POST `/api/templates/merge` - Merge multiple templates into one custom role
- GET `/api/templates/custom` - Get saved custom role templates
- POST `/api/templates/custom` - Save custom role as reusable template
- GET `/api/templates/custom/:id` - Get custom template details
- PUT `/api/templates/custom/:id` - Update custom template
- DELETE `/api/templates/custom/:id` - Delete custom template
- POST `/api/templates/compare` - Compare multiple templates side-by-side
- GET `/api/templates/popular` - Get most commonly used templates

### Capability Management
- GET `/api/capabilities` - List all available capabilities
- GET `/api/capabilities/categories` - Get capabilities grouped by feature category
- GET `/api/capabilities/category/{category}` - Get capabilities for specific category
- GET `/api/capabilities/{capability_key}` - Get capability details
- GET `/api/capabilities/user/{userId}` - Get user's effective capabilities
- GET `/api/capabilities/user/{userId}/check/{capability_key}` - Check if user has specific capability
- GET `/api/capabilities/search` - Search capabilities by keyword

### Vehicles
- GET `/api/vehicles` - List all vehicles
- POST `/api/vehicles` - Add new vehicle
- GET `/api/vehicles/:id` - Get vehicle details
- PUT `/api/vehicles/:id` - Update vehicle
- DELETE `/api/vehicles/:id` - Delete vehicle
- GET `/api/vehicles/:id/documents` - Get vehicle documents
- POST `/api/vehicles/:id/documents` - Upload vehicle document

### Drivers
- GET `/api/drivers` - List all drivers
- POST `/api/drivers` - Add new driver
- GET `/api/drivers/:id` - Get driver details
- PUT `/api/drivers/:id` - Update driver
- DELETE `/api/drivers/:id` - Delete driver
- GET `/api/drivers/:id/performance` - Get driver performance metrics

### Trips
- GET `/api/trips` - List all trips
- POST `/api/trips` - Create new trip
- GET `/api/trips/:id` - Get trip details
- PUT `/api/trips/:id` - Update trip
- DELETE `/api/trips/:id` - Cancel trip
- PUT `/api/trips/:id/status` - Update trip status
- POST `/api/trips/:id/assign` - Assign driver and vehicle

### Tracking
- GET `/api/tracking/:vehicleId` - Get live location
- GET `/api/tracking/history/:vehicleId` - Get historical tracking data
- POST `/api/tracking/geofence` - Create geofence alert
- GET `/api/tracking/alerts` - Get tracking alerts

### Financial Management
- GET `/api/expenses` - List all expenses
- POST `/api/expenses` - Add new expense
- PUT `/api/expenses/:id` - Update expense
- PUT `/api/expenses/:id/approve` - Approve expense
- GET `/api/invoices` - List all invoices
- POST `/api/invoices` - Create invoice
- GET `/api/invoices/:id` - Get invoice details
- PUT `/api/invoices/:id/send` - Send invoice to customer
- GET `/api/payments` - List payments
- POST `/api/payments` - Record payment
- GET `/api/reports/financial` - Generate financial reports
- GET `/api/budgets` - Get budget information

### Maintenance Management
- GET `/api/maintenance/schedules` - Get maintenance schedules
- POST `/api/maintenance/schedules` - Create maintenance schedule
- GET `/api/maintenance/records` - Get maintenance history
- POST `/api/maintenance/records` - Log maintenance activity
- GET `/api/work-orders` - List work orders
- POST `/api/work-orders` - Create work order
- PUT `/api/work-orders/:id/status` - Update work order status
- GET `/api/parts` - List parts inventory
- PUT `/api/parts/:id/stock` - Update parts stock
- GET `/api/vendors` - List service vendors

### Compliance Management
- GET `/api/compliance/licenses` - Get all licenses
- POST `/api/compliance/licenses` - Add license
- PUT `/api/compliance/licenses/:id` - Update license
- GET `/api/compliance/documents` - Get compliance documents
- POST `/api/compliance/documents` - Upload compliance document
- GET `/api/compliance/inspections` - Get inspection records
- POST `/api/compliance/inspections` - Log inspection
- GET `/api/compliance/incidents` - Get incident reports
- POST `/api/compliance/incidents` - Report incident
- GET `/api/compliance/alerts` - Get expiration alerts

### Customer Management
- GET `/api/customers` - List all customers
- POST `/api/customers` - Add new customer
- GET `/api/customers/:id` - Get customer details
- PUT `/api/customers/:id` - Update customer
- GET `/api/support-tickets` - List support tickets
- POST `/api/support-tickets` - Create support ticket
- PUT `/api/support-tickets/:id` - Update ticket status
- POST `/api/notifications` - Send notification

### Reports & Analytics
- GET `/api/reports/fleet-performance` - Fleet performance report
- GET `/api/reports/driver-performance` - Driver performance report
- GET `/api/reports/fuel-consumption` - Fuel consumption report
- GET `/api/reports/maintenance` - Maintenance report
- GET `/api/reports/compliance` - Compliance report
- GET `/api/reports/financial` - Financial report
- GET `/api/analytics/dashboard` - Dashboard analytics
- GET `/api/analytics/kpis` - Key performance indicators

---

## FastAPI Features & Benefits

### Why FastAPI?
1. **High Performance:** Comparable to NodeJS and Go
2. **Fast Development:** Reduces development time by 40%
3. **Automatic Documentation:** Interactive API docs (Swagger UI, ReDoc)
4. **Type Safety:** Python type hints with Pydantic validation
5. **Async Support:** Built-in async/await for WebSocket and real-time features
6. **Easy Testing:** Built-in test client
7. **Modern Standards:** Based on OpenAPI and JSON Schema

### Key Features Used
- **Dependency Injection:** Clean architecture with reusable dependencies
- **Background Tasks:** For email notifications and async operations
- **WebSocket Support:** Real-time vehicle tracking
- **CORS Middleware:** Secure cross-origin requests from Flutter app
- **Request Validation:** Automatic validation with Pydantic models
- **Error Handling:** Consistent error responses across all endpoints
- **Database Session Management:** Automatic session handling with SQLAlchemy

### Example FastAPI Endpoint
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.permissions import require_role
from app.schemas.vehicle import VehicleCreate, VehicleResponse
from app.services.vehicle_service import VehicleService
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.post("/vehicles", response_model=VehicleResponse)
async def create_vehicle(
    vehicle: VehicleCreate,
    db: Session = Depends(get_db),
    current_user = Depends(require_role(["super_admin", "fleet_manager"]))
):
    """
    Create a new vehicle.

    Required roles: Super Admin, Fleet Manager
    """
    service = VehicleService(db)
    return service.create_vehicle(vehicle, current_user.id)
```

### Example: Custom Role Permission Check
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.permissions import check_permission
from app.schemas.vehicle import VehicleCreate, VehicleResponse
from app.services.vehicle_service import VehicleService
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.post("/vehicles", response_model=VehicleResponse)
async def create_vehicle(
    vehicle: VehicleCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Create a new vehicle.

    Permission required: vehicle_create
    Checks both predefined roles and custom role permissions.
    """
    # Check if user has permission (works for both predefined and custom roles)
    if not check_permission(current_user, "vehicle_create", db):
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to create vehicles"
        )

    service = VehicleService(db)
    return service.create_vehicle(vehicle, current_user.id)
```

### Template-Based Custom Role Creation

**Example: Create Custom Role from Template**
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas.custom_role import CustomRoleCreate
from app.services.template_service import TemplateService
from app.api.deps import get_db, require_role

router = APIRouter()

@router.post("/custom-roles/from-template")
async def create_custom_role_from_template(
    role_name: str,
    template_ids: list[str],  # Can use multiple predefined templates
    customizations: dict,  # Specific permission overrides
    db: Session = Depends(get_db),
    current_user = Depends(require_role(["super_admin"]))
):
    """
    Create a custom role using predefined role templates.

    Example request body:
    {
        "role_name": "Regional Manager - West Coast",
        "template_ids": ["fleet_manager", "operations_manager"],
        "customizations": {
            "vehicle_delete": "none",  # Override from template
            "financial_view": "view",  # Add from different template
            "region_filter": "west_coast"  # Custom constraint
        }
    }
    """
    template_service = TemplateService(db)

    # Get permissions from selected templates
    base_permissions = template_service.merge_templates(template_ids)

    # Apply customizations
    final_permissions = template_service.apply_customizations(
        base_permissions,
        customizations
    )

    # Create custom role
    custom_role = template_service.create_custom_role(
        name=role_name,
        permissions=final_permissions,
        template_sources=template_ids,  # Track which templates were used
        created_by=current_user.id
    )

    return {
        "role_id": custom_role.id,
        "role_name": custom_role.name,
        "permissions": custom_role.permissions,
        "template_sources": template_ids,
        "message": "Custom role created successfully from templates"
    }
```

**Example: Get Template for Customization**
```python
@router.get("/templates/predefined/{role_type}")
async def get_predefined_template(
    role_type: str,  # e.g., "fleet_manager", "accountant"
    db: Session = Depends(get_db),
    current_user = Depends(require_role(["super_admin", "operations_manager"]))
):
    """
    Get a predefined role template with all its permissions.
    Users can then customize this template to create their custom role.
    """
    template_service = TemplateService(db)

    # Get template with full permission details
    template = template_service.get_predefined_template(role_type)

    return {
        "template_id": role_type,
        "template_name": template.display_name,
        "description": template.description,
        "permissions": {
            "user_management": "limited",
            "vehicle_create": "full",
            "vehicle_edit": "full",
            "vehicle_delete": "none",
            "driver_manage": "full",
            "trip_create": "full",
            # ... all permissions
        },
        "permission_count": len(template.permissions),
        "users_with_this_role": template.user_count,
        "can_be_customized": True
    }
```

**Example: Merge Multiple Templates**
```python
@router.post("/templates/merge")
async def merge_templates(
    template_ids: list[str],
    merge_strategy: str = "union",  # "union" or "intersection"
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Merge permissions from multiple templates.

    Union: Combines all permissions (most permissive)
    Intersection: Only keeps common permissions (most restrictive)
    """
    template_service = TemplateService(db)

    merged_permissions = template_service.merge_templates(
        template_ids=template_ids,
        strategy=merge_strategy
    )

    return {
        "merged_from": template_ids,
        "strategy": merge_strategy,
        "resulting_permissions": merged_permissions,
        "permission_sources": {
            "vehicle_create": ["fleet_manager", "operations_manager"],
            "financial_view": ["accountant"],
            # Shows which template each permission came from
        }
    }
```

### Custom Role Permission System

The custom role system uses a flexible template-based permission architecture:

**Permission Structure:**
```python
# Example permission definition
{
    "permission_key": "vehicle_create",
    "permission_name": "Create Vehicles",
    "category": "vehicle_management",
    "access_levels": ["none", "view", "create", "full"]
}
```

**Custom Role Configuration:**
```python
# Example custom role in database
{
    "role_id": "custom_regional_manager",
    "role_name": "Regional Manager - West",
    "description": "Manages western region fleet operations",
    "is_custom": true,
    "permissions": {
        "vehicle_create": "full",
        "vehicle_edit": "full",
        "vehicle_delete": "none",
        "driver_manage": "full",
        "trip_create": "full",
        "financial_view": "view",
        "financial_manage": "none",
        "reports_generate": "full"
    },
    "created_by": "super_admin_user_id",
    "created_at": "2024-01-15T10:30:00Z"
}
```

**Permission Check Logic:**
```python
def check_permission(user, permission_key: str, db: Session) -> bool:
    """
    Check if user has specific permission.
    Works for both predefined and custom roles.
    """
    # Get user's role
    user_role = db.query(UserRole).filter_by(user_id=user.id).first()

    # If predefined role, check role_permissions table
    if user_role.role.is_predefined:
        return has_predefined_permission(user_role.role, permission_key, db)

    # If custom role, check custom_role_permissions table
    if user_role.role.is_custom:
        custom_permission = db.query(CustomRolePermission).filter_by(
            role_id=user_role.role_id,
            permission_key=permission_key
        ).first()

        return custom_permission and custom_permission.access_level != "none"

    return False
```

---

## Security Considerations

1. **Authentication:** All API endpoints require JWT authentication
2. **Role-Based Access Control (RBAC):** Enforced at API and database level using FastAPI dependencies
3. **Data Encryption:** Sensitive data encrypted at rest and in transit (HTTPS)
4. **Password Security:** Bcrypt hashing with salt
5. **Input Validation:** Pydantic models validate all incoming data
6. **SQL Injection Prevention:** SQLAlchemy ORM with parameterized queries
7. **CORS Configuration:** Restricted origins for production
8. **Rate Limiting:** Prevent API abuse with slowapi middleware
9. **Audit Logging:** All critical actions logged with user tracking
10. **Token Expiration:** JWT tokens with configurable expiration
11. **Environment Variables:** Sensitive configs in .env files (not committed)

---

## Environment Configuration

### Backend Environment Variables (.env)

Create a `.env` file in the backend directory with the following configuration:

```env
# Application
APP_NAME=Fleet Management System
APP_VERSION=1.0.0
DEBUG=True
ENVIRONMENT=development

# Server
HOST=0.0.0.0
PORT=8000

# Database
DATABASE_URL=postgresql://username:password@localhost:5432/fleet_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fleet_db
DB_USER=your_username
DB_PASSWORD=your_password

# JWT/Authentication
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
CORS_ALLOW_CREDENTIALS=True

# Redis (for caching and real-time features)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@fleetmanagement.com

# File Upload
MAX_UPLOAD_SIZE=10485760  # 10MB in bytes
UPLOAD_DIR=./uploads

# Google Maps (for tracking)
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Websocket
WEBSOCKET_HEARTBEAT_INTERVAL=30

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/app.log

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60

# Pagination
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100
```

### Frontend Environment Variables

For Flutter app, create environment-specific configuration files:

**lib/config/env.dart**
```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000/ws',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'your-api-key',
  );
}
```

---

## Future Enhancements

### Phase 1 - Core Features
- [ ] Push notifications (mobile and web)
- [ ] Email notifications for alerts and reminders
- [ ] Multi-language support
- [ ] Dark mode theme

### Phase 2 - Advanced Analytics
- [ ] AI-powered predictive maintenance
- [ ] Advanced route optimization using ML
- [ ] Driver behavior scoring and analytics
- [ ] Fuel consumption prediction
- [ ] Cost optimization recommendations
- [ ] Custom dashboard builder
****
### Phase 3 - Integration & Automation
- [ ] Integration with accounting software (QuickBooks, Xero)
- [ ] Integration with fuel card providers
- [ ] API for third-party integrations
- [ ] Automated invoice generation
- [ ] Integration with telematics devices
- [ ] Webhook support for real-time events

### Phase 4 - Advanced Features
- [ ] Video telematics and dashcam integration
- [ ] Driver mobile app with offline mode
- [ ] Advanced geofencing with custom zones
- [ ] Temperature monitoring for refrigerated vehicles
- [ ] Load/cargo management
- [ ] Electronic Logging Device (ELD) compliance
- [ ] Driver fatigue monitoring
- [ ] Fuel theft detection

### Phase 5 - Enterprise Features
- [ ] Multi-organization management
- [ ] White-label solution
- [ ] Advanced role customization
- [ ] SSO (Single Sign-On) support
- [ ] Custom workflows and automation
- [ ] Advanced reporting with custom queries
- [ ] Data export to BI tools
- [ ] Mobile SDK for custom apps

---

## Contributing

[Contribution guidelines to be added]

## License

[License information to be added]

## Contact

[Contact information to be added]
