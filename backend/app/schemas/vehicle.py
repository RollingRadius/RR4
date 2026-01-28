"""
Pydantic schemas for Vehicle Management API.
"""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator
import re


# ============================================================================
# Vehicle Schemas
# ============================================================================

class VehicleCreateRequest(BaseModel):
    """Schema for creating a new vehicle."""

    vehicle_number: str = Field(..., min_length=1, max_length=50, description="Internal vehicle number")
    registration_number: str = Field(..., min_length=1, max_length=50, description="Official registration number")
    manufacturer: str = Field(..., min_length=1, max_length=100, description="Vehicle manufacturer")
    model: str = Field(..., min_length=1, max_length=100, description="Vehicle model")
    year: int = Field(..., ge=1900, description="Manufacturing year")
    vehicle_type: str = Field(..., description="Type of vehicle (truck, bus, van, car, motorcycle, other)")
    fuel_type: str = Field(..., description="Fuel type (petrol, diesel, electric, hybrid, cng, lpg)")
    capacity: Optional[int] = Field(None, ge=1, description="Passenger or cargo capacity")
    color: Optional[str] = Field(None, max_length=50)
    vin_number: Optional[str] = Field(None, min_length=17, max_length=17, description="17-character VIN")
    engine_number: Optional[str] = Field(None, max_length=50)
    chassis_number: Optional[str] = Field(None, max_length=50)
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = Field(None, ge=0)
    current_odometer: int = Field(0, ge=0, description="Current odometer reading in km")

    # Insurance and compliance
    insurance_provider: Optional[str] = Field(None, max_length=255)
    insurance_policy_number: Optional[str] = Field(None, max_length=100)
    insurance_expiry_date: Optional[date] = None
    registration_expiry_date: Optional[date] = None
    pollution_certificate_expiry: Optional[date] = None
    fitness_certificate_expiry: Optional[date] = None

    notes: Optional[str] = None

    @field_validator('vehicle_number')
    @classmethod
    def validate_vehicle_number(cls, v: str) -> str:
        """Validate vehicle number format (alphanumeric and hyphens)."""
        if not re.match(r'^[A-Z0-9\-]+$', v, re.IGNORECASE):
            raise ValueError('Vehicle number must contain only letters, numbers, and hyphens')
        return v.upper()

    @field_validator('registration_number')
    @classmethod
    def validate_registration_number(cls, v: str) -> str:
        """Validate registration number format."""
        # Allow alphanumeric and hyphens for flexibility
        if not re.match(r'^[A-Z0-9\-]+$', v, re.IGNORECASE):
            raise ValueError('Registration number must contain only letters, numbers, and hyphens')
        return v.upper()

    @field_validator('year')
    @classmethod
    def validate_year(cls, v: int) -> int:
        """Validate year is not in future."""
        current_year = datetime.now().year
        if v > current_year + 1:
            raise ValueError(f'Year cannot be more than {current_year + 1}')
        return v

    @field_validator('vin_number')
    @classmethod
    def validate_vin(cls, v: Optional[str]) -> Optional[str]:
        """Validate VIN format if provided."""
        if v and len(v) != 17:
            raise ValueError('VIN must be exactly 17 characters')
        if v and not re.match(r'^[A-HJ-NPR-Z0-9]{17}$', v, re.IGNORECASE):
            raise ValueError('VIN contains invalid characters (I, O, Q not allowed)')
        return v.upper() if v else None

    @field_validator('vehicle_type')
    @classmethod
    def validate_vehicle_type(cls, v: str) -> str:
        """Validate vehicle type."""
        valid_types = ['truck', 'bus', 'van', 'car', 'motorcycle', 'other']
        if v.lower() not in valid_types:
            raise ValueError(f'Vehicle type must be one of: {", ".join(valid_types)}')
        return v.lower()

    @field_validator('fuel_type')
    @classmethod
    def validate_fuel_type(cls, v: str) -> str:
        """Validate fuel type."""
        valid_types = ['petrol', 'diesel', 'electric', 'hybrid', 'cng', 'lpg']
        if v.lower() not in valid_types:
            raise ValueError(f'Fuel type must be one of: {", ".join(valid_types)}')
        return v.lower()


