"""
API Dependencies
Authentication and authorization dependencies for API endpoints
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models.user import User
from app.models.user_organization import UserOrganization
from app.core.security import decode_access_token


# HTTP Bearer token security scheme
security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency to get the current authenticated user from JWT token.

    Args:
        credentials: HTTP Authorization credentials with Bearer token
        db: Database session

    Returns:
        User object of the authenticated user

    Raises:
        HTTPException: If token is invalid or user not found
    """
    token = credentials.credentials

    # Decode JWT token
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Extract user ID from token
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Get user from database
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"}
        )

    # Check if user is active
    if not user.can_login():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is not active or locked"
        )

    return user


def get_current_organization(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> str:
    """
    Dependency to get the current user's active organization ID.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        Organization ID (UUID as string)

    Raises:
        HTTPException: If user has no active organization
    """
    # Get user's active organization
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    if not user_org or not user_org.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User must be associated with an active organization"
        )

    return str(user_org.organization_id)


def get_current_user_role(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> str:
    """
    Dependency to get the current user's role in their organization.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        Role key (e.g., 'owner', 'admin', 'manager')

    Raises:
        HTTPException: If user has no active organization or role
    """
    # Get user's active organization with role
    user_org = db.query(UserOrganization).filter(
        UserOrganization.user_id == current_user.id,
        UserOrganization.status == 'active'
    ).first()

    if not user_org:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User must be associated with an active organization"
        )

    # Get role information
    from app.models.role import Role
    role = db.query(Role).filter(Role.id == user_org.role_id).first()

    if not role:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="User role not found"
        )

    return role.role_key


def require_owner_or_admin(
    role: str = Depends(get_current_user_role)
) -> bool:
    """
    Dependency to require owner or admin role.

    Args:
        role: Current user's role

    Returns:
        True if user is owner or admin

    Raises:
        HTTPException: If user doesn't have required role
    """
    if role not in ['owner', 'admin']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions. Owner or Admin role required."
        )

    return True


def get_optional_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    Dependency to optionally get the current user (allows anonymous access).

    Args:
        credentials: Optional HTTP Authorization credentials
        db: Database session

    Returns:
        User object if authenticated, None otherwise
    """
    if not credentials:
        return None

    try:
        return get_current_user(credentials, db)
    except HTTPException:
        return None
