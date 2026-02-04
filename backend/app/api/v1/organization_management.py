"""
Organization Management API
For owners to manage their organization, employees, and access requests
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.dependencies import get_current_user

router = APIRouter()


def verify_owner(current_user: User, db: Session) -> UserOrganization:
    """
    Verify that the current user is an owner and return their organization.

    Raises:
        HTTPException: If user is not an owner
    """
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
            detail="Only organization owners can access this resource"
        )

    return owner_org


@router.get("/my-organization", response_model=dict)
def get_my_organization(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get organization details with statistics for the owner.

    **Requirements:**
    - User must be an owner

    **Returns:**
    - Organization details
    - Employee statistics
    - Pending requests count
    """
    owner_org = verify_owner(current_user, db)

    if not owner_org.organization:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organization not found"
        )

    organization = owner_org.organization

    # Get all members (active + pending)
    all_members = db.query(UserOrganization).filter(
        UserOrganization.organization_id == organization.id
    ).all()

    # Count active employees
    active_members = [m for m in all_members if m.status == 'active']
    pending_members = [m for m in all_members if m.status == 'pending']

    # Count by role
    role_distribution = {}
    for member in active_members:
        if member.role:
            role_name = member.role.role_name
            role_distribution[role_name] = role_distribution.get(role_name, 0) + 1

    return {
        "success": True,
        "organization": {
            "id": str(organization.id),
            "name": organization.company_name,
            "business_type": organization.business_type,
            "email": organization.business_email,
            "phone": organization.business_phone,
            "address": organization.address,
            "city": organization.city,
            "state": organization.state,
            "pincode": organization.pincode,
            "country": organization.country,
            "status": organization.status,
            "created_at": organization.created_at.isoformat()
        },
        "statistics": {
            "total_employees": len(active_members),
            "pending_requests": len(pending_members),
            "total_members": len(all_members),
            "role_distribution": role_distribution
        },
        "owner": {
            "id": str(current_user.id),
            "name": current_user.full_name,
            "username": current_user.username,
            "email": current_user.email
        }
    }


@router.get("/employees", response_model=dict)
def get_employees(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    role_filter: str = None,  # Optional: filter by role_key
    status_filter: str = 'active'  # Default: only active
):
    """
    Get list of all employees in the organization.

    **Requirements:**
    - User must be an owner

    **Query Parameters:**
    - role_filter: Filter by role_key (e.g., 'fleet_manager')
    - status_filter: Filter by status ('active', 'pending', 'all')

    **Returns:**
    - List of employees with their details and roles
    """
    owner_org = verify_owner(current_user, db)

    # Build query
    query = db.query(UserOrganization).filter(
        UserOrganization.organization_id == owner_org.organization_id
    )

    # Apply filters
    if status_filter and status_filter != 'all':
        query = query.filter(UserOrganization.status == status_filter)

    if role_filter:
        query = query.join(
            Role, UserOrganization.role_id == Role.id
        ).filter(Role.role_key == role_filter)

    employees = query.all()

    employee_list = []
    for emp_org in employees:
        employee = emp_org.user
        employee_info = {
            "user_organization_id": str(emp_org.id),
            "user_id": str(employee.id),
            "full_name": employee.full_name,
            "username": employee.username,
            "email": employee.email,
            "phone": employee.phone,
            "status": emp_org.status,
            "joined_at": emp_org.joined_at.isoformat(),
            "role": {
                "id": str(emp_org.role.id),
                "name": emp_org.role.role_name,
                "key": emp_org.role.role_key,
                "is_custom": emp_org.role.is_custom_role()
            } if emp_org.role else None
        }

        # Add requested role if pending
        if emp_org.requested_role_id and emp_org.requested_role:
            employee_info["requested_role"] = {
                "id": str(emp_org.requested_role.id),
                "name": emp_org.requested_role.role_name,
                "key": emp_org.requested_role.role_key
            }

        # Add approval info if approved
        if emp_org.approved_at:
            employee_info["approved_at"] = emp_org.approved_at.isoformat()
            if emp_org.approver:
                employee_info["approved_by"] = emp_org.approver.full_name

        employee_list.append(employee_info)

    return {
        "success": True,
        "employees": employee_list,
        "count": len(employee_list),
        "filters_applied": {
            "role": role_filter,
            "status": status_filter
        }
    }


