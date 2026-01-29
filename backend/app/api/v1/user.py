"""
User Profile and Organization Management API Endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.role import Role

router = APIRouter()


@router.get("/me")
async def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user profile information.

    **Requires:** JWT token in Authorization header

    **Returns:**
    - User profile
    - Current/default organization
    - Role information
    """
    # Get user's primary organization (first active one)
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    response = {
        "user_id": str(current_user.id),
        "username": current_user.username,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "phone": current_user.phone,
        "auth_method": current_user.auth_method,
        "status": current_user.status,
        "company_id": None,
        "company_name": None,
        "role": None
    }

    if user_org and user_org.organization:
        response.update({
            "company_id": str(user_org.organization_id),
            "company_name": user_org.organization.company_name,
            "role": user_org.role.name if user_org.role else None
        })

    return response


@router.post("/refresh-token")
async def refresh_token(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Refresh JWT token with updated user context.

    **Requires:** JWT token in Authorization header

    **Returns:**
    - New JWT token with updated organization info
    - Updated user profile

    **Use Cases:**
    - After creating an organization
    - After joining an organization
    - After organization context changes
    """
    from app.core.security import create_access_token

    # Get user's primary organization (first active one)
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    # Generate new JWT token with updated context
    token_data = {
        "sub": str(current_user.id),
        "username": current_user.username,
        "role": user_org.role.role_key if user_org and user_org.role else "independent_user",
        "company_id": str(user_org.organization_id) if user_org else None
    }

    access_token = create_access_token(token_data)

    return {
        "success": True,
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": str(current_user.id),
        "username": current_user.username,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "company_id": str(user_org.organization_id) if user_org else None,
        "company_name": user_org.organization.company_name if user_org and user_org.organization else None,
        "role": user_org.role.role_name if user_org and user_org.role else "Independent User"
    }


@router.get("/organizations")
async def get_user_organizations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all organizations the current user belongs to.

    **Returns:**
    - List of organizations with role and status
    - Active and pending organizations
    """
    user_orgs = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id
    ).join(Organization).join(
        Role, UserOrganization.role_id == Role.id
    ).all()

    organizations = []
    for user_org in user_orgs:
        if user_org.organization:
            organizations.append({
                "organization_id": str(user_org.organization_id),
                "organization_name": user_org.organization.company_name,
                "role": user_org.role.role_name if user_org.role else None,
                "role_key": user_org.role.role_key if user_org.role else None,
                "status": user_org.status,
                "joined_at": user_org.joined_at.isoformat(),
                "is_active": user_org.is_active()
            })

    return {
        "success": True,
        "organizations": organizations,
        "count": len(organizations)
    }


@router.post("/set-organization/{organization_id}")
async def set_active_organization(
    organization_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Set the active organization for the user session.

    **Parameters:**
    - organization_id: ID of the organization to switch to

    **Returns:**
    - New JWT token with updated organization context
    - Organization details
    """
    from app.core.security import create_access_token

    # Verify user has access to this organization
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.organization_id == organization_id,
        UserOrganization.status == 'active'
    ).first()

    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this organization"
        )

    # Generate new JWT token with updated organization context
    token_data = {
        "sub": str(current_user.id),
        "username": current_user.username,
        "role": user_org.role.role_key if user_org.role else None,
        "company_id": str(organization_id)
    }

    access_token = create_access_token(token_data)

    return {
        "success": True,
        "access_token": access_token,
        "token_type": "bearer",
        "organization_id": str(user_org.organization_id),
        "organization_name": user_org.organization.company_name,
        "role": user_org.role.name if user_org.role else None,
        "message": "Organization context updated successfully"
    }
