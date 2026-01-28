"""
Driver Management API Endpoints
Driver CRUD operations for fleet management
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.schemas.driver import (
    DriverCreateRequest,
    DriverUpdateRequest,
    DriverResponse,
    DriverListResponse
)
from app.services.driver_service import DriverService


router = APIRouter()


@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_driver(
    driver_data: DriverCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Create a new driver with license information.

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership
    - Driver basic information (name, employee ID, phone, join date)
    - Driver license information (number, type, dates)

    **Optional:**
    - Email, date of birth
    - Address information
    - Emergency contact details

    **Validations:**
    - Employee ID must be unique within organization
    - Email must be unique globally (if provided)
    - License number must be unique globally
    - License expiry date must be in the future
    - Phone numbers must be 10 digits
    - Pincode must be 6 digits (if provided)

    **License Types:**
    - LMV: Light Motor Vehicle (cars, jeeps, small vans)
    - HMV: Heavy Motor Vehicle (trucks, buses)
    - MCWG: Motorcycle with Gear
    - HPMV: Heavy Passenger Motor Vehicle (large buses)

    **Returns:**
    - Success confirmation
    - Driver ID, name, and employee ID

    **Example:**
    ```json
    {
      "employee_id": "DRV001",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "9876543210",
      "join_date": "2024-01-15",
      "license": {
        "license_number": "DL1420110012345",
        "license_type": "LMV",
        "issue_date": "2020-01-01",
        "expiry_date": "2040-01-01",
        "issuing_state": "Karnataka"
      }
    }
    ```
    """
    driver_service = DriverService(db)

    # Convert Pydantic model to dict
    driver_dict = driver_data.model_dump()

    result = driver_service.create_driver(
        user_id=str(current_user.id),
        org_id=org_id,
        driver_data=driver_dict
    )

    return result


