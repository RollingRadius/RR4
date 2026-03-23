"""
Permission Checking Middleware and Decorators
Capability-based access control
"""
from typing import List, Optional, Callable
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User
from app.services.capability_service import CapabilityService
from app.models.capability import AccessLevel

# ---------------------------------------------------------------------------
# Capability domain boundaries
# These prefixes belong exclusively to fleet_manager (and super_admin).
# load_owner must NOT auto-pass these — they will fail the capability check
# since no vehicle capabilities are granted to load_owner in role_capabilities.
# ---------------------------------------------------------------------------
_FLEET_MANAGER_ONLY_PREFIXES: tuple = (
    'vehicle.',
    'driver.',
    'tracking.',
    'maintenance.',
    'compliance.',
    'trip.',
    'fleet.',
)


def _role_auto_passes(role_key: str, capability_key: str) -> bool:
    """
    Determine whether a role auto-passes a capability check without hitting
    the role_capabilities table.

    Rules:
    - super_admin  → always passes
    - fleet_manager → always passes (manages all fleet operations)
    - load_owner   → passes ONLY for non-fleet capabilities
                     (cannot access vehicle/driver/maintenance/trip/tracking)
    - all others   → never auto-passes; must have explicit role_capability row
    """
    if role_key == 'super_admin':
        return True
    if role_key == 'fleet_management':
        return True
    if role_key == 'load_owner':
        for prefix in _FLEET_MANAGER_ONLY_PREFIXES:
            if capability_key.startswith(prefix):
                return False   # falls through to capability table check → 403
        return True
    return False


def require_capability(
    capability_key: str,
    required_level: str = AccessLevel.VIEW
):
    """
    Dependency to check if user has specific capability.
    Usage:
        @router.post("/vehicles")
        async def create_vehicle(
            current_user = Depends(require_capability("vehicle.create", AccessLevel.FULL))
        ):
            ...
    """
    async def check_capability(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> User:
        # Get user's active organization from DB
        from app.models import UserOrganization
        from app.models.role import Role as RoleModel
        user_org = db.query(UserOrganization).filter(
            UserOrganization.user_id == current_user.id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org or not user_org.organization_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User must be associated with an active organization"
            )

        # Role-domain auto-pass (fleet_owner owns all; load_owner is blocked
        # from fleet capabilities; others must have explicit row).
        user_role = db.query(RoleModel).filter(RoleModel.id == user_org.role_id).first()
        if user_role and _role_auto_passes(user_role.role_key, capability_key):
            return current_user

        organization_id = str(user_org.organization_id)
        capability_service = CapabilityService(db)

        # Check if user has the capability
        has_capability = capability_service.check_user_capability(
            user_id=str(current_user.id),
            organization_id=organization_id,
            capability_key=capability_key,
            required_level=required_level
        )

        if not has_capability:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required capability: {capability_key} (level: {required_level})"
            )

        return current_user

    return check_capability


def require_any_capability(
    capability_keys: List[str],
    required_level: str = AccessLevel.VIEW
):
    """
    Dependency to check if user has ANY of the specified capabilities.
    Useful for endpoints that can be accessed by multiple permission types.
    """
    async def check_any_capability(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> User:
        from app.models import UserOrganization
        from app.models.role import Role as RoleModel
        user_org = db.query(UserOrganization).filter(
            UserOrganization.user_id == current_user.id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org or not user_org.organization_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User must be associated with an active organization"
            )

        # Role-domain auto-pass — check against each requested capability
        user_role = db.query(RoleModel).filter(RoleModel.id == user_org.role_id).first()
        if user_role and all(
            _role_auto_passes(user_role.role_key, k) for k in capability_keys
        ):
            return current_user

        organization_id = str(user_org.organization_id)
        capability_service = CapabilityService(db)

        # Check if user has any of the capabilities
        for capability_key in capability_keys:
            has_capability = capability_service.check_user_capability(
                user_id=str(current_user.id),
                organization_id=organization_id,
                capability_key=capability_key,
                required_level=required_level
            )
            if has_capability:
                return current_user

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Missing required capabilities. Need one of: {', '.join(capability_keys)}"
        )

    return check_any_capability