@router.put("/employees/{user_org_id}/role", response_model=dict)
def update_employee_role(
    user_org_id: str,
    new_role_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update an employee's role.

    **Requirements:**
    - User must be an owner
    - Cannot change owner's role

    **Parameters:**
    - user_org_id: UserOrganization ID
    - new_role_id: New role ID to assign
    """
    owner_org = verify_owner(current_user, db)

    # Get the employee's UserOrganization record
    emp_org = db.query(UserOrganization).filter(
        UserOrganization.id == user_org_id,
        UserOrganization.organization_id == owner_org.organization_id
    ).first()

    if not emp_org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Employee not found in your organization"
        )

    # Check if trying to change owner role
    if emp_org.role and emp_org.role.role_key == 'owner':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot change owner's role"
        )

    # Verify new role exists
    new_role = db.query(Role).filter(Role.id == new_role_id).first()
    if not new_role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Role not found"
        )

    # Don't allow assigning owner role
    if new_role.role_key == 'owner':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot assign owner role to another user"
        )

    # Update role
    old_role_name = emp_org.role.role_name if emp_org.role else "None"
    emp_org.role_id = new_role.id

    db.commit()
    db.refresh(emp_org)

    return {
        "success": True,
        "message": f"Employee role updated from {old_role_name} to {new_role.role_name}",
        "employee": {
            "id": str(emp_org.user_id),
            "name": emp_org.user.full_name,
            "username": emp_org.user.username
        },
        "old_role": old_role_name,
        "new_role": {
            "id": str(new_role.id),
            "name": new_role.role_name,
            "key": new_role.role_key
        }
    }


@router.delete("/employees/{user_org_id}", response_model=dict)
def remove_employee(
    user_org_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Remove an employee from the organization.

    **Requirements:**
    - User must be an owner
    - Cannot remove self (owner)

    **Actions:**
    - Deletes UserOrganization record
    - Employee loses access to organization
    """
    owner_org = verify_owner(current_user, db)

    # Get the employee's UserOrganization record
    emp_org = db.query(UserOrganization).filter(
        UserOrganization.id == user_org_id,
        UserOrganization.organization_id == owner_org.organization_id
    ).first()

    if not emp_org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Employee not found in your organization"
        )

    # Cannot remove self
    if emp_org.user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot remove yourself from the organization"
        )

    employee_name = emp_org.user.full_name
    employee_role = emp_org.role.role_name if emp_org.role else "No role"

    # Delete the record
    db.delete(emp_org)
    db.commit()

    return {
        "success": True,
        "message": f"{employee_name} ({employee_role}) has been removed from the organization"
    }


@router.get("/statistics", response_model=dict)
def get_organization_statistics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get detailed statistics about the organization.

    **Requirements:**
    - User must be an owner

    **Returns:**
    - Employee count by role
    - Status distribution
    - Recent activity
    """
    owner_org = verify_owner(current_user, db)

    # Get all members
    all_members = db.query(UserOrganization).filter(
        UserOrganization.organization_id == owner_org.organization_id
    ).all()

    # Statistics
    total = len(all_members)
    active = len([m for m in all_members if m.status == 'active'])
    pending = len([m for m in all_members if m.status == 'pending'])
    inactive = len([m for m in all_members if m.status == 'inactive'])

    # Role distribution
    role_stats = {}
    for member in all_members:
        if member.role and member.status == 'active':
            role_key = member.role.role_key
            role_name = member.role.role_name

            if role_key not in role_stats:
                role_stats[role_key] = {
                    "role_name": role_name,
                    "count": 0,
                    "is_custom": member.role.is_custom_role()
                }
            role_stats[role_key]["count"] += 1

    # Recent joins (last 30 days)
    from datetime import timedelta
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    recent_joins = len([
        m for m in all_members
        if m.joined_at >= thirty_days_ago and m.status == 'active'
    ])

    return {
        "success": True,
        "statistics": {
            "total_members": total,
            "active_employees": active,
            "pending_requests": pending,
            "inactive_members": inactive,
            "recent_joins_30_days": recent_joins,
            "role_distribution": role_stats
        }
    }
