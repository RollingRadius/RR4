"""
Company Schemas
Pydantic models for company/organization endpoints
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import date

from app.utils.validators import validate_gstin, validate_pan, validate_pincode


class CompanySearchResult(BaseModel):
    """Single company search result"""
    company_id: str
    company_name: str
    city: str
    state: str
    business_type: str


class CompanySearchResponse(BaseModel):
    """Company search response"""
    success: bool
    companies: List[CompanySearchResult]
    count: int
    query: str
    has_more: bool = False


class CompanyValidationRequest(BaseModel):
    """Validate company details (GSTIN, PAN, etc.)"""
    gstin: Optional[str] = Field(None, min_length=15, max_length=15)
    pan_number: Optional[str] = Field(None, min_length=10, max_length=10)
    registration_number: Optional[str] = None

    @field_validator('gstin')
    @classmethod
    def validate_gstin_format(cls, v):
        if v:
            is_valid, error = validate_gstin(v)
            if not is_valid:
                raise ValueError(error)
        return v

    @field_validator('pan_number')
    @classmethod
    def validate_pan_format(cls, v):
        if v:
            is_valid, error = validate_pan(v)
            if not is_valid:
                raise ValueError(error)
        return v


class CompanyValidationResponse(BaseModel):
    """Company validation response"""
    success: bool
    valid: bool
    message: str
    validation: dict


class CompanyCreateRequest(BaseModel):
    """Create new company request"""
    company_name: str = Field(..., min_length=2, max_length=255)
    business_type: str = Field(..., min_length=2, max_length=50)

    # Legal Information (Optional)
    gstin: Optional[str] = Field(None, min_length=15, max_length=15)
    pan_number: Optional[str] = Field(None, min_length=10, max_length=10)
    registration_number: Optional[str] = Field(None, max_length=100)
    registration_date: Optional[date] = None

    # Contact Information
    business_email: EmailStr
    business_phone: str = Field(..., min_length=10, max_length=20)

    # Address
    address: str = Field(..., min_length=5, max_length=500)
    city: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    pincode: str = Field(..., min_length=6, max_length=10)
    country: str = Field(default="India", max_length=100)

    @field_validator('gstin')
    @classmethod
    def validate_gstin_format(cls, v):
        if v:
            is_valid, error = validate_gstin(v)
            if not is_valid:
                raise ValueError(error)
        return v

    @field_validator('pan_number')
    @classmethod
    def validate_pan_format(cls, v):
        if v:
            is_valid, error = validate_pan(v)
            if not is_valid:
                raise ValueError(error)
        return v

    @field_validator('pincode')
    @classmethod
    def validate_pincode_format(cls, v):
        is_valid, error = validate_pincode(v)
        if not is_valid:
            raise ValueError(error)
        return v


class CompanyResponse(BaseModel):
    """Company details response"""
    company_id: str
    company_name: str
    business_type: str
    gstin: Optional[str]
    pan_number: Optional[str]
    business_email: str
    business_phone: str
    city: str
    state: str
    country: str
    status: str


class CompanyJoinRequest(BaseModel):
    """Join existing company request"""
    company_id: str = Field(..., description="UUID of the company to join")


class CompanyJoinResponse(BaseModel):
    """Company join response"""
    success: bool
    message: str
    company_id: str
    company_name: str
    role: str
    status: str
