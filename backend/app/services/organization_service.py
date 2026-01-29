"""
Organization Management Service
Business logic for managing organization members, approvals, and roles
"""

from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from typing import List, Optional
from datetime import datetime
import uuid

from app.models.company import Organization
from app.models.user_organization import UserOrganization
from app.models.user import User
from app.models.role import Role
from app.models.audit_log import AuditLog
from app.utils.constants import (
    AUDIT_ACTION_USER_APPROVED,
    AUDIT_ACTION_USER_REJECTED,
    AUDIT_ACTION_ROLE_CHANGED,
    AUDIT_ACTION_USER_REMOVED,
    ENTITY_TYPE_USER_ORG
)


class OrganizationService:
    """Service for organization member management"""

    def __init__(self, db: Session):
        self.db = db

    def _check_organization_access(
        self,
        user_id: str,
        organization_id: str,
        required_roles: List[str] = None
    ) -> UserOrganization:
        """
        Check if user has access to organization with required role.

        Args:
            user_id: User ID
            organization_id: Organization ID
            required_roles: List of role keys that are allowed (e.g., ['owner', 'admin'])

        Returns:
            UserOrganization object

        Raises:
            HTTPException: If user doesn't have access
        """
        user_org = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.role)
        ).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == organization_id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this organization"
            )

        if required_roles and user_org.role.role_key not in required_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"This action requires one of these roles: {', '.join(required_roles)}"
            )

        return user_org

    def get_organization_members(
        self,
        organization_id: str,
        current_user_id: str,
        include_pending: bool = False
    ) -> dict:
        """
        Get all members of an organization.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be member)
            include_pending: Whether to include pending users

        Returns:
            Dictionary with members list and counts
        """
        # Check if user has access
        self._check_organization_access(current_user_id, organization_id)

        # Get organization
        organization = self.db.query(Organization).filter(
            Organization.id == organization_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Build query
        query = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user),
            joinedload(UserOrganization.role)
        ).filter(
            UserOrganization.organization_id == organization_id
        )

        if not include_pending:
            query = query.filter(UserOrganization.status == 'active')

        user_orgs = query.all()

        # Format response
        members = []
        active_count = 0
        pending_count = 0

        for user_org in user_orgs:
            if user_org.user and user_org.role:
                members.append({
                    "user_id": str(user_org.user_id),
                    "username": user_org.user.username,
                    "full_name": user_org.user.full_name,
                    "email": user_org.user.email,
                    "phone": user_org.user.phone,
                    "role": user_org.role.name,
                    "role_key": user_org.role.role_key,
                    "status": user_org.status,
                    "joined_at": user_org.joined_at,
                    "approved_at": user_org.approved_at,
                    "is_pending": user_org.is_pending(),
                    "is_active": user_org.is_active()
                })

                if user_org.is_active():
                    active_count += 1
                elif user_org.is_pending():
                    pending_count += 1

        return {
            "success": True,
            "organization_id": str(organization_id),
            "organization_name": organization.company_name,
            "members": members,
            "active_count": active_count,
            "pending_count": pending_count,
            "total_count": len(members)
        }

    def get_pending_users(
        self,
        organization_id: str,
        current_user_id: str
    ) -> dict:
        """
        Get pending users for an organization.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be owner/admin)

        Returns:
            Dictionary with pending users list
        """
        # Check if user is owner or admin
        self._check_organization_access(
            current_user_id,
            organization_id,
            required_roles=['owner', 'admin']
        )

        # Get organization
        organization = self.db.query(Organization).filter(
            Organization.id == organization_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Get pending users
        pending_users = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user),
            joinedload(UserOrganization.requested_role)
        ).filter(
            UserOrganization.organization_id == organization_id,
            UserOrganization.status == 'pending'
        ).all()

        # Format response
        users = []
        for user_org in pending_users:
            if user_org.user:
                # For pending users, show the requested role
                requested_role = user_org.requested_role
                role_name = requested_role.role_name if requested_role else 'No role requested'
                role_key = requested_role.role_key if requested_role else None

                users.append({
                    "user_id": str(user_org.user_id),
                    "username": user_org.user.username,
                    "full_name": user_org.user.full_name,
                    "email": user_org.user.email,
                    "phone": user_org.user.phone,
                    "role": role_name,
                    "role_key": role_key,
                    "requested_role": role_name,
                    "requested_role_key": role_key,
                    "status": user_org.status,
                    "joined_at": user_org.joined_at.isoformat() if user_org.joined_at else None,
                    "approved_at": user_org.approved_at.isoformat() if user_org.approved_at else None,
                    "is_pending": True,
                    "is_active": False
                })

        return {
            "success": True,
            "organization_id": str(organization_id),
            "organization_name": organization.company_name,
            "pending_users": users,
            "count": len(users)
        }

    def approve_user(
        self,
        organization_id: str,
        current_user_id: str,
        user_id: str,
        role_key: str = 'user'
    ) -> dict:
        """
        Approve a pending user and assign role.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be owner/admin)
            user_id: User ID to approve
            role_key: Role to assign (default: 'user')

        Returns:
            Approval confirmation
        """
        # Check if current user is owner or admin
        self._check_organization_access(
            current_user_id,
            organization_id,
            required_roles=['owner', 'admin']
        )

        # Get the pending user-organization relationship
        user_org = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user)
        ).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == organization_id,
            UserOrganization.status == 'pending'
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pending user not found"
            )

        # Get the role to assign
        role = self.db.query(Role).filter(
            Role.role_key == role_key
        ).first()

        if not role:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role: {role_key}"
            )

        # Prevent assigning owner role
        if role_key == 'owner':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot assign owner role through approval"
            )

        # Update user-organization
        user_org.status = 'active'
        user_org.role_id = role.id
        user_org.approved_at = datetime.utcnow()
        user_org.approved_by = current_user_id

        # Log audit event
        audit_log = AuditLog(
            user_id=current_user_id,
            organization_id=organization_id,
            action=AUDIT_ACTION_USER_APPROVED,
            entity_type=ENTITY_TYPE_USER_ORG,
            entity_id=user_org.id,
            details={
                "approved_user_id": str(user_id),
                "username": user_org.user.username,
                "role_assigned": role.name
            }
        )

        self.db.add(audit_log)
        self.db.commit()
        self.db.refresh(user_org)

        return {
            "success": True,
            "message": f"User {user_org.user.username} approved successfully",
            "user_id": str(user_id),
            "username": user_org.user.username,
            "role": role.name
        }

    def reject_user(
        self,
        organization_id: str,
        current_user_id: str,
        user_id: str,
        reason: Optional[str] = None
    ) -> dict:
        """
        Reject a pending user.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be owner/admin)
            user_id: User ID to reject
            reason: Optional rejection reason

        Returns:
            Rejection confirmation
        """
        # Check if current user is owner or admin
        self._check_organization_access(
            current_user_id,
            organization_id,
            required_roles=['owner', 'admin']
        )

        # Get the pending user-organization relationship
        user_org = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user)
        ).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == organization_id,
            UserOrganization.status == 'pending'
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pending user not found"
            )

        username = user_org.user.username if user_org.user else "Unknown"

        # Log audit event before deletion
        audit_log = AuditLog(
            user_id=current_user_id,
            organization_id=organization_id,
            action=AUDIT_ACTION_USER_REJECTED,
            entity_type=ENTITY_TYPE_USER_ORG,
            entity_id=user_org.id,
            details={
                "rejected_user_id": str(user_id),
                "username": username,
                "reason": reason
            }
        )

        self.db.add(audit_log)

        # Delete the relationship
        self.db.delete(user_org)
        self.db.commit()

        return {
            "success": True,
            "message": f"User {username} rejected successfully",
            "user_id": str(user_id)
        }

    def update_user_role(
        self,
        organization_id: str,
        current_user_id: str,
        user_id: str,
        new_role_key: str
    ) -> dict:
        """
        Update a user's role in the organization.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be owner/admin)
            user_id: User ID to update
            new_role_key: New role key

        Returns:
            Update confirmation
        """
        # Check if current user is owner or admin
        current_user_org = self._check_organization_access(
            current_user_id,
            organization_id,
            required_roles=['owner', 'admin']
        )

        # Get the user-organization relationship
        user_org = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user),
            joinedload(UserOrganization.role)
        ).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == organization_id,
            UserOrganization.status == 'active'
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found in organization"
            )

        # Get the new role
        new_role = self.db.query(Role).filter(
            Role.role_key == new_role_key
        ).first()

        if not new_role:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role: {new_role_key}"
            )

        # Prevent changing owner role unless current user is owner
        if user_org.role.role_key == 'owner' and current_user_org.role.role_key != 'owner':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only owners can change owner roles"
            )

        # Prevent assigning owner role unless current user is owner
        if new_role_key == 'owner' and current_user_org.role.role_key != 'owner':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only owners can assign owner role"
            )

        # Prevent users from changing their own role
        if user_id == current_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot change your own role"
            )

        old_role_name = user_org.role.name

        # Update role
        user_org.role_id = new_role.id

        # Log audit event
        audit_log = AuditLog(
            user_id=current_user_id,
            organization_id=organization_id,
            action=AUDIT_ACTION_ROLE_CHANGED,
            entity_type=ENTITY_TYPE_USER_ORG,
            entity_id=user_org.id,
            details={
                "target_user_id": str(user_id),
                "username": user_org.user.username,
                "old_role": old_role_name,
                "new_role": new_role.name
            }
        )

        self.db.add(audit_log)
        self.db.commit()
        self.db.refresh(user_org)

        return {
            "success": True,
            "message": f"Role updated successfully",
            "user_id": str(user_id),
            "username": user_org.user.username,
            "old_role": old_role_name,
            "new_role": new_role.name
        }

    def remove_user(
        self,
        organization_id: str,
        current_user_id: str,
        user_id: str
    ) -> dict:
        """
        Remove a user from the organization.

        Args:
            organization_id: Organization ID
            current_user_id: Current user ID (must be owner/admin)
            user_id: User ID to remove

        Returns:
            Removal confirmation
        """
        # Check if current user is owner or admin
        current_user_org = self._check_organization_access(
            current_user_id,
            organization_id,
            required_roles=['owner', 'admin']
        )

        # Get the user-organization relationship
        user_org = self.db.query(UserOrganization).options(
            joinedload(UserOrganization.user),
            joinedload(UserOrganization.role)
        ).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == organization_id
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found in organization"
            )

        # Prevent removing owner unless current user is owner
        if user_org.role.role_key == 'owner' and current_user_org.role.role_key != 'owner':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only owners can remove other owners"
            )

        # Prevent users from removing themselves
        if user_id == current_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot remove yourself. Transfer ownership first or delete the organization."
            )

        username = user_org.user.username if user_org.user else "Unknown"

        # Log audit event before deletion
        audit_log = AuditLog(
            user_id=current_user_id,
            organization_id=organization_id,
            action=AUDIT_ACTION_USER_REMOVED,
            entity_type=ENTITY_TYPE_USER_ORG,
            entity_id=user_org.id,
            details={
                "removed_user_id": str(user_id),
                "username": username,
                "role": user_org.role.name
            }
        )

        self.db.add(audit_log)

        # Delete the relationship
        self.db.delete(user_org)
        self.db.commit()

        return {
            "success": True,
            "message": f"User {username} removed from organization",
            "user_id": str(user_id)
        }