class VehicleUpdateRequest(BaseModel):
    """Schema for updating a vehicle."""

    vehicle_number: Optional[str] = Field(None, min_length=1, max_length=50)
    registration_number: Optional[str] = Field(None, min_length=1, max_length=50)
    manufacturer: Optional[str] = Field(None, min_length=1, max_length=100)
    model: Optional[str] = Field(None, min_length=1, max_length=100)
    year: Optional[int] = Field(None, ge=1900)
    vehicle_type: Optional[str] = None
    fuel_type: Optional[str] = None
    capacity: Optional[int] = Field(None, ge=1)
    color: Optional[str] = Field(None, max_length=50)
    vin_number: Optional[str] = Field(None, min_length=17, max_length=17)
    engine_number: Optional[str] = Field(None, max_length=50)
    chassis_number: Optional[str] = Field(None, max_length=50)
    purchase_date: Optional[date] = None
    purchase_price: Optional[Decimal] = Field(None, ge=0)
    current_odometer: Optional[int] = Field(None, ge=0)
    status: Optional[str] = None

    # Insurance and compliance
    insurance_provider: Optional[str] = Field(None, max_length=255)
    insurance_policy_number: Optional[str] = Field(None, max_length=100)
    insurance_expiry_date: Optional[date] = None
    registration_expiry_date: Optional[date] = None
    pollution_certificate_expiry: Optional[date] = None
    fitness_certificate_expiry: Optional[date] = None

    notes: Optional[str] = None

    @field_validator('vehicle_number')
    @classmethod
    def validate_vehicle_number(cls, v: Optional[str]) -> Optional[str]:
        if v and not re.match(r'^[A-Z0-9\-]+$', v, re.IGNORECASE):
            raise ValueError('Vehicle number must contain only letters, numbers, and hyphens')
        return v.upper() if v else None

    @field_validator('registration_number')
    @classmethod
    def validate_registration_number(cls, v: Optional[str]) -> Optional[str]:
        if v and not re.match(r'^[A-Z0-9\-]+$', v, re.IGNORECASE):
            raise ValueError('Registration number must contain only letters, numbers, and hyphens')
        return v.upper() if v else None

    @field_validator('year')
    @classmethod
    def validate_year(cls, v: Optional[int]) -> Optional[int]:
        if v:
            current_year = datetime.now().year
            if v > current_year + 1:
                raise ValueError(f'Year cannot be more than {current_year + 1}')
        return v

    @field_validator('vin_number')
    @classmethod
    def validate_vin(cls, v: Optional[str]) -> Optional[str]:
        if v:
            if len(v) != 17:
                raise ValueError('VIN must be exactly 17 characters')
            if not re.match(r'^[A-HJ-NPR-Z0-9]{17}$', v, re.IGNORECASE):
                raise ValueError('VIN contains invalid characters (I, O, Q not allowed)')
        return v.upper() if v else None

    @field_validator('vehicle_type')
    @classmethod
    def validate_vehicle_type(cls, v: Optional[str]) -> Optional[str]:
        if v:
            valid_types = ['truck', 'bus', 'van', 'car', 'motorcycle', 'other']
            if v.lower() not in valid_types:
                raise ValueError(f'Vehicle type must be one of: {", ".join(valid_types)}')
        return v.lower() if v else None

    @field_validator('fuel_type')
    @classmethod
    def validate_fuel_type(cls, v: Optional[str]) -> Optional[str]:
        if v:
            valid_types = ['petrol', 'diesel', 'electric', 'hybrid', 'cng', 'lpg']
            if v.lower() not in valid_types:
                raise ValueError(f'Fuel type must be one of: {", ".join(valid_types)}')
        return v.lower() if v else None

    @field_validator('status')
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        if v:
            valid_statuses = ['active', 'inactive', 'maintenance', 'decommissioned']
            if v.lower() not in valid_statuses:
                raise ValueError(f'Status must be one of: {", ".join(valid_statuses)}')
        return v.lower() if v else None


