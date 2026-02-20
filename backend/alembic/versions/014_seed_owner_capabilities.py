"""seed owner role capabilities

Revision ID: 014_seed_owner_capabilities
Revises: 013_seed_predefined_roles
Create Date: 2026-02-20

Seeds the 'owner' system role with full access to all capabilities,
mirroring super_admin so organization owners can manage the entire system.
Also seeds capabilities for the simple org roles (admin, dispatcher, user, viewer)
that were added in migration 011.
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '014_seed_owner_capabilities'
down_revision: Union[str, None] = '013_seed_predefined_roles'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# All capability keys to grant to the owner role with FULL access
OWNER_CAPABILITIES = [
    # User Management
    "user.view", "user.create", "user.edit", "user.delete",
    "user.role.assign", "user.role.revoke", "user.password.reset",
    "user.activate", "user.deactivate", "user.activity.view",
    # Role Management
    "role.view", "role.predefined.view", "role.custom.view",
    "role.custom.create", "role.custom.edit", "role.custom.delete",
    "role.template.view", "role.template.use",
    "role.capability.assign", "role.capability.revoke",
    # Vehicle Management
    "vehicle.view", "vehicle.create", "vehicle.edit", "vehicle.delete",
    "vehicle.export", "vehicle.import", "vehicle.archive", "vehicle.assign",
    "vehicle.documents.view", "vehicle.documents.upload", "vehicle.documents.delete",
    # Driver Management
    "driver.view", "driver.view.all", "driver.view.own", "driver.create",
    "driver.edit", "driver.delete", "driver.license.view", "driver.license.manage",
    "driver.performance.view", "driver.assign",
    # Trip Management
    "trip.view", "trip.view.all", "trip.view.own", "trip.create", "trip.edit",
    "trip.delete", "trip.assign", "trip.status.update",
    "trip.route.view", "trip.route.modify", "trip.waypoint.add", "trip.waypoint.edit",
    # Tracking
    "tracking.view.all", "tracking.view.active", "tracking.view.own",
    "tracking.history.view", "tracking.history.export",
    "tracking.geofence.view", "tracking.geofence.create", "tracking.geofence.edit",
    "tracking.alerts.manage",
    # Financial
    "finance.view", "finance.dashboard",
    "expense.view", "expense.create", "expense.edit", "expense.delete",
    "expense.approve", "expense.reject",
    "invoice.view", "invoice.create", "invoice.edit", "invoice.send", "invoice.delete",
    "payment.view", "payment.record",
    "budget.view", "budget.manage", "finance.export",
    # Maintenance
    "maintenance.view", "maintenance.schedule.view", "maintenance.schedule.create",
    "maintenance.schedule.edit", "maintenance.record.create",
    "maintenance.workorder.view", "maintenance.workorder.create",
    "maintenance.workorder.assign", "maintenance.workorder.update",
    "maintenance.workorder.complete",
    "maintenance.inspection.perform", "maintenance.inspection.view",
    "parts.view", "parts.request", "parts.manage", "parts.order",
    "vendor.view", "vendor.manage",
    # Compliance
    "compliance.view", "compliance.license.view", "compliance.license.manage",
    "compliance.document.view", "compliance.document.upload", "compliance.document.manage",
    "compliance.inspection.view", "compliance.inspection.schedule",
    "compliance.inspection.perform",
    "compliance.incident.view", "compliance.incident.create", "compliance.incident.manage",
    "compliance.certification.view", "compliance.certification.manage",
    "compliance.hos.view", "compliance.hos.manage", "compliance.alerts.view",
    # Customer
    "customer.view", "customer.create", "customer.edit", "customer.delete",
    "customer.contact.manage",
    "support.ticket.view", "support.ticket.create", "support.ticket.assign",
    "support.ticket.update", "support.ticket.close",
    "notification.send", "communication.log.view",
    # Reporting
    "reports.view", "reports.fleet.view", "reports.driver.view",
    "reports.financial.view", "reports.maintenance.view", "reports.compliance.view",
    "reports.custom.create", "reports.export", "reports.schedule",
    "analytics.dashboard.view", "analytics.dashboard.customize", "analytics.kpi.view",
    # System
    "system.settings.view", "system.settings.edit",
    "system.config.view", "system.config.edit",
    "system.audit.view",
    "system.backup.create", "system.backup.restore",
    "system.integration.manage",
]

# Capabilities for the 'admin' org role (added in migration 011)
# Admin can manage users, roles, vehicles, drivers, trips but not full system access
ADMIN_CAPABILITIES = [
    "user.view", "user.create", "user.edit", "user.role.assign",
    "role.view", "role.predefined.view", "role.custom.view",
    "role.custom.create", "role.custom.edit",
    "vehicle.view", "vehicle.create", "vehicle.edit", "vehicle.assign",
    "vehicle.documents.view", "vehicle.documents.upload",
    "driver.view", "driver.view.all", "driver.create", "driver.edit",
    "driver.license.view", "driver.performance.view", "driver.assign",
    "trip.view", "trip.view.all", "trip.create", "trip.edit", "trip.assign", "trip.status.update",
    "trip.route.view", "trip.route.modify",
    "tracking.view.all", "tracking.history.view",
    "reports.view", "reports.fleet.view", "reports.driver.view", "reports.export",
    "analytics.dashboard.view", "analytics.kpi.view",
    "maintenance.view", "maintenance.schedule.view",
    "compliance.view", "compliance.document.view",
    "expense.view", "expense.create",
    "customer.view",
    "system.audit.view",
]

# Capabilities for the 'dispatcher' org role
DISPATCHER_CAPABILITIES = [
    "vehicle.view",
    "driver.view", "driver.view.all",
    "trip.view", "trip.view.all", "trip.create", "trip.edit", "trip.assign",
    "trip.status.update", "trip.route.view", "trip.route.modify",
    "trip.waypoint.add", "trip.waypoint.edit",
    "tracking.view.active", "tracking.geofence.view",
    "customer.view", "notification.send",
    "reports.view", "reports.fleet.view", "reports.driver.view",
]

# Capabilities for the 'user' org role (standard access)
USER_CAPABILITIES = [
    "vehicle.view",
    "driver.view.own",
    "trip.view.own", "trip.status.update",
    "tracking.view.own",
    "expense.create", "expense.view",
    "maintenance.workorder.view", "maintenance.inspection.view",
    "support.ticket.create",
    "reports.view",
]

# Capabilities for the 'viewer' org role (read-only)
VIEWER_CAPABILITIES = [
    "vehicle.view",
    "driver.view", "driver.view.all",
    "trip.view", "trip.view.all",
    "tracking.view.all", "tracking.history.view",
    "finance.view", "expense.view",
    "maintenance.view",
    "compliance.view",
    "customer.view",
    "reports.view", "reports.fleet.view", "reports.driver.view",
    "reports.financial.view", "reports.maintenance.view", "reports.compliance.view",
    "reports.export", "analytics.dashboard.view", "analytics.kpi.view",
]


def _seed_role_capabilities(role_key: str, capabilities: list, access_level: str = 'full') -> None:
    """Helper to seed capabilities for a given role key."""
    for capability_key in capabilities:
        op.execute(
            sa.text("""
                INSERT INTO role_capabilities (id, role_id, capability_key, access_level)
                SELECT gen_random_uuid(), r.id, :capability_key, :access_level
                FROM roles r
                WHERE r.role_key = :role_key
                AND EXISTS (SELECT 1 FROM capabilities c WHERE c.capability_key = :capability_key)
                AND NOT EXISTS (
                    SELECT 1 FROM role_capabilities rc
                    WHERE rc.role_id = r.id AND rc.capability_key = :capability_key
                )
            """).bindparams(
                capability_key=capability_key,
                access_level=access_level,
                role_key=role_key
            )
        )


def upgrade() -> None:
    """Seed capabilities for owner and org roles."""
    # Owner gets full access to everything (same as super_admin)
    _seed_role_capabilities('owner', OWNER_CAPABILITIES, 'full')

    # Org roles from migration 011
    _seed_role_capabilities('admin', ADMIN_CAPABILITIES, 'full')
    _seed_role_capabilities('dispatcher', DISPATCHER_CAPABILITIES, 'full')
    _seed_role_capabilities('user', USER_CAPABILITIES, 'full')
    _seed_role_capabilities('viewer', VIEWER_CAPABILITIES, 'view')


def downgrade() -> None:
    """Remove seeded capabilities for owner and org roles."""
    for role_key in ('owner', 'admin', 'dispatcher', 'user', 'viewer'):
        op.execute(
            sa.text("""
                DELETE FROM role_capabilities
                WHERE role_id = (SELECT id FROM roles WHERE role_key = :role_key)
            """).bindparams(role_key=role_key)
        )
