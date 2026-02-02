"""
Driver Schemas
Pydantic models for driver endpoints
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import date, datetime
import re


class DriverLicenseCreate(BaseModel):
    """Driver license information for creation"""
    license_number: str = Field(..., min_length=10, max_length=50)
    license_type: str = Field(..., description="LMV, HMV, MCWG, or HPMV")
    issue_date: date
    expiry_date: date
    issuing_authority: Optional[str] = Field(None, max_length=255)
    issuing_state: Optional[str] = Field(None, max_length=100)

    @field_validator('license_number')
    @classmethod
    def validate_license_number(cls, v):
        """Validate license number format (alphanumeric with hyphens)"""
        if not re.match(r'^[A-Z0-9\-]{10,50}$', v):
            raise ValueError('License number must be 10-50 alphanumeric characters (uppercase) with optional hyphens')
        return v

    @field_validator('license_type')
    @classmethod
    def validate_license_type(cls, v):
        """Validate license type"""
        valid_types = ['LMV', 'HMV', 'MCWG', 'HPMV']
        if v not in valid_types:
            raise ValueError(f'License type must be one of: {", ".join(valid_types)}')
        return v

    @field_validator('expiry_date')
    @classmethod
    def validate_expiry_date(cls, v, info):
        """Validate expiry date is after issue date and in future"""
        issue_date = info.data.get('issue_date')
        if issue_date and v <= issue_date:
            raise ValueError('Expiry date must be after issue date')
        if v < date.today():
            raise ValueError('License expiry date must be in the future')
        return v


class DriverLicenseUpdate(BaseModel):
    """Driver license information for updates"""
    license_number: Optional[str] = Field(None, min_length=10, max_length=50)
    license_type: Optional[str] = None
    issue_date: Optional[date] = None
    expiry_date: Optional[date] = None
    issuing_authority: Optional[str] = Field(None, max_length=255)
    issuing_state: Optional[str] = Field(None, max_length=100)

    @field_validator('license_number')
    @classmethod
    def validate_license_number(cls, v):
        if v and not re.match(r'^[A-Z0-9\-]{10,50}$', v):
            raise ValueError('License number must be 10-50 alphanumeric characters (uppercase) with optional hyphens')
        return v

    @field_validator('license_type')
    @classmethod
    def validate_license_type(cls, v):
        if v:
            valid_types = ['LMV', 'HMV', 'MCWG', 'HPMV']
            if v not in valid_types:
                raise ValueError(f'License type must be one of: {", ".join(valid_types)}')
        return v


class DriverCreateRequest(BaseModel):
    """Create new driver request"""
    # User Account Information (for driver login)
    username: str = Field(..., min_length=3, max_length=50, description="Username for driver login")
    password: str = Field(..., min_length=8, description="Password for driver login (min 8 characters)")

    # Employment Information
    employee_id: str = Field(..., min_length=3, max_length=50)
    join_date: date

    # Basic Information
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: str = Field(..., min_length=10, max_length=20)
    date_of_birth: Optional[date] = None

    # Address Information
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    pincode: Optional[str] = Field(None, min_length=6, max_length=6)
    country: str = Field(default="India", max_length=100)

    # Emergency Contact
    emergency_contact_name: Optional[str] = Field(None, max_length=255)
    emergency_contact_phone: Optional[str] = Field(None, min_length=10, max_length=20)
    emergency_contact_relationship: Optional[str] = Field(None, max_length=50)

    # License Information (embedded)
    license: DriverLicenseCreate

    @field_validator('username')
    @classmethod
    def validate_username(cls, v):
        """Validate username format (alphanumeric with underscores)"""
        if not re.match(r'^[a-zA-Z0-9_]{3,50}$', v):
            raise ValueError('Username must be 3-50 alphanumeric characters (letters, numbers, underscores only)')
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        """Validate password strength"""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        return v

    @field_validator('employee_id')
    @classmethod
    def validate_employee_id(cls, v):
        """Validate employee ID format (alphanumeric with hyphens)"""
        if not re.match(r'^[A-Za-z0-9\-]{3,50}$', v):
            raise ValueError('Employee ID must be 3-50 alphanumeric characters with optional hyphens')
        return v

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        """Validate phone number (10 digits)"""
        if not re.match(r'^\d{10}$', v):
            raise ValueError('Phone number must be exactly 10 digits')
        return v

    @field_validator('pincode')
    @classmethod
    def validate_pincode(cls, v):
        """Validate pincode (6 digits)"""
        if v and not re.match(r'^\d{6}$', v):
            raise ValueError('Pincode must be exactly 6 digits')
        return v

    @field_validator('emergency_contact_phone')
    @classmethod
    def validate_emergency_phone(cls, v):
        """Validate emergency contact phone (10 digits)"""
        if v and not re.match(r'^\d{10}$', v):
            raise ValueError('Emergency contact phone must be exactly 10 digits')
        return v

    @field_validator('join_date')
    @classmethod
    def validate_join_date(cls, v):
        """Validate join date is not in future"""
        if v > date.today():
            raise ValueError('Join date cannot be in the future')
        return v


class DriverUpdateRequest(BaseModel):
    """Update driver request (all fields optional)"""
    # Employment Information
    employee_id: Optional[str] = Field(None, min_length=3, max_length=50)
    join_date: Optional[date] = None
    status: Optional[str] = None

    # Basic Information
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, min_length=10, max_length=20)
    date_of_birth: Optional[date] = None

    # Address Information
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    pincode: Optional[str] = Field(None, min_length=6, max_length=6)
    country: Optional[str] = Field(None, max_length=100)

    # Emergency Contact
    emergency_contact_name: Optional[str] = Field(None, max_length=255)
    emergency_contact_phone: Optional[str] = Field(None, min_length=10, max_length=20)
    emergency_contact_relationship: Optional[str] = Field(None, max_length=50)

    # License Information (embedded, optional)
    license: Optional[DriverLicenseUpdate] = None

    @field_validator('employee_id')
    @classmethod
    def validate_employee_id(cls, v):
        if v and not re.match(r'^[A-Za-z0-9\-]{3,50}$', v):
            raise ValueError('Employee ID must be 3-50 alphanumeric characters with optional hyphens')
        return v

    @field_validator('phone')
    @classmethod
    def validate_phone(cls, v):
        if v and not re.match(r'^\d{10}$', v):
            raise ValueError('Phone number must be exactly 10 digits')
        return v

    @field_validator('pincode')
    @classmethod
    def validate_pincode(cls, v):
        if v and not re.match(r'^\d{6}$', v):
            raise ValueError('Pincode must be exactly 6 digits')
        return v

    @field_validator('emergency_contact_phone')
    @classmethod
    def validate_emergency_phone(cls, v):
        if v and not re.match(r'^\d{10}$', v):
            raise ValueError('Emergency contact phone must be exactly 10 digits')
        return v

    @field_validator('status')
    @classmethod
    def validate_status(cls, v):
        if v:
            valid_statuses = ['active', 'inactive', 'on_leave', 'terminated']
            if v not in valid_statuses:
                raise ValueError(f'Status must be one of: {", ".join(valid_statuses)}')
        return v


class DriverLicenseResponse(BaseModel):
    """Driver license response"""
    license_number: str
    license_type: str
    issue_date: date
    expiry_date: date
    issuing_authority: Optional[str]
    issuing_state: Optional[str]

    class Config:
        from_attributes = True


class DriverResponse(BaseModel):
    """Driver details response"""
    driver_id: str
    organization_id: str
    employee_id: str
    join_date: date
    status: str

    # Basic Information
    first_name: str
    last_name: str
    full_name: str  # Computed property
    email: Optional[str]
    phone: str
    date_of_birth: Optional[date]

    # Address Information
    address: Optional[str]
    city: Optional[str]
    state: Optional[str]
    pincode: Optional[str]
    country: str

    # Emergency Contact
    emergency_contact_name: Optional[str]
    emergency_contact_phone: Optional[str]
    emergency_contact_relationship: Optional[str]

    # License Information
    license: Optional[DriverLicenseResponse]

    # Timestamps
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DriverListResponse(BaseModel):
    """Paginated driver list response"""
    success: bool
    drivers: List[DriverResponse]
    total: int
    skip: int
    limit: int
