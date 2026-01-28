"""
Driver Service
Business logic for driver management
"""

from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any
from datetime import date
import uuid

from app.models.driver import Driver, DriverLicense
from app.models.company import Organization
from app.models.audit_log import AuditLog
from app.utils.constants import (
    AUDIT_ACTION_DRIVER_CREATED,
    AUDIT_ACTION_DRIVER_UPDATED,
    AUDIT_ACTION_DRIVER_DELETED,
    ENTITY_TYPE_DRIVER
)


class DriverService:
    """Service for driver operations"""

    def __init__(self, db: Session):
        self.db = db

    def create_driver(
        self,
        user_id: str,
        org_id: str,
        driver_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a new driver with license information.

        Args:
            user_id: User creating the driver
            org_id: Organization ID
            driver_data: Driver information including license

        Returns:
            Created driver information

        Raises:
            HTTPException: If creation fails
        """
        # Validate organization exists
        organization = self.db.query(Organization).filter(
            Organization.id == org_id
        ).first()

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Check employee_id uniqueness within organization
        existing_employee = self.db.query(Driver).filter(
            Driver.organization_id == org_id,
            Driver.employee_id == driver_data['employee_id']
        ).first()

        if existing_employee:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Employee ID '{driver_data['employee_id']}' already exists in your organization"
            )

        # Check email uniqueness globally (if provided)
        if driver_data.get('email'):
            existing_email = self.db.query(Driver).filter(
                Driver.email == driver_data['email']
            ).first()

            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Email '{driver_data['email']}' is already registered"
                )

        # Check license_number uniqueness globally
        license_data = driver_data.pop('license')
        existing_license = self.db.query(DriverLicense).filter(
            DriverLicense.license_number == license_data['license_number']
        ).first()

        if existing_license:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"License number '{license_data['license_number']}' is already registered"
            )

        # Create driver
        driver = Driver(
            id=uuid.uuid4(),
            organization_id=org_id,
            employee_id=driver_data['employee_id'],
            join_date=driver_data['join_date'],
            first_name=driver_data['first_name'],
            last_name=driver_data['last_name'],
            email=driver_data.get('email'),
            phone=driver_data['phone'],
            date_of_birth=driver_data.get('date_of_birth'),
            address=driver_data.get('address'),
            city=driver_data.get('city'),
            state=driver_data.get('state'),
            pincode=driver_data.get('pincode'),
            country=driver_data.get('country', 'India'),
            emergency_contact_name=driver_data.get('emergency_contact_name'),
            emergency_contact_phone=driver_data.get('emergency_contact_phone'),
            emergency_contact_relationship=driver_data.get('emergency_contact_relationship'),
            created_by=user_id,
            status='active'
        )

        self.db.add(driver)
        self.db.flush()  # Flush to get driver.id for license FK

        # Create driver license
        license = DriverLicense(
            id=uuid.uuid4(),
            driver_id=driver.id,
            license_number=license_data['license_number'],
            license_type=license_data['license_type'],
            issue_date=license_data['issue_date'],
            expiry_date=license_data['expiry_date'],
            issuing_authority=license_data.get('issuing_authority'),
            issuing_state=license_data.get('issuing_state')
        )

        self.db.add(license)

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_DRIVER_CREATED,
            entity_type=ENTITY_TYPE_DRIVER,
            entity_id=driver.id,
            details={
                "driver_name": driver.full_name,
                "employee_id": driver.employee_id,
                "license_number": license.license_number,
                "license_type": license.license_type
            }
        )

        self.db.add(audit_log)

        # Commit transaction
        self.db.commit()
        self.db.refresh(driver)
        self.db.refresh(license)

        return {
            "success": True,
            "message": "Driver created successfully",
            "driver_id": str(driver.id),
            "driver_name": driver.full_name,
            "employee_id": driver.employee_id
        }

    def get_driver_by_id(
        self,
        driver_id: str,
        org_id: str
    ) -> Optional[Driver]:
        """
        Get driver by ID with organization security check.

        Args:
            driver_id: Driver ID
            org_id: Organization ID (for security)

        Returns:
            Driver object or None

        Raises:
            HTTPException: If driver not found or not in organization
        """
        driver = self.db.query(Driver).options(
            joinedload(Driver.license)
        ).filter(
            Driver.id == driver_id,
            Driver.organization_id == org_id
        ).first()

        if not driver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Driver not found"
            )

        return driver

    def get_drivers_by_organization(
        self,
        org_id: str,
        skip: int = 0,
        limit: int = 50,
        status_filter: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get paginated list of drivers for an organization.

        Args:
            org_id: Organization ID
            skip: Number of records to skip
            limit: Maximum records to return
            status_filter: Optional status filter (active/inactive/on_leave/terminated)

        Returns:
            Dictionary with drivers list and pagination info
        """
        # Build query
        query = self.db.query(Driver).options(
            joinedload(Driver.license)
        ).filter(
            Driver.organization_id == org_id
        )

        # Apply status filter if provided
        if status_filter:
            query = query.filter(Driver.status == status_filter)

        # Get total count
        total = query.count()

        # Get paginated results
        drivers = query.order_by(
            Driver.created_at.desc()
        ).offset(skip).limit(limit).all()

        return {
            "success": True,
            "drivers": drivers,
            "total": total,
            "skip": skip,
            "limit": limit
        }

    def update_driver(
        self,
        driver_id: str,
        org_id: str,
        user_id: str,
        update_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Update driver information.

        Args:
            driver_id: Driver ID
            org_id: Organization ID (for security)
            user_id: User making the update
            update_data: Fields to update

        Returns:
            Update confirmation

        Raises:
            HTTPException: If update fails
        """
        # Get driver
        driver = self.get_driver_by_id(driver_id, org_id)

        # Extract license data if present
        license_data = update_data.pop('license', None)

        # Check employee_id uniqueness if being updated
        if 'employee_id' in update_data and update_data['employee_id'] != driver.employee_id:
            existing_employee = self.db.query(Driver).filter(
                Driver.organization_id == org_id,
                Driver.employee_id == update_data['employee_id'],
                Driver.id != driver_id
            ).first()

            if existing_employee:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Employee ID '{update_data['employee_id']}' already exists"
                )

        # Check email uniqueness if being updated
        if 'email' in update_data and update_data['email'] != driver.email:
            existing_email = self.db.query(Driver).filter(
                Driver.email == update_data['email'],
                Driver.id != driver_id
            ).first()

            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Email '{update_data['email']}' is already registered"
                )

        # Update driver fields
        for field, value in update_data.items():
            if hasattr(driver, field):
                setattr(driver, field, value)

        # Update license if provided
        if license_data:
            if driver.license:
                # Check license_number uniqueness if being updated
                if 'license_number' in license_data and license_data['license_number'] != driver.license.license_number:
                    existing_license = self.db.query(DriverLicense).filter(
                        DriverLicense.license_number == license_data['license_number'],
                        DriverLicense.id != driver.license.id
                    ).first()

                    if existing_license:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail=f"License number '{license_data['license_number']}' is already registered"
                        )

                # Update license fields
                for field, value in license_data.items():
                    if hasattr(driver.license, field):
                        setattr(driver.license, field, value)

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_DRIVER_UPDATED,
            entity_type=ENTITY_TYPE_DRIVER,
            entity_id=driver.id,
            details={
                "driver_name": driver.full_name,
                "updated_fields": list(update_data.keys())
            }
        )

        self.db.add(audit_log)

        # Commit transaction
        self.db.commit()
        self.db.refresh(driver)

        return {
            "success": True,
            "message": "Driver updated successfully",
            "driver_id": str(driver.id),
            "driver_name": driver.full_name
        }

    def delete_driver(
        self,
        driver_id: str,
        org_id: str,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Soft delete driver (set status to 'terminated').

        Args:
            driver_id: Driver ID
            org_id: Organization ID (for security)
            user_id: User performing the deletion

        Returns:
            Deletion confirmation

        Raises:
            HTTPException: If deletion fails
        """
        # Get driver
        driver = self.get_driver_by_id(driver_id, org_id)

        # Soft delete (set status to terminated)
        driver.status = 'terminated'

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=org_id,
            action=AUDIT_ACTION_DRIVER_DELETED,
            entity_type=ENTITY_TYPE_DRIVER,
            entity_id=driver.id,
            details={
                "driver_name": driver.full_name,
                "employee_id": driver.employee_id
            }
        )

        self.db.add(audit_log)

        # Commit transaction
        self.db.commit()

        return {
            "success": True,
            "message": "Driver deleted successfully",
            "driver_id": str(driver_id)
        }

    def validate_license_expiry(self, driver_id: str, org_id: str) -> Dict[str, Any]:
        """
        Check license expiry status for a driver.

        Args:
            driver_id: Driver ID
            org_id: Organization ID (for security)

        Returns:
            License expiry status

        Raises:
            HTTPException: If driver not found
        """
        driver = self.get_driver_by_id(driver_id, org_id)

        if not driver.license:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="License information not found"
            )

        is_expired = driver.license.is_expired()
        is_expiring_soon = driver.license.is_expiring_soon(days=30)

        return {
            "success": True,
            "license_number": driver.license.license_number,
            "expiry_date": driver.license.expiry_date,
            "is_expired": is_expired,
            "is_expiring_soon": is_expiring_soon,
            "status": "expired" if is_expired else ("expiring_soon" if is_expiring_soon else "valid")
        }
