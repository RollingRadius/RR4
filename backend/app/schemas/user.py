"""
User Schemas
Pydantic models for user-related endpoints
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserBase(BaseModel):
    """Base user information"""
    username: str
    full_name: str
    email: Optional[str]
    phone: str
    auth_method: str


class UserResponse(BaseModel):
    """User details response"""
    user_id: str
    username: str
    full_name: str
    email: Optional[str]
    phone: str
    auth_method: str
    status: str
    email_verified: bool
    created_at: datetime
    last_login: Optional[datetime]


class UserProfileResponse(BaseModel):
    """User profile with company information"""
    user_id: str
    username: str
    full_name: str
    email: Optional[str]
    phone: str
    auth_method: str
    status: str
    company_id: Optional[str]
    company_name: Optional[str]
    role: Optional[str]
    created_at: datetime
    last_login: Optional[datetime]