@router.get("", response_model=DriverListResponse)
async def get_drivers(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(50, ge=1, le=100, description="Maximum records to return"),
    status: Optional[str] = Query(None, description="Filter by status (active/inactive/on_leave/terminated)"),
    org_id: str = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get paginated list of drivers for the organization.

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership

    **Query Parameters:**
    - skip: Number of records to skip (default: 0)
    - limit: Maximum records to return (default: 50, max: 100)
    - status: Filter by driver status (optional)

    **Status Values:**
    - active: Currently employed drivers
    - inactive: Temporarily inactive drivers
    - on_leave: Drivers on leave
    - terminated: Former drivers (soft deleted)

    **Returns:**
    - List of drivers with full information
    - License information for each driver
    - Total count and pagination info

    **Example Response:**
    ```json
    {
      "success": true,
      "drivers": [...],
      "total": 25,
      "skip": 0,
      "limit": 50
    }
    ```
    """
    driver_service = DriverService(db)

    result = driver_service.get_drivers_by_organization(
        org_id=org_id,
        skip=skip,
        limit=limit,
        status_filter=status
    )

    # Convert Driver models to response schemas
    driver_responses = []
    for driver in result['drivers']:
        driver_response = DriverResponse(
            driver_id=str(driver.id),
            organization_id=str(driver.organization_id),
            employee_id=driver.employee_id,
            join_date=driver.join_date,
            status=driver.status,
            first_name=driver.first_name,
            last_name=driver.last_name,
            full_name=driver.full_name,
            email=driver.email,
            phone=driver.phone,
            date_of_birth=driver.date_of_birth,
            address=driver.address,
            city=driver.city,
            state=driver.state,
            pincode=driver.pincode,
            country=driver.country,
            emergency_contact_name=driver.emergency_contact_name,
            emergency_contact_phone=driver.emergency_contact_phone,
            emergency_contact_relationship=driver.emergency_contact_relationship,
            license=driver.license,
            created_at=driver.created_at,
            updated_at=driver.updated_at
        )
        driver_responses.append(driver_response)

    return DriverListResponse(
        success=result['success'],
        drivers=driver_responses,
        total=result['total'],
        skip=result['skip'],
        limit=result['limit']
    )


@router.get("/{driver_id}", response_model=DriverResponse)
async def get_driver_details(
    driver_id: str,
    org_id: str = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get detailed information for a specific driver.

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership
    - Driver must belong to user's organization

    **Returns:**
    - Full driver information
    - License details
    - Emergency contact information
    - Created and updated timestamps

    **Example:**
    ```
    GET /api/drivers/{driver_id}
    ```
    """
    driver_service = DriverService(db)

    driver = driver_service.get_driver_by_id(driver_id, org_id)

    return DriverResponse(
        driver_id=str(driver.id),
        organization_id=str(driver.organization_id),
        employee_id=driver.employee_id,
        join_date=driver.join_date,
        status=driver.status,
        first_name=driver.first_name,
        last_name=driver.last_name,
        full_name=driver.full_name,
        email=driver.email,
        phone=driver.phone,
        date_of_birth=driver.date_of_birth,
        address=driver.address,
        city=driver.city,
        state=driver.state,
        pincode=driver.pincode,
        country=driver.country,
        emergency_contact_name=driver.emergency_contact_name,
        emergency_contact_phone=driver.emergency_contact_phone,
        emergency_contact_relationship=driver.emergency_contact_relationship,
        license=driver.license,
        created_at=driver.created_at,
        updated_at=driver.updated_at
    )


@router.put("/{driver_id}", response_model=dict)
async def update_driver(
    driver_id: str,
    update_data: DriverUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Update driver information.

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership
    - Driver must belong to user's organization

    **Updateable Fields:**
    - Employee ID (must remain unique in organization)
    - Name, email, phone
    - Address information
    - Emergency contact details
    - License information
    - Status (active/inactive/on_leave)

    **Note:**
    - All fields are optional
    - Only provided fields will be updated
    - Email and license number uniqueness is enforced

    **Returns:**
    - Success confirmation
    - Updated driver ID and name

    **Example:**
    ```json
    {
      "phone": "9876543210",
      "status": "active",
      "license": {
        "expiry_date": "2045-01-01"
      }
    }
    ```
    """
    driver_service = DriverService(db)

    # Convert Pydantic model to dict, excluding None values
    update_dict = update_data.model_dump(exclude_none=True)

    result = driver_service.update_driver(
        driver_id=driver_id,
        org_id=org_id,
        user_id=str(current_user.id),
        update_data=update_dict
    )

    return result


@router.delete("/{driver_id}", response_model=dict)
async def delete_driver(
    driver_id: str,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Delete a driver (soft delete - sets status to 'terminated').

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership
    - Driver must belong to user's organization

    **Note:**
    - This is a soft delete operation
    - Driver status is set to 'terminated'
    - Driver data is preserved for audit purposes
    - Driver will not appear in active listings

    **Returns:**
    - Success confirmation
    - Deleted driver ID

    **Example:**
    ```
    DELETE /api/drivers/{driver_id}
    ```
    """
    driver_service = DriverService(db)

    result = driver_service.delete_driver(
        driver_id=driver_id,
        org_id=org_id,
        user_id=str(current_user.id)
    )

    return result


@router.get("/{driver_id}/license-status", response_model=dict)
async def check_license_expiry(
    driver_id: str,
    org_id: str = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Check license expiry status for a driver.

    **Requires:**
    - Authentication (Bearer token)
    - Active organization membership
    - Driver must belong to user's organization

    **Returns:**
    - License number and expiry date
    - is_expired: Whether license is expired
    - is_expiring_soon: Whether license expires within 30 days
    - status: "expired", "expiring_soon", or "valid"

    **Use Cases:**
    - Dashboard alerts for expiring licenses
    - Driver availability checks
    - Compliance monitoring

    **Example Response:**
    ```json
    {
      "success": true,
      "license_number": "DL1420110012345",
      "expiry_date": "2040-01-01",
      "is_expired": false,
      "is_expiring_soon": false,
      "status": "valid"
    }
    ```
    """
    driver_service = DriverService(db)

    result = driver_service.validate_license_expiry(driver_id, org_id)

    return result
