"""
Profile Service
Handle profile completion and role selection
"""

from datetime import datetime
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
import uuid

from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.driver import Driver
from app.models.audit_log import AuditLog
from app.utils.constants import *


class ProfileService:
    """Service for profile operations"""

    def __init__(self, db: Session):
        self.db = db

    def get_profile_status(self, user_id: uuid.UUID) -> dict:
        """Get user's profile completion status"""
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Get user's organization and role if exists
        user_org = self.db.query(UserOrganization).filter(
            UserOrganization.user_id == user_id
        ).first()

        company = None
        role = None
        role_type = None

        if user_org:
            role = self.db.query(Role).filter(Role.id == user_org.role_id).first()

            # Determine role_type
            if role:
                if role.is_owner():
                    role_type = "owner"
                elif role.is_independent_user():
                    role_type = "independent"
                elif role.is_pending_user():
                    role_type = "pending_user"
                else:
                    # Check if user is a driver
                    driver = self.db.query(Driver).filter(Driver.user_id == user_id).first()
                    if driver:
                        role_type = "driver"
                    else:
                        role_type = "custom"

            if user_org.organization_id:
                company = self.db.query(Organization).filter(
                    Organization.id == user_org.organization_id
                ).first()

        return {
            "success": True,
            "profile_completed": user.profile_completed,
            "user_id": str(user.id),
            "username": user.username,
            "full_name": user.full_name,
            "email": user.email,
            "phone": user.phone,
            "role": role.role_name if role else None,
            "role_type": role_type,
            "company_id": str(company.id) if company else None,
            "company_name": company.company_name if company else None
        }

    def complete_profile(self, user_id: uuid.UUID, profile_data: dict) -> dict:
        """Complete user profile with role selection"""
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Check if profile already completed
        if user.profile_completed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Profile already completed. Role cannot be changed."
            )

        role_type = profile_data['role_type']
        role = None
        company = None
        driver_id = None
        user_org = None

        # Handle different role types
        if role_type == 'independent':
            # Set as Independent User
            role = self._get_role_by_key('independent_user')
            user_org = UserOrganization(
                user_id=user.id,
                organization_id=None,
                role_id=role.id,
                status='active'
            )
            self.db.add(user_org)

        elif role_type == 'driver':
            # Create driver profile
            if not profile_data.get('license_number'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="License number required for driver role"
                )

            # Create driver record
            driver = Driver(
                id=uuid.uuid4(),
                user_id=user.id,
                driver_name=user.full_name,
                phone=user.phone,
                email=user.email,
                license_number=profile_data['license_number'],
                license_expiry=datetime.fromisoformat(profile_data['license_expiry']) if profile_data.get('license_expiry') else None,
                status='available',
                employment_type='permanent',
                is_verified=True
            )
            self.db.add(driver)
            self.db.flush()
            driver_id = driver.id

            # Set as Independent User (driver without company)
            role = self._get_role_by_key('independent_user')
            user_org = UserOrganization(
                user_id=user.id,
                organization_id=None,
                role_id=role.id,
                status='active'
            )
            self.db.add(user_org)

        elif role_type == 'join_company':
            # Join existing company
            if not profile_data.get('company_id'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Company ID required to join company"
                )

            company = self.db.query(Organization).filter(
                Organization.id == profile_data['company_id']
            ).first()

            if not company:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Company not found"
                )

            # Set as Pending User
            role = self._get_role_by_key('pending_user')
            user_org = UserOrganization(
                user_id=user.id,
                organization_id=company.id,
                role_id=role.id,
                status='pending'
            )
            self.db.add(user_org)

        elif role_type == 'create_company':
            # Create new company
            if not profile_data.get('company_name'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Company details required to create company"
                )

            company = Organization(
                id=uuid.uuid4(),
                company_name=profile_data['company_name'],
                business_type=profile_data.get('business_type', 'Other'),
                business_email=profile_data.get('business_email', user.email),
                business_phone=profile_data.get('business_phone', user.phone),
                address=profile_data.get('address', ''),
                city=profile_data.get('city', ''),
                state=profile_data.get('state', ''),
                pincode=profile_data.get('pincode', ''),
                country=profile_data.get('country', 'India'),
                status='active'
            )
            self.db.add(company)
            self.db.flush()

            # Set as Owner
            role = self._get_role_by_key('owner')
            user_org = UserOrganization(
                user_id=user.id,
                organization_id=company.id,
                role_id=role.id,
                status='active',
                approved_at=datetime.utcnow(),
                approved_by=user.id
            )
            self.db.add(user_org)

            # Log company creation
            self._log_audit(
                user_id=user.id,
                organization_id=company.id,
                action=AUDIT_ACTION_COMPANY_CREATED,
                entity_type=ENTITY_TYPE_COMPANY,
                entity_id=company.id
            )

        # Mark profile as completed (cannot be changed)
        user.profile_completed = True

        # Commit all changes
        self.db.commit()
        self.db.refresh(user)

        # Log profile completion
        self._log_audit(
            user_id=user.id,
            organization_id=company.id if company else None,
            action="profile_completed",
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id,
            details={
                "role_type": role_type,
                "role": role.role_name if role else None
            }
        )

        return {
            "success": True,
            "message": f"Profile completed successfully as {role_type}",
            "user_id": str(user.id),
            "role": role.role_name if role else None,
            "role_type": role_type,
            "company_id": str(company.id) if company else None,
            "company_name": company.company_name if company else None,
            "driver_id": str(driver_id) if driver_id else None
        }

    def _get_role_by_key(self, role_key: str) -> Role:
        """Get role by role_key"""
        role = self.db.query(Role).filter(Role.role_key == role_key).first()

        if not role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Role '{role_key}' not found in database"
            )

        return role

    def _log_audit(
        self,
        user_id: Optional[uuid.UUID],
        action: str,
        entity_type: Optional[str] = None,
        entity_id: Optional[uuid.UUID] = None,
        organization_id: Optional[uuid.UUID] = None,
        details: Optional[dict] = None
    ):
        """Log audit event"""
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=organization_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details
        )

        self.db.add(audit_log)

    def change_role(self, user_id: uuid.UUID, profile_data: dict) -> dict:
        """Allow Independent Users to change their role"""
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Get user's current organization and role
        user_org = self.db.query(UserOrganization).filter(
            UserOrganization.user_id == user_id
        ).first()

        if not user_org:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User has no role assignment"
            )

        current_role = self.db.query(Role).filter(Role.id == user_org.role_id).first()

        # Only Independent Users can change role
        if not current_role or not current_role.is_independent_user():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only Independent Users can change their role. Users with company affiliations cannot change roles."
            )

        # Ensure user has no organization
        if user_org.organization_id is not None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot change role while affiliated with an organization"
            )

        role_type = profile_data['role_type']

        # Independent users cannot change back to independent
        if role_type == 'independent':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already an Independent User"
            )

        role = None
        company = None
        driver_id = None

        # Handle different role types
        if role_type == 'driver':
            # Create driver profile
            if not profile_data.get('license_number'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="License number required for driver role"
                )

            # Check if user is already a driver
            existing_driver = self.db.query(Driver).filter(Driver.user_id == user.id).first()
            if existing_driver:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="You are already registered as a driver"
                )

            # Create driver record
            driver = Driver(
                id=uuid.uuid4(),
                user_id=user.id,
                driver_name=user.full_name,
                phone=user.phone,
                email=user.email,
                license_number=profile_data['license_number'],
                license_expiry=datetime.fromisoformat(profile_data['license_expiry']) if profile_data.get('license_expiry') else None,
                status='available',
                employment_type='permanent',
                is_verified=True
            )
            self.db.add(driver)
            self.db.flush()
            driver_id = driver.id

            # Role remains Independent User
            role = current_role

        elif role_type == 'join_company':
            # Join existing company
            if not profile_data.get('company_id'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Company ID required to join company"
                )

            company = self.db.query(Organization).filter(
                Organization.id == profile_data['company_id']
            ).first()

            if not company:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Company not found"
                )

            # Update to Pending User
            role = self._get_role_by_key('pending_user')
            user_org.organization_id = company.id
            user_org.role_id = role.id
            user_org.status = 'pending'

        elif role_type == 'create_company':
            # Create new company
            if not profile_data.get('company_name'):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Company details required to create company"
                )

            company = Organization(
                id=uuid.uuid4(),
                company_name=profile_data['company_name'],
                business_type=profile_data.get('business_type', 'Other'),
                business_email=profile_data.get('business_email', user.email),
                business_phone=profile_data.get('business_phone', user.phone),
                address=profile_data.get('address', ''),
                city=profile_data.get('city', ''),
                state=profile_data.get('state', ''),
                pincode=profile_data.get('pincode', ''),
                country=profile_data.get('country', 'India'),
                status='active'
            )
            self.db.add(company)
            self.db.flush()

            # Update to Owner
            role = self._get_role_by_key('owner')
            user_org.organization_id = company.id
            user_org.role_id = role.id
            user_org.status = 'active'
            user_org.approved_at = datetime.utcnow()
            user_org.approved_by = user.id

            # Log company creation
            self._log_audit(
                user_id=user.id,
                organization_id=company.id,
                action=AUDIT_ACTION_COMPANY_CREATED,
                entity_type=ENTITY_TYPE_COMPANY,
                entity_id=company.id
            )

        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid role_type: {role_type}"
            )

        # Commit all changes
        self.db.commit()
        self.db.refresh(user)

        # Log role change
        self._log_audit(
            user_id=user.id,
            organization_id=company.id if company else None,
            action="role_changed",
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id,
            details={
                "old_role": current_role.role_name,
                "new_role_type": role_type,
                "new_role": role.role_name if role else None
            }
        )

        return {
            "success": True,
            "message": f"Role changed successfully to {role_type}",
            "user_id": str(user.id),
            "role": role.role_name if role else None,
            "role_type": role_type,
            "company_id": str(company.id) if company else None,
            "company_name": company.company_name if company else None,
            "driver_id": str(driver_id) if driver_id else None
        }

    def update_profile(self, user_id: uuid.UUID, update_data: dict) -> dict:
        """Update user profile information"""
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Update allowed fields
        if 'full_name' in update_data:
            user.full_name = update_data['full_name']

        if 'email' in update_data:
            # Check if email is already in use by another user
            existing_user = self.db.query(User).filter(
                User.email == update_data['email'],
                User.id != user_id
            ).first()

            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email is already in use"
                )

            user.email = update_data['email']

        if 'phone' in update_data:
            # Check if phone is already in use by another user
            existing_user = self.db.query(User).filter(
                User.phone == update_data['phone'],
                User.id != user_id
            ).first()

            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Phone number is already in use"
                )

            user.phone = update_data['phone']

        # Commit changes
        self.db.commit()
        self.db.refresh(user)

        # Log profile update
        self._log_audit(
            user_id=user.id,
            action="profile_updated",
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id,
            details={
                "updated_fields": list(update_data.keys())
            }
        )

        # Return updated profile status
        return self.get_profile_status(user_id)
