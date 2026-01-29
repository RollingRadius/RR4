"""
Role Schemas
Request/Response schemas for role management
"""

from pydantic import BaseModel, Field
from typing import List, Optional


class RoleResponse(BaseModel):
    """Role information response"""
    id: str
    role_name: str
    role_key: str
    description: Optional[str] = None
    is_system_role: bool
    is_custom_role: bool = False

    class Config:
        from_attributes = True


class RoleListResponse(BaseModel):
    """List of available roles"""
    success: bool = True
    roles: List[RoleResponse]
    count: int


class RoleRequestCreate(BaseModel):
    """Create role request when joining company"""
    requested_role_id: str = Field(..., description="Role ID that user wants to be assigned")


class RoleApprovalRequest(BaseModel):
    """Approve or modify role request"""
    approved_role_id: Optional[str] = Field(None, description="Role ID to assign (if different from requested)")


class PendingRoleRequest(BaseModel):
    """Pending role request information"""
    user_organization_id: str
    user_id: str
    user_name: str
    username: str
    email: Optional[str]
    phone: Optional[str]
    joined_at: str
    current_role: dict
    requested_role: Optional[dict] = None