def require_all_capabilities(
    capability_keys: List[str],
    required_level: str = AccessLevel.VIEW
):
    """
    Dependency to check if user has ALL of the specified capabilities.
    """
    async def check_all_capabilities(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> User:
        from app.models import UserOrganization
        from app.models.role import Role as RoleModel
        user_org = db.query(UserOrganization).filter(
            UserOrganization.user_id == current_user.id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org or not user_org.organization_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User must be associated with an active organization"
            )

        # Role-domain auto-pass — all keys must pass for the role
        user_role = db.query(RoleModel).filter(RoleModel.id == user_org.role_id).first()
        if user_role and all(
            _role_auto_passes(user_role.role_key, k) for k in capability_keys
        ):
            return current_user

        organization_id = str(user_org.organization_id)
        capability_service = CapabilityService(db)

        missing_capabilities = []

        # Check if user has all capabilities
        for capability_key in capability_keys:
            has_capability = capability_service.check_user_capability(
                user_id=str(current_user.id),
                organization_id=organization_id,
                capability_key=capability_key,
                required_level=required_level
            )
            if not has_capability:
                missing_capabilities.append(capability_key)

        if missing_capabilities:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required capabilities: {', '.join(missing_capabilities)}"
            )

        return current_user

    return check_all_capabilities


def check_capability_sync(
    user: User,
    organization_id: str,
    capability_key: str,
    required_level: str,
    db: Session
) -> bool:
    """
    Synchronous capability check for use in service layer.
    """
    capability_service = CapabilityService(db)
    return capability_service.check_user_capability(
        user_id=str(user.id),
        organization_id=organization_id,
        capability_key=capability_key,
        required_level=required_level
    )


def get_user_capabilities_sync(
    user: User,
    organization_id: str,
    db: Session
) -> dict:
    """
    Get all user capabilities synchronously.
    """
    capability_service = CapabilityService(db)
    return capability_service.get_user_capabilities(
        user_id=str(user.id),
        organization_id=organization_id
    )


# Legacy role-based check for backward compatibility
def require_role(allowed_roles: List[str]):
    """
    Legacy role-based permission check.
    Kept for backward compatibility with existing code.
    Will be deprecated in favor of capability-based checks.
    """
    async def check_role(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ) -> User:
        # Get user's role in active organization
        from app.models import UserOrganization
        from app.models.role import Role as RoleModel
        user_org = db.query(UserOrganization).filter(
            UserOrganization.user_id == current_user.id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org or not user_org.organization_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User must be associated with an active organization"
            )

        # Only fleet_owner and super_admin bypass legacy role checks by default.
        # load_owner must be explicitly listed in allowed_roles to pass.
        user_role_obj = db.query(RoleModel).filter(RoleModel.id == user_org.role_id).first()
        if user_role_obj and user_role_obj.role_key in ('fleet_management', 'super_admin'):
            return current_user

        if not user_org or not user_org.role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User does not have a role in this organization"
            )

        if user_org.role.role_key not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required roles: {', '.join(allowed_roles)}"
            )

        return current_user

    return check_role


# Convenience functions for common capabilities
def require_super_admin():
    """Check if user has super admin role"""
    return require_role(["super_admin"])


def require_admin():
    """Check if user has admin privileges"""
    return require_any_capability([
        "user.create",
        "user.edit",
        "role.custom.create"
    ], AccessLevel.FULL)


def require_vehicle_create():
    """Check if user can create vehicles"""
    return require_capability("vehicle.create", AccessLevel.FULL)


def require_vehicle_edit():
    """Check if user can edit vehicles"""
    return require_capability("vehicle.edit", AccessLevel.FULL)


def require_vehicle_view():
    """Check if user can view vehicles"""
    return require_capability("vehicle.view", AccessLevel.VIEW)


def require_driver_create():
    """Check if user can create drivers"""
    return require_capability("driver.create", AccessLevel.FULL)


def require_driver_edit():
    """Check if user can edit drivers"""
    return require_capability("driver.edit", AccessLevel.FULL)


def require_driver_view():
    """Check if user can view drivers"""
    return require_capability("driver.view", AccessLevel.VIEW)


def require_reports_view():
    """Check if user can view reports"""
    return require_capability("reports.view", AccessLevel.VIEW)


def require_reports_export():
    """Check if user can export reports"""
    return require_capability("reports.export", AccessLevel.FULL)