class VehicleResponse(BaseModel):
    """Schema for vehicle response."""

    id: str
    organization_id: str
    vehicle_number: str
    registration_number: str
    manufacturer: str
    model: str
    year: int
    vehicle_type: str
    fuel_type: str
    capacity: Optional[int]
    color: Optional[str]
    vin_number: Optional[str]
    engine_number: Optional[str]
    chassis_number: Optional[str]
    purchase_date: Optional[date]
    purchase_price: Optional[Decimal]
    current_driver_id: Optional[str]
    current_driver_name: Optional[str]
    current_odometer: int
    status: str

    # Insurance and compliance
    insurance_provider: Optional[str]
    insurance_policy_number: Optional[str]
    insurance_expiry_date: Optional[date]
    registration_expiry_date: Optional[date]
    pollution_certificate_expiry: Optional[date]
    fitness_certificate_expiry: Optional[date]

    notes: Optional[str]
    document_count: int = 0
    has_expiring_docs: bool = False
    created_by: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class VehicleListResponse(BaseModel):
    """Schema for paginated vehicle list response."""

    success: bool = True
    vehicles: List[VehicleResponse]
    total: int
    skip: int
    limit: int


# ============================================================================
# Vehicle Document Schemas
# ============================================================================

class VehicleDocumentCreate(BaseModel):
    """Schema for creating a vehicle document."""

    document_type: str = Field(..., description="Type of document")
    document_name: str = Field(..., min_length=1, max_length=255)
    expiry_date: Optional[date] = None
    notes: Optional[str] = None

    @field_validator('document_type')
    @classmethod
    def validate_document_type(cls, v: str) -> str:
        valid_types = ['registration', 'insurance', 'pollution_cert', 'fitness_cert', 'permit', 'tax_receipt', 'other']
        if v.lower() not in valid_types:
            raise ValueError(f'Document type must be one of: {", ".join(valid_types)}')
        return v.lower()


class VehicleDocumentResponse(BaseModel):
    """Schema for vehicle document response."""

    id: str
    vehicle_id: str
    document_type: str
    document_name: str
    file_path: str
    file_size: int
    mime_type: str
    expiry_date: Optional[date]
    is_expired: bool
    days_until_expiry: Optional[int]
    uploaded_by: Optional[str]
    uploaded_at: datetime
    notes: Optional[str]

    model_config = {"from_attributes": True}


# ============================================================================
# Vehicle Assignment Schemas
# ============================================================================

class VehicleAssignDriverRequest(BaseModel):
    """Schema for assigning a driver to a vehicle."""

    driver_id: str = Field(..., description="Driver ID to assign")
    assignment_date: Optional[date] = Field(default_factory=date.today, description="Assignment date")
    notes: Optional[str] = Field(None, description="Assignment notes")


class VehicleUnassignDriverRequest(BaseModel):
    """Schema for unassigning a driver from a vehicle."""

    notes: Optional[str] = Field(None, description="Unassignment notes")


# ============================================================================
# Expiring Documents Schema
# ============================================================================

class ExpiringDocumentResponse(BaseModel):
    """Schema for expiring document information."""

    type: str
    expiry_date: date
    days_remaining: int
    is_expired: bool = False


class VehicleExpiringDocsResponse(BaseModel):
    """Schema for vehicle expiring documents response."""

    success: bool = True
    vehicle_id: str
    vehicle_name: str
    expiring_documents: List[ExpiringDocumentResponse]
    total_expiring: int
