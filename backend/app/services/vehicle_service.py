"""
Vehicle Service
Business logic for vehicle management operations.
"""
from datetime import date, datetime
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_, func
from fastapi import HTTPException, status, UploadFile
import uuid
import os
from pathlib import Path

from app.models.vehicle import Vehicle, VehicleDocument
from app.models.driver import Driver
from app.models.company import Organization
from app.models.audit_log import AuditLog
from app.schemas.vehicle import (
    VehicleCreateRequest,
    VehicleUpdateRequest,
    VehicleAssignDriverRequest,
    VehicleDocumentCreate
)
from app.utils.constants import (
    AUDIT_ACTION_VEHICLE_CREATED,
    AUDIT_ACTION_VEHICLE_UPDATED,
    AUDIT_ACTION_VEHICLE_DELETED,
    AUDIT_ACTION_VEHICLE_ASSIGNED,
    AUDIT_ACTION_VEHICLE_UNASSIGNED,
    AUDIT_ACTION_VEHICLE_DOCUMENT_UPLOADED,
    AUDIT_ACTION_VEHICLE_DOCUMENT_DELETED,
    AUDIT_ACTION_VEHICLE_ARCHIVED,
    ENTITY_TYPE_VEHICLE,
    ENTITY_TYPE_VEHICLE_DOCUMENT,
    VEHICLE_STATUS_ACTIVE,
    VEHICLE_STATUS_DECOMMISSIONED
)


