"""
Vehicle Management API Endpoints
Handles all vehicle-related operations including CRUD, driver assignment, and document management.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.vehicle_service import VehicleService
from app.schemas.vehicle import (
    VehicleCreateRequest,
    VehicleUpdateRequest,
    VehicleResponse,
    VehicleListResponse,
    VehicleAssignDriverRequest,
    VehicleUnassignDriverRequest,
    VehicleExpiringDocsResponse
)
from app.core.permissions import (
    require_capability,
    AccessLevel,
    require_vehicle_create,
    require_vehicle_edit,
    require_vehicle_view
)


router = APIRouter()


@router.post(
    "",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new vehicle",
    description="Create a new vehicle in the fleet. Requires vehicle.create capability."
)
async def create_vehicle(
    vehicle_data: VehicleCreateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_vehicle_create)
):
    """
    Create a new vehicle.

    Required capability: vehicle.create (FULL access)

    **Request Body:**
    - vehicle_number: Internal vehicle number (unique within organization)
    - registration_number: Official registration number (globally unique)
    - manufacturer: Vehicle manufacturer/brand
    - model: Vehicle model
    - year: Manufacturing year (1900-current year +1)
    - vehicle_type: Type of vehicle (truck, bus, van, car, motorcycle, other)
    - fuel_type: Fuel type (petrol, diesel, electric, hybrid, cng, lpg)
    - capacity: Passenger or cargo capacity (optional)
    - color: Vehicle color (optional)
    - vin_number: 17-character VIN (optional, globally unique)
    - engine_number: Engine number (optional)
    - chassis_number: Chassis number (optional)
    - purchase_date: Purchase date (optional)
    - purchase_price: Purchase price (optional)
    - current_odometer: Current odometer reading in km (default: 0)
    - insurance details (optional)
    - compliance certificate expiry dates (optional)
    - notes: Additional notes (optional)

    **Returns:**
    - success: True if created successfully
    - message: Success message
    - vehicle_id: ID of created vehicle
    - vehicle_name: Formatted vehicle name

    **Errors:**
    - 400: Duplicate vehicle number, registration number, or VIN
    - 404: Organization not found
    """
    service = VehicleService(db)
    result = service.create_vehicle(
        user_id=current_user.id,
        org_id=uuid.UUID(org_id),
        vehicle_data=vehicle_data
    )
    return result


@router.get(
    "",
    response_model=VehicleListResponse,
    summary="Get list of vehicles",
    description="Get paginated list of vehicles with optional filters. Requires vehicle.view capability."
)
async def get_vehicles(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(20, ge=1, le=100, description="Number of records to return"),
    status: Optional[str] = Query(None, description="Filter by status (active, inactive, maintenance, decommissioned)"),
    vehicle_type: Optional[str] = Query(None, description="Filter by vehicle type"),
    fuel_type: Optional[str] = Query(None, description="Filter by fuel type"),
    search: Optional[str] = Query(None, description="Search in vehicle number, registration, manufacturer, or model"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_vehicle_view)
):
    """
    Get paginated list of vehicles.

    Required capability: vehicle.view (VIEW or higher access)

    **Query Parameters:**
    - skip: Number of records to skip (default: 0)
    - limit: Number of records to return (default: 20, max: 100)
    - status: Filter by vehicle status (active, inactive, maintenance, decommissioned)
    - vehicle_type: Filter by vehicle type (truck, bus, van, car, motorcycle, other)
    - fuel_type: Filter by fuel type (petrol, diesel, electric, hybrid, cng, lpg)
    - search: Search term (searches in vehicle number, registration number, manufacturer, model)

    **Returns:**
    - success: True
    - vehicles: List of vehicle objects with driver and document info
    - total: Total number of vehicles matching filters
    - skip: Number of records skipped
    - limit: Number of records returned

    **Vehicle Object Fields:**
    - Basic info: id, vehicle_number, registration_number, manufacturer, model, year
    - Type info: vehicle_type, fuel_type, capacity, color
    - Identification: vin_number, engine_number, chassis_number
    - Financial: purchase_date, purchase_price
    - Assignment: current_driver_id, current_driver_name
    - Operational: current_odometer, status
    - Compliance: insurance details, certificate expiry dates
    - Metadata: document_count, has_expiring_docs, created_at, updated_at
    """
    service = VehicleService(db)
    result = service.get_vehicles_by_organization(
        org_id=uuid.UUID(org_id),
        skip=skip,
        limit=limit,
        status_filter=status,
        vehicle_type_filter=vehicle_type,
        fuel_type_filter=fuel_type,
        search=search
    )
    return result


@router.get(
    "/{vehicle_id}",
    response_model=VehicleResponse,
    summary="Get vehicle details",
    description="Get detailed information about a specific vehicle. Requires vehicle.view capability."
)
async def get_vehicle(
    vehicle_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_vehicle_view)
):
    """
    Get vehicle details by ID.

    Required capability: vehicle.view (VIEW or higher access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle

    **Returns:**
    Complete vehicle information including:
    - All basic vehicle details
    - Current driver assignment (if any)
    - Document count and expiry status
    - Insurance and compliance information
    - Audit trail (created_at, updated_at, created_by)

    **Errors:**
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    vehicle = service.get_vehicle_by_id(vehicle_id=vehicle_id, org_id=uuid.UUID(org_id))

    # Convert to response format
    vehicle_dict = vehicle.to_dict()
    vehicle_dict["current_driver_name"] = vehicle.current_driver.full_name if vehicle.current_driver else None
    vehicle_dict["document_count"] = len(vehicle.documents)
    vehicle_dict["has_expiring_docs"] = vehicle.needs_maintenance()

    return vehicle_dict


@router.put(
    "/{vehicle_id}",
    response_model=dict,
    summary="Update vehicle",
    description="Update vehicle information. Requires vehicle.edit capability."
)
async def update_vehicle(
    vehicle_id: uuid.UUID,
    update_data: VehicleUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_vehicle_edit)
):
    """
    Update vehicle information.

    Required capability: vehicle.edit (FULL access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle to update

    **Request Body:**
    All fields are optional. Only provided fields will be updated.
    - vehicle_number: Internal vehicle number
    - registration_number: Official registration number
    - manufacturer, model, year
    - vehicle_type, fuel_type, capacity, color
    - vin_number, engine_number, chassis_number
    - purchase_date, purchase_price
    - current_odometer: Current odometer reading
    - status: Vehicle status (active, inactive, maintenance, decommissioned)
    - insurance details
    - compliance certificate expiry dates
    - notes

    **Returns:**
    - success: True if updated successfully
    - message: Success message
    - vehicle_id: ID of updated vehicle

    **Errors:**
    - 400: Duplicate vehicle number, registration number, or VIN
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    result = service.update_vehicle(
        vehicle_id=vehicle_id,
        org_id=uuid.UUID(org_id),
        user_id=current_user.id,
        update_data=update_data
    )
    return result


@router.delete(
    "/{vehicle_id}",
    response_model=dict,
    summary="Delete vehicle",
    description="Soft delete a vehicle (sets status to decommissioned). Requires vehicle.delete capability."
)
async def delete_vehicle(
    vehicle_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("vehicle.delete", AccessLevel.FULL))
):
    """
    Delete (decommission) a vehicle.

    Required capability: vehicle.delete (FULL access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle to delete

    **Behavior:**
    - Performs soft delete (sets status to 'decommissioned')
    - Unassigns any currently assigned driver
    - Preserves all vehicle data for audit purposes
    - Vehicle documents are retained

    **Returns:**
    - success: True if deleted successfully
    - message: Success message

    **Errors:**
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    result = service.delete_vehicle(
        vehicle_id=vehicle_id,
        org_id=uuid.UUID(org_id),
        user_id=current_user.id
    )
    return result


@router.post(
    "/{vehicle_id}/assign-driver",
    response_model=dict,
    summary="Assign driver to vehicle",
    description="Assign a driver to a vehicle. Requires vehicle.assign capability."
)
async def assign_driver_to_vehicle(
    vehicle_id: uuid.UUID,
    assignment_data: VehicleAssignDriverRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("vehicle.assign", AccessLevel.FULL))
):
    """
    Assign a driver to a vehicle.

    Required capability: vehicle.assign (FULL access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle

    **Request Body:**
    - driver_id: UUID of the driver to assign
    - assignment_date: Date of assignment (default: today)
    - notes: Optional notes about the assignment

    **Behavior:**
    - Validates driver exists and belongs to same organization
    - Validates driver is in active status
    - Unassigns previous driver if any
    - Assigns new driver to vehicle
    - Logs assignment in audit trail

    **Returns:**
    - success: True if assigned successfully
    - message: Success message with driver and vehicle names
    - vehicle_id: ID of vehicle
    - driver_id: ID of driver

    **Errors:**
    - 400: Driver not in active status
    - 404: Vehicle or driver not found, or driver not in organization
    """
    service = VehicleService(db)
    driver_id = uuid.UUID(assignment_data.driver_id)

    result = service.assign_driver(
        vehicle_id=vehicle_id,
        driver_id=driver_id,
        org_id=uuid.UUID(org_id),
        user_id=current_user.id,
        assignment_data=assignment_data
    )
    return result


