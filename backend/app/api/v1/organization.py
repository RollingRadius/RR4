"""
Organization Management API Endpoints
Member management, approvals, and role assignments
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.organization import (
    OrganizationMembersListResponse,
    PendingUsersResponse,
    ApproveUserRequest, ApproveUserResponse,
    RejectUserRequest, RejectUserResponse,
    UpdateUserRoleRequest, UpdateUserRoleResponse,
    RemoveUserRequest, RemoveUserResponse
)
from app.services.organization_service import OrganizationService

router = APIRouter()


@router.get("/{organization_id}/members", response_model=OrganizationMembersListResponse)
async def get_organization_members(
    organization_id: str,
    include_pending: bool = Query(False, description="Include pending users"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all members of an organization.

    **Requires:** User must be a member of the organization

    **Returns:**
    - List of all members
    - Member details: user info, role, status
    - Counts: active, pending, total

    **Query Parameters:**
    - include_pending: Set to true to include pending users (default: false)

    **Use Cases:**
    - View organization members
    - Check member roles and status
    """
    org_service = OrganizationService(db)

    result = org_service.get_organization_members(
        organization_id=organization_id,
        current_user_id=str(current_user.id),
        include_pending=include_pending
    )

    return OrganizationMembersListResponse(**result)


@router.get("/{organization_id}/pending-users", response_model=PendingUsersResponse)
async def get_pending_users(
    organization_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all pending users awaiting approval.

    **Requires:** Owner or Admin role

    **Returns:**
    - List of pending users
    - User details: username, full name, contact info
    - Join request timestamp

    **Use Cases:**
    - View pending join requests
    - Decide who to approve/reject
    """
    org_service = OrganizationService(db)

    result = org_service.get_pending_users(
        organization_id=organization_id,
        current_user_id=str(current_user.id)
    )

    return PendingUsersResponse(**result)


@router.post("/{organization_id}/approve-user", response_model=ApproveUserResponse)
async def approve_user(
    organization_id: str,
    approve_data: ApproveUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Approve a pending user and assign a role.

    **Requires:** Owner or Admin role

    **Request Body:**
    - user_id: User to approve
    - role_key: Role to assign (admin, dispatcher, user, viewer)

    **Process:**
    1. Verify pending user exists
    2. Assign selected role
    3. Set status to 'active'
    4. Log approval in audit log

    **Available Roles:**
    - admin: Can manage members and settings
    - dispatcher: Can manage trips and assignments
    - user: Standard access to features
    - viewer: Read-only access

    **Note:**
    - Cannot assign owner role through approval
    """
    org_service = OrganizationService(db)

    result = org_service.approve_user(
        organization_id=organization_id,
        current_user_id=str(current_user.id),
        user_id=approve_data.user_id,
        role_key=approve_data.role_key
    )

    return ApproveUserResponse(**result)


@router.post("/{organization_id}/reject-user", response_model=RejectUserResponse)
async def reject_user(
    organization_id: str,
    reject_data: RejectUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Reject a pending user's request to join.

    **Requires:** Owner or Admin role

    **Request Body:**
    - user_id: User to reject
    - reason: Optional rejection reason

    **Process:**
    1. Verify pending user exists
    2. Remove user-organization relationship
    3. Log rejection in audit log

    **Note:**
    - Rejection is permanent, user must request to join again
    """
    org_service = OrganizationService(db)

    result = org_service.reject_user(
        organization_id=organization_id,
        current_user_id=str(current_user.id),
        user_id=reject_data.user_id,
        reason=reject_data.reason
    )

    return RejectUserResponse(**result)


@router.post("/{organization_id}/update-role", response_model=UpdateUserRoleResponse)
async def update_user_role(
    organization_id: str,
    update_data: UpdateUserRoleRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update a user's role in the organization.

    **Requires:** Owner or Admin role

    **Request Body:**
    - user_id: User to update
    - role_key: New role (admin, dispatcher, user, viewer)

    **Restrictions:**
    - Only owners can change/assign owner roles
    - Users cannot change their own role
    - Admins cannot change owner roles

    **Process:**
    1. Verify user exists and is active
    2. Check permissions
    3. Update role
    4. Log change in audit log

    **Use Cases:**
    - Promote user to admin
    - Demote user to viewer
    - Change dispatcher to regular user
    """
    org_service = OrganizationService(db)

    result = org_service.update_user_role(
        organization_id=organization_id,
        current_user_id=str(current_user.id),
        user_id=update_data.user_id,
        new_role_key=update_data.role_key
    )

    return UpdateUserRoleResponse(**result)


@router.post("/{organization_id}/remove-user", response_model=RemoveUserResponse)
async def remove_user(
    organization_id: str,
    remove_data: RemoveUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Remove a user from the organization.

    **Requires:** Owner or Admin role

    **Request Body:**
    - user_id: User to remove

    **Restrictions:**
    - Only owners can remove other owners
    - Users cannot remove themselves
    - Must transfer ownership before removing last owner

    **Process:**
    1. Verify user exists
    2. Check permissions
    3. Remove user-organization relationship
    4. Log removal in audit log

    **Note:**
    - Removal is permanent
    - User must request to join again if needed
    """
    org_service = OrganizationService(db)

    result = org_service.remove_user(
        organization_id=organization_id,
        current_user_id=str(current_user.id),
        user_id=remove_data.user_id
    )

    return RemoveUserResponse(**result)