class VehicleService:
    """Service class for vehicle-related operations."""

    def __init__(self, db: Session):
        self.db = db

    def create_vehicle(
        self,
        user_id: uuid.UUID,
        org_id: uuid.UUID,
        vehicle_data: VehicleCreateRequest
    ) -> Dict[str, Any]:
        """
        Create a new vehicle.

        Args:
            user_id: ID of user creating the vehicle
            org_id: Organization ID
            vehicle_data: Vehicle creation data

        Returns:
            Dictionary with success status and vehicle info

        Raises:
            HTTPException: If validation fails or duplicates found
        """
        # Validate organization exists
        organization = self.db.query(Organization).filter_by(id=org_id).first()
        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Check vehicle_number uniqueness within organization
        existing_vehicle_number = self.db.query(Vehicle).filter(
            and_(
                Vehicle.organization_id == org_id,
                Vehicle.vehicle_number == vehicle_data.vehicle_number
            )
        ).first()

        if existing_vehicle_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Vehicle number '{vehicle_data.vehicle_number}' already exists in your organization"
            )

        # Check registration_number uniqueness globally
        existing_registration = self.db.query(Vehicle).filter_by(
            registration_number=vehicle_data.registration_number
        ).first()

        if existing_registration:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Registration number '{vehicle_data.registration_number}' already exists"
            )

        # Check VIN uniqueness if provided
        if vehicle_data.vin_number:
            existing_vin = self.db.query(Vehicle).filter_by(
                vin_number=vehicle_data.vin_number
            ).first()

            if existing_vin:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"VIN '{vehicle_data.vin_number}' already exists"
                )

        # Create vehicle
        new_vehicle = Vehicle(
            organization_id=org_id,
            created_by=user_id,
            status=VEHICLE_STATUS_ACTIVE,
            **vehicle_data.model_dump()
        )

        self.db.add(new_vehicle)
        self.db.commit()
        self.db.refresh(new_vehicle)

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_VEHICLE_CREATED,
            entity_type=ENTITY_TYPE_VEHICLE,
            entity_id=new_vehicle.id,
            details={
                "vehicle_number": new_vehicle.vehicle_number,
                "registration_number": new_vehicle.registration_number,
                "manufacturer": new_vehicle.manufacturer,
                "model": new_vehicle.model,
                "vehicle_type": new_vehicle.vehicle_type
            }
        )
        self.db.add(audit_log)
        self.db.commit()

        return {
            "success": True,
            "message": "Vehicle created successfully",
            "vehicle_id": str(new_vehicle.id),
            "vehicle_name": new_vehicle.full_vehicle_name
        }

    def get_vehicle_by_id(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID
    ) -> Vehicle:
        """
        Get vehicle by ID with organization security check.

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID

        Returns:
            Vehicle object

        Raises:
            HTTPException: If vehicle not found or belongs to different organization
        """
        vehicle = self.db.query(Vehicle).options(
            joinedload(Vehicle.current_driver),
            joinedload(Vehicle.documents)
        ).filter(
            and_(
                Vehicle.id == vehicle_id,
                Vehicle.organization_id == org_id
            )
        ).first()

        if not vehicle:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle not found"
            )

        return vehicle

    def get_vehicles_by_organization(
        self,
        org_id: uuid.UUID,
        skip: int = 0,
        limit: int = 20,
        status_filter: Optional[str] = None,
        vehicle_type_filter: Optional[str] = None,
        fuel_type_filter: Optional[str] = None,
        search: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get paginated list of vehicles for an organization with optional filters.

        Args:
            org_id: Organization ID
            skip: Number of records to skip
            limit: Number of records to return
            status_filter: Filter by vehicle status
            vehicle_type_filter: Filter by vehicle type
            fuel_type_filter: Filter by fuel type
            search: Search term for vehicle number, registration, or manufacturer

        Returns:
            Dictionary with vehicles list and pagination info
        """
        query = self.db.query(Vehicle).options(
            joinedload(Vehicle.current_driver)
        ).filter(Vehicle.organization_id == org_id)

        # Apply filters
        if status_filter:
            query = query.filter(Vehicle.status == status_filter)

        if vehicle_type_filter:
            query = query.filter(Vehicle.vehicle_type == vehicle_type_filter)

        if fuel_type_filter:
            query = query.filter(Vehicle.fuel_type == fuel_type_filter)

        if search:
            search_term = f"%{search}%"
            query = query.filter(
                or_(
                    Vehicle.vehicle_number.ilike(search_term),
                    Vehicle.registration_number.ilike(search_term),
                    Vehicle.manufacturer.ilike(search_term),
                    Vehicle.model.ilike(search_term)
                )
            )

        # Get total count
        total = query.count()

        # Apply pagination and order by
        vehicles = query.order_by(Vehicle.created_at.desc()).offset(skip).limit(limit).all()

        # Convert to response format
        vehicle_responses = []
        for vehicle in vehicles:
            vehicle_dict = vehicle.to_dict()
            vehicle_dict["current_driver_name"] = vehicle.current_driver.full_name if vehicle.current_driver else None
            vehicle_dict["document_count"] = len(vehicle.documents)
            vehicle_dict["has_expiring_docs"] = vehicle.needs_maintenance()
            vehicle_responses.append(vehicle_dict)

        return {
            "success": True,
            "vehicles": vehicle_responses,
            "total": total,
            "skip": skip,
            "limit": limit
        }

    def update_vehicle(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID,
        user_id: uuid.UUID,
        update_data: VehicleUpdateRequest
    ) -> Dict[str, Any]:
        """
        Update vehicle information.

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID
            user_id: ID of user performing update
            update_data: Updated vehicle data

        Returns:
            Dictionary with success status

        Raises:
            HTTPException: If vehicle not found or validation fails
        """
        vehicle = self.get_vehicle_by_id(vehicle_id, org_id)

        # Track changes for audit log
        changes = {}

        # Check uniqueness constraints if being updated
        update_dict = update_data.model_dump(exclude_unset=True)

        if "vehicle_number" in update_dict and update_dict["vehicle_number"] != vehicle.vehicle_number:
            existing = self.db.query(Vehicle).filter(
                and_(
                    Vehicle.organization_id == org_id,
                    Vehicle.vehicle_number == update_dict["vehicle_number"],
                    Vehicle.id != vehicle_id
                )
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Vehicle number '{update_dict['vehicle_number']}' already exists"
                )
            changes["vehicle_number"] = {
                "old": vehicle.vehicle_number,
                "new": update_dict["vehicle_number"]
            }

        if "registration_number" in update_dict and update_dict["registration_number"] != vehicle.registration_number:
            existing = self.db.query(Vehicle).filter(
                and_(
                    Vehicle.registration_number == update_dict["registration_number"],
                    Vehicle.id != vehicle_id
                )
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Registration number '{update_dict['registration_number']}' already exists"
                )
            changes["registration_number"] = {
                "old": vehicle.registration_number,
                "new": update_dict["registration_number"]
            }

        if "vin_number" in update_dict and update_dict["vin_number"] and update_dict["vin_number"] != vehicle.vin_number:
            existing = self.db.query(Vehicle).filter(
                and_(
                    Vehicle.vin_number == update_dict["vin_number"],
                    Vehicle.id != vehicle_id
                )
            ).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"VIN '{update_dict['vin_number']}' already exists"
                )

        # Update vehicle fields
        for field, value in update_dict.items():
            if value is not None and hasattr(vehicle, field):
                old_value = getattr(vehicle, field)
                if old_value != value:
                    if field not in changes:
                        changes[field] = {"old": str(old_value), "new": str(value)}
                    setattr(vehicle, field, value)

        vehicle.updated_at = datetime.utcnow()

        self.db.commit()
        self.db.refresh(vehicle)

        # Log audit event
        if changes:
            audit_log = AuditLog(
                user_id=user_id,
                organization_id=org_id,
                action=AUDIT_ACTION_VEHICLE_UPDATED,
                entity_type=ENTITY_TYPE_VEHICLE,
                entity_id=vehicle_id,
                details={
                    "vehicle_number": vehicle.vehicle_number,
                    "changes": changes
                }
            )
            self.db.add(audit_log)
            self.db.commit()

        return {
            "success": True,
            "message": "Vehicle updated successfully",
            "vehicle_id": str(vehicle.id)
        }

    def delete_vehicle(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> Dict[str, Any]:
        """
        Soft delete a vehicle (set status to decommissioned).

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID
            user_id: ID of user performing deletion

        Returns:
            Dictionary with success status

        Raises:
            HTTPException: If vehicle not found
        """
        vehicle = self.get_vehicle_by_id(vehicle_id, org_id)

        # Soft delete: set status to decommissioned
        vehicle.status = VEHICLE_STATUS_DECOMMISSIONED
        vehicle.current_driver_id = None  # Unassign driver if any
        vehicle.updated_at = datetime.utcnow()

        self.db.commit()

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_VEHICLE_DELETED,
            entity_type=ENTITY_TYPE_VEHICLE,
            entity_id=vehicle_id,
            details={
                "vehicle_number": vehicle.vehicle_number,
                "registration_number": vehicle.registration_number
            }
        )
        self.db.add(audit_log)
        self.db.commit()

        return {
            "success": True,
            "message": "Vehicle decommissioned successfully"
        }

    def assign_driver(
        self,
        vehicle_id: uuid.UUID,
        driver_id: uuid.UUID,
        org_id: uuid.UUID,
        user_id: uuid.UUID,
        assignment_data: VehicleAssignDriverRequest
    ) -> Dict[str, Any]:
        """
        Assign a driver to a vehicle.

        Args:
            vehicle_id: Vehicle ID
            driver_id: Driver ID to assign
            org_id: Organization ID
            user_id: ID of user performing assignment
            assignment_data: Assignment details

        Returns:
            Dictionary with success status

        Raises:
            HTTPException: If vehicle or driver not found, or driver not available
        """
        vehicle = self.get_vehicle_by_id(vehicle_id, org_id)

        # Validate driver exists and belongs to same organization
        driver = self.db.query(Driver).filter(
            and_(
                Driver.id == driver_id,
                Driver.organization_id == org_id
            )
        ).first()

        if not driver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Driver not found in your organization"
            )

        # Check if driver is active
        if not driver.is_active():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Driver {driver.full_name} is not in active status"
            )

        # Unassign previous driver if any
        previous_driver_id = vehicle.current_driver_id

        # Assign new driver
        vehicle.current_driver_id = driver_id
        vehicle.updated_at = datetime.utcnow()

        self.db.commit()

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_VEHICLE_ASSIGNED,
            entity_type=ENTITY_TYPE_VEHICLE,
            entity_id=vehicle_id,
            details={
                "vehicle_number": vehicle.vehicle_number,
                "driver_id": str(driver_id),
                "driver_name": driver.full_name,
                "previous_driver_id": str(previous_driver_id) if previous_driver_id else None,
                "assignment_date": str(assignment_data.assignment_date),
                "notes": assignment_data.notes
            }
        )
        self.db.add(audit_log)
        self.db.commit()

        return {
            "success": True,
            "message": f"Driver {driver.full_name} assigned to vehicle {vehicle.vehicle_number}",
            "vehicle_id": str(vehicle.id),
            "driver_id": str(driver.id)
        }

    def unassign_driver(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID,
        user_id: uuid.UUID,
        notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Remove driver assignment from a vehicle.

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID
            user_id: ID of user performing unassignment
            notes: Optional notes about the unassignment

        Returns:
            Dictionary with success status

        Raises:
            HTTPException: If vehicle not found or no driver assigned
        """
        vehicle = self.get_vehicle_by_id(vehicle_id, org_id)

        if not vehicle.current_driver_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No driver currently assigned to this vehicle"
            )

        previous_driver_id = vehicle.current_driver_id
        previous_driver = vehicle.current_driver

        # Unassign driver
        vehicle.current_driver_id = None
        vehicle.updated_at = datetime.utcnow()

        self.db.commit()

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_VEHICLE_UNASSIGNED,
            entity_type=ENTITY_TYPE_VEHICLE,
            entity_id=vehicle_id,
            details={
                "vehicle_number": vehicle.vehicle_number,
                "previous_driver_id": str(previous_driver_id),
                "previous_driver_name": previous_driver.full_name if previous_driver else None,
                "notes": notes
            }
        )
        self.db.add(audit_log)
        self.db.commit()

        return {
            "success": True,
            "message": "Driver unassigned successfully",
            "vehicle_id": str(vehicle.id)
        }

    def get_expiring_documents(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID,
        days: int = 30
    ) -> Dict[str, Any]:
        """
        Get list of expiring documents/certificates for a vehicle.

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID
            days: Number of days to look ahead for expiry

        Returns:
            Dictionary with expiring documents list

        Raises:
            HTTPException: If vehicle not found
        """
        vehicle = self.get_vehicle_by_id(vehicle_id, org_id)

        expiring_docs = vehicle.get_expiring_documents(days=days)

        # Add expired flag
        for doc in expiring_docs:
            doc["is_expired"] = doc["days_remaining"] < 0

        return {
            "success": True,
            "vehicle_id": str(vehicle.id),
            "vehicle_name": vehicle.full_vehicle_name,
            "expiring_documents": expiring_docs,
            "total_expiring": len(expiring_docs)
        }

    def archive_vehicle(
        self,
        vehicle_id: uuid.UUID,
        org_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> Dict[str, Any]:
        """
        Archive a vehicle (same as soft delete).

        Args:
            vehicle_id: Vehicle ID
            org_id: Organization ID
            user_id: ID of user performing archival

        Returns:
            Dictionary with success status
        """
        return self.delete_vehicle(vehicle_id, org_id, user_id)
