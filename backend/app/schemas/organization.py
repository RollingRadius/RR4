"""
Organization Management Schemas
Pydantic models for organization member management
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class OrganizationMemberResponse(BaseModel):
    """Organization member details"""
    user_id: str
    username: str
    full_name: str
    email: Optional[str]
    phone: str
    role: str
    role_key: str
    status: str
    joined_at: datetime
    approved_at: Optional[datetime]
    is_pending: bool
    is_active: bool


class OrganizationMembersListResponse(BaseModel):
    """List of organization members"""
    success: bool
    organization_id: str
    organization_name: str
    members: List[OrganizationMemberResponse]
    active_count: int
    pending_count: int
    total_count: int


class PendingUsersResponse(BaseModel):
    """List of pending users"""
    success: bool
    organization_id: str
    organization_name: str
    pending_users: List[OrganizationMemberResponse]
    count: int


class ApproveUserRequest(BaseModel):
    """Approve a pending user"""
    user_id: str = Field(..., description="User ID to approve")
    role_key: str = Field(
        "user",
        description="Role to assign: 'admin', 'dispatcher', 'user', 'viewer'"
    )


class ApproveUserResponse(BaseModel):
    """Approve user response"""
    success: bool
    message: str
    user_id: str
    username: str
    role: str


class RejectUserRequest(BaseModel):
    """Reject a pending user"""
    user_id: str = Field(..., description="User ID to reject")
    reason: Optional[str] = Field(None, description="Optional rejection reason")


class RejectUserResponse(BaseModel):
    """Reject user response"""
    success: bool
    message: str
    user_id: str


class UpdateUserRoleRequest(BaseModel):
    """Update user role in organization"""
    user_id: str = Field(..., description="User ID")
    role_key: str = Field(
        ...,
        description="New role: 'admin', 'dispatcher', 'user', 'viewer'"
    )


class UpdateUserRoleResponse(BaseModel):
    """Update user role response"""
    success: bool
    message: str
    user_id: str
    username: str
    old_role: str
    new_role: str


class RemoveUserRequest(BaseModel):
    """Remove user from organization"""
    user_id: str = Field(..., description="User ID to remove")


class RemoveUserResponse(BaseModel):
    """Remove user response"""
    success: bool
    message: str
    user_id: str