@router.post(
    "/{vehicle_id}/unassign-driver",
    response_model=dict,
    summary="Remove driver assignment from vehicle",
    description="Unassign driver from a vehicle. Requires vehicle.assign capability."
)
async def unassign_driver_from_vehicle(
    vehicle_id: uuid.UUID,
    unassign_data: VehicleUnassignDriverRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("vehicle.assign", AccessLevel.FULL))
):
    """
    Remove driver assignment from a vehicle.

    Required capability: vehicle.assign (FULL access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle

    **Request Body:**
    - notes: Optional notes about the unassignment

    **Returns:**
    - success: True if unassigned successfully
    - message: Success message
    - vehicle_id: ID of vehicle

    **Errors:**
    - 400: No driver currently assigned to vehicle
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    result = service.unassign_driver(
        vehicle_id=vehicle_id,
        org_id=uuid.UUID(org_id),
        user_id=current_user.id,
        notes=unassign_data.notes
    )
    return result


@router.get(
    "/{vehicle_id}/expiring-docs",
    response_model=VehicleExpiringDocsResponse,
    summary="Get expiring documents for vehicle",
    description="Get list of expiring documents and certificates. Requires vehicle.view capability."
)
async def get_expiring_documents(
    vehicle_id: uuid.UUID,
    days: int = Query(30, ge=1, le=365, description="Number of days to look ahead for expiry"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_vehicle_view)
):
    """
    Get expiring documents and certificates for a vehicle.

    Required capability: vehicle.view (VIEW or higher access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle

    **Query Parameters:**
    - days: Number of days to look ahead (default: 30, max: 365)

    **Returns:**
    - success: True
    - vehicle_id: ID of vehicle
    - vehicle_name: Formatted vehicle name
    - expiring_documents: List of expiring documents
    - total_expiring: Count of expiring documents

    **Expiring Document Object:**
    - type: Document type (insurance, registration, pollution_certificate, fitness_certificate)
    - expiry_date: Date when document expires
    - days_remaining: Days until expiry (negative if already expired)
    - is_expired: Boolean flag indicating if already expired

    **Errors:**
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    result = service.get_expiring_documents(
        vehicle_id=vehicle_id,
        org_id=uuid.UUID(org_id),
        days=days
    )
    return result


@router.post(
    "/{vehicle_id}/archive",
    response_model=dict,
    summary="Archive vehicle",
    description="Archive a vehicle (sets status to decommissioned). Requires vehicle.archive capability."
)
async def archive_vehicle(
    vehicle_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("vehicle.archive", AccessLevel.FULL))
):
    """
    Archive a vehicle.

    Required capability: vehicle.archive (FULL access)

    **Path Parameters:**
    - vehicle_id: UUID of the vehicle to archive

    **Behavior:**
    - Same as delete operation (soft delete)
    - Sets status to 'decommissioned'
    - Unassigns driver if any
    - Preserves all data for audit purposes

    **Returns:**
    - success: True if archived successfully
    - message: Success message

    **Errors:**
    - 404: Vehicle not found or belongs to different organization
    """
    service = VehicleService(db)
    result = service.archive_vehicle(
        vehicle_id=vehicle_id,
        org_id=uuid.UUID(org_id),
        user_id=current_user.id
    )
    return result
