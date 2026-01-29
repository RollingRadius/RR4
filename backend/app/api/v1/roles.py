"""
Roles API Endpoints
Get available roles and manage role assignments
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.user import User
from app.schemas.role import RoleResponse, RoleListResponse
from app.dependencies import get_current_user

router = APIRouter()


@router.get("/available", response_model=RoleListResponse)
async def get_available_roles(db: Session = Depends(get_db)):
    """
    Get all available roles for selection.

    Returns all system roles that users can request:
    - Super Admin
    - Fleet Manager
    - Dispatcher
    - Driver
    - Accountant/Finance Manager
    - Maintenance Manager
    - Compliance Officer
    - Operations Manager
    - Maintenance Technician
    - Customer Service Representative
    - Viewer/Analyst
    - Custom Roles (future)

    **Note:** This excludes internal system roles like 'pending_user' and 'independent_user'
    """
    # Get all roles except internal system roles
    roles = db.query(Role).filter(
        ~Role.role_key.in_(['pending_user', 'independent_user'])
    ).order_by(Role.role_name).all()

    role_list = []
    for role in roles:
        role_list.append(RoleResponse(
            id=str(role.id),
            role_name=role.role_name,
            role_key=role.role_key,
            description=role.description,
            is_system_role=role.is_system_role,
            is_custom_role=role.is_custom_role()
        ))

    return RoleListResponse(
        success=True,
        roles=role_list,
        count=len(role_list)
    )


@router.get("/my-role", response_model=dict)
async def get_my_role(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's role and status.

    Returns:
    - Current role assignment
    - Requested role (if pending)
    - Organization info
    - Approval status
    """
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id
    ).first()

    if not user_org:
        return {
            "success": True,
            "has_role": False,
            "message": "User has not completed profile"
        }

    role_info = {
        "success": True,
        "has_role": True,
        "status": user_org.status,
        "current_role": {
            "id": str(user_org.role.id),
            "name": user_org.role.role_name,
            "key": user_org.role.role_key,
            "description": user_org.role.description
        }
    }

    # Add requested role if exists
    if user_org.requested_role_id and user_org.requested_role:
        role_info["requested_role"] = {
            "id": str(user_org.requested_role.id),
            "name": user_org.requested_role.role_name,
            "key": user_org.requested_role.role_key,
            "description": user_org.requested_role.description
        }

    # Add organization info if exists
    if user_org.organization:
        role_info["organization"] = {
            "id": str(user_org.organization.id),
            "name": user_org.organization.name
        }

    # Add approval info if approved
    if user_org.approved_at:
        role_info["approved_at"] = user_org.approved_at.isoformat()
        if user_org.approver:
            role_info["approved_by"] = user_org.approver.full_name

    return role_info


@router.get("/pending-requests", response_model=dict)
async def get_pending_role_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get pending role requests for organization owners.

    **Requirements:**
    - User must be an owner of an organization

    **Returns:**
    - List of users pending approval with their requested roles
    """
    # Check if user is an owner
    owner_org = db.query(UserOrganization).join(
        Role, UserOrganization.role_id == Role.id
    ).filter(
        UserOrganization.user_id == current_user.id,
        Role.role_key == 'owner',
        UserOrganization.status == 'active'
    ).first()

    if not owner_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only organization owners can view pending requests"
        )

    # Get pending users for this organization
    pending_requests = db.query(UserOrganization).filter(
        UserOrganization.organization_id == owner_org.organization_id,
        UserOrganization.status == 'pending'
    ).all()

    requests_list = []
    for request in pending_requests:
        user_info = {
            "user_organization_id": str(request.id),
            "user_id": str(request.user_id),
            "user_name": request.user.full_name,
            "username": request.user.username,
            "email": request.user.email,
            "phone": request.user.phone,
            "joined_at": request.joined_at.isoformat(),
            "current_role": {
                "id": str(request.role.id),
                "name": request.role.role_name,
                "key": request.role.role_key
            }
        }

        # Add requested role if exists
        if request.requested_role_id and request.requested_role:
            user_info["requested_role"] = {
                "id": str(request.requested_role.id),
                "name": request.requested_role.role_name,
                "key": request.requested_role.role_key,
                "description": request.requested_role.description
            }

        requests_list.append(user_info)

    return {
        "success": True,
        "organization": {
            "id": str(owner_org.organization_id),
            "name": owner_org.organization.name
        },
        "pending_requests": requests_list,
        "count": len(requests_list)
    }


@router.post("/approve-request/{user_org_id}", response_model=dict)
async def approve_role_request(
    user_org_id: str,
    approved_role_id: str = None,  # Optional: owner can change the role
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Approve a pending role request.

    **Requirements:**
    - User must be an owner of the organization

    **Parameters:**
    - user_org_id: The UserOrganization ID to approve
    - approved_role_id: Optional role ID to assign (if different from requested)

    **Actions:**
    - Changes status from 'pending' to 'active'
    - Assigns the requested role or the role specified by owner
    - Records approval timestamp and approver
    """
    # Check if user is an owner
    owner_org = db.query(UserOrganization).join(
        Role, UserOrganization.role_id == Role.id
    ).filter(
        UserOrganization.user_id == current_user.id,
        Role.role_key == 'owner',
        UserOrganization.status == 'active'
    ).first()

    if not owner_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only organization owners can approve requests"
        )

    # Get the pending request
    user_org = db.query(UserOrganization).filter(
        UserOrganization.id == user_org_id,
        UserOrganization.organization_id == owner_org.organization_id,
        UserOrganization.status == 'pending'
    ).first()

    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pending request not found"
        )

    # Determine which role to assign
    if approved_role_id:
        # Owner is changing the role
        role = db.query(Role).filter(Role.id == approved_role_id).first()
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Specified role not found"
            )
        user_org.role_id = role.id
    elif user_org.requested_role_id:
        # Use the requested role
        user_org.role_id = user_org.requested_role_id
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No role specified for approval"
        )

    # Update status
    user_org.status = 'active'
    user_org.approved_at = func.now()
    user_org.approved_by = current_user.id

    db.commit()
    db.refresh(user_org)

    return {
        "success": True,
        "message": "Role request approved successfully",
        "user": {
            "id": str(user_org.user_id),
            "name": user_org.user.full_name,
            "username": user_org.user.username
        },
        "assigned_role": {
            "id": str(user_org.role.id),
            "name": user_org.role.role_name,
            "key": user_org.role.role_key
        },
        "approved_by": current_user.full_name,
        "approved_at": user_org.approved_at.isoformat()
    }


@router.post("/reject-request/{user_org_id}", response_model=dict)
async def reject_role_request(
    user_org_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Reject a pending role request.

    **Requirements:**
    - User must be an owner of the organization

    **Actions:**
    - Deletes the UserOrganization record
    - User can reapply to join the organization
    """
    # Check if user is an owner
    owner_org = db.query(UserOrganization).join(
        Role, UserOrganization.role_id == Role.id
    ).filter(
        UserOrganization.user_id == current_user.id,
        Role.role_key == 'owner',
        UserOrganization.status == 'active'
    ).first()

    if not owner_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only organization owners can reject requests"
        )

    # Get the pending request
    user_org = db.query(UserOrganization).filter(
        UserOrganization.id == user_org_id,
        UserOrganization.organization_id == owner_org.organization_id,
        UserOrganization.status == 'pending'
    ).first()

    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pending request not found"
        )

    user_name = user_org.user.full_name

    # Delete the request
    db.delete(user_org)
    db.commit()

    return {
        "success": True,
        "message": f"Role request from {user_name} has been rejected"
    }
