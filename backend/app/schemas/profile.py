"""
Profile Schemas
Pydantic models for profile completion and management
"""

from pydantic import BaseModel, Field
from typing import Optional


class ProfileCompletionRequest(BaseModel):
    """Profile completion request - user selects their role"""
    # Role Selection Type: 'driver', 'independent', 'join_company', 'create_company'
    role_type: str = Field(..., pattern="^(driver|independent|join_company|create_company)$")

    # For driver role
    license_number: Optional[str] = Field(None, min_length=5, max_length=50)
    license_expiry: Optional[str] = None  # ISO date string

    # For joining existing company
    company_id: Optional[str] = None  # UUID

    # For creating new company
    company_name: Optional[str] = Field(None, min_length=2, max_length=255)
    business_type: Optional[str] = Field(None, min_length=2, max_length=50)
    business_email: Optional[str] = None
    business_phone: Optional[str] = Field(None, min_length=10, max_length=20)
    address: Optional[str] = Field(None, min_length=5, max_length=500)
    city: Optional[str] = Field(None, min_length=2, max_length=100)
    state: Optional[str] = Field(None, min_length=2, max_length=100)
    pincode: Optional[str] = Field(None, min_length=6, max_length=10)
    country: Optional[str] = Field(default="India", max_length=100)


class ProfileCompletionResponse(BaseModel):
    """Profile completion response"""
    success: bool
    message: str
    user_id: str
    role: str
    role_type: str
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    driver_id: Optional[str] = None


class ProfileUpdateRequest(BaseModel):
    """Profile update request - editable fields only"""
    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    email: Optional[str] = Field(None, min_length=5, max_length=255)
    phone: Optional[str] = Field(None, min_length=10, max_length=20)


class ProfileStatusResponse(BaseModel):
    """Profile status response"""
    success: bool
    profile_completed: bool
    user_id: str
    username: str
    full_name: str
    email: Optional[str]
    phone: str
    role: Optional[str] = None
    role_type: Optional[str] = None
    company_id: Optional[str] = None
    company_name: Optional[str] = None
