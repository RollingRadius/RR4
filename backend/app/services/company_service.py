"""
Company Service
Business logic for company/organization management
"""

from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from fastapi import HTTPException, status
from typing import List, Optional
import uuid

from app.models.company import Organization
from app.models.user_organization import UserOrganization
from app.models.role import Role
from app.models.audit_log import AuditLog
from app.utils.validators import (
    validate_gstin, validate_pan, validate_gstin_pan_linkage,
    extract_pan_from_gstin
)
from app.utils.constants import AUDIT_ACTION_COMPANY_CREATED, ENTITY_TYPE_COMPANY
from app.config import settings


class CompanyService:
    """Service for company operations"""

    def __init__(self, db: Session):
        self.db = db

    def search_companies(self, query: str, limit: int = 3) -> dict:
        """
        Search companies by name.

        Requirements:
        - Minimum 3 characters in query
        - Maximum 3 results returned
        - Case-insensitive partial match

        Args:
            query: Search term
            limit: Maximum results (default: 3, max: 3)

        Returns:
            Dictionary with search results

        Raises:
            HTTPException: If query too short
        """
        # Validate query length
        if len(query.strip()) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Search query must be at least 3 characters"
            )

        # Enforce max limit
        limit = min(limit, 3)

        # Search companies (case-insensitive partial match)
        companies = self.db.query(Organization).filter(
            Organization.company_name.ilike(f"%{query}%"),
            Organization.status == 'active'
        ).limit(limit).all()

        # Convert to search results
        results = [company.to_search_result() for company in companies]

        # Check if there are more results
        total_count = self.db.query(func.count(Organization.id)).filter(
            Organization.company_name.ilike(f"%{query}%"),
            Organization.status == 'active'
        ).scalar()

        has_more = total_count > limit

        return {
            "success": True,
            "companies": results,
            "count": len(results),
            "query": query,
            "has_more": has_more
        }

    def validate_company_details(
        self,
        gstin: Optional[str] = None,
        pan_number: Optional[str] = None,
        registration_number: Optional[str] = None
    ) -> dict:
        """
        Validate company details (GSTIN, PAN format).

        In production, this could connect to government APIs for verification.
        For now, it performs format validation and linkage checks.

        Args:
            gstin: GSTIN to validate
            pan_number: PAN to validate
            registration_number: Registration number

        Returns:
            Validation result dictionary
        """
        validation_result = {
            "gstin_valid": True,
            "pan_valid": True,
            "registration_number_valid": True,
            "gstin_status": None,
            "pan_linked": None
        }

        errors = []

        # Validate GSTIN format
        if gstin:
            is_valid, error = validate_gstin(gstin)
            if not is_valid:
                validation_result["gstin_valid"] = False
                errors.append(f"GSTIN: {error}")
            else:
                validation_result["gstin_status"] = "Format Valid"

                # Check if GSTIN already exists
                existing = self.db.query(Organization).filter(
                    Organization.gstin == gstin
                ).first()

                if existing:
                    validation_result["gstin_valid"] = False
                    errors.append("GSTIN already registered to another company")

        # Validate PAN format
        if pan_number:
            is_valid, error = validate_pan(pan_number)
            if not is_valid:
                validation_result["pan_valid"] = False
                errors.append(f"PAN: {error}")

        # Validate GSTIN-PAN linkage
        if gstin and pan_number:
            is_linked, error = validate_gstin_pan_linkage(gstin, pan_number)
            if not is_linked:
                validation_result["pan_linked"] = False
                errors.append(f"Linkage: {error}")
            else:
                validation_result["pan_linked"] = True

        # Registration number (basic validation)
        if registration_number:
            if len(registration_number) < 5:
                validation_result["registration_number_valid"] = False
                errors.append("Registration number too short")

        # Overall validity
        all_valid = all([
            validation_result["gstin_valid"],
            validation_result["pan_valid"],
            validation_result["registration_number_valid"]
        ])

        if gstin and pan_number:
            all_valid = all_valid and validation_result.get("pan_linked", True)

        return {
            "success": True,
            "valid": all_valid,
            "message": "Valid" if all_valid else "Validation errors found",
            "validation": validation_result,
            "errors": errors if errors else None
        }

    def create_company(
        self,
        user_id: str,
        company_data: dict
    ) -> dict:
        """
        Create a new company.

        Args:
            user_id: User creating the company (will become Owner)
            company_data: Company information dictionary

        Returns:
            Created company information

        Raises:
            HTTPException: If creation fails
        """
        # Validate GSTIN uniqueness
        if company_data.get('gstin'):
            existing = self.db.query(Organization).filter(
                Organization.gstin == company_data['gstin']
            ).first()

            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="GSTIN already registered to another company"
                )

        # Create organization
        company = Organization(
            id=uuid.uuid4(),
            company_name=company_data['company_name'],
            business_type=company_data['business_type'],
            gstin=company_data.get('gstin'),
            pan_number=company_data.get('pan_number'),
            registration_number=company_data.get('registration_number'),
            registration_date=company_data.get('registration_date'),
            business_email=company_data['business_email'],
            business_phone=company_data['business_phone'],
            address=company_data['address'],
            city=company_data['city'],
            state=company_data['state'],
            pincode=company_data['pincode'],
            country=company_data.get('country', 'India'),
            status='active'
        )

        self.db.add(company)
        self.db.flush()

        # Get Owner role
        owner_role = self.db.query(Role).filter(
            Role.role_key == 'owner'
        ).first()

        if not owner_role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Owner role not found in database"
            )

        # Create user-organization relationship with Owner role
        from datetime import datetime
        user_org = UserOrganization(
            user_id=user_id,
            organization_id=company.id,
            role_id=owner_role.id,
            status='active',
            approved_at=datetime.utcnow(),
            approved_by=user_id
        )

        self.db.add(user_org)

        # Log audit event
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=company.id,
            action=AUDIT_ACTION_COMPANY_CREATED,
            entity_type=ENTITY_TYPE_COMPANY,
            entity_id=company.id,
            details={
                "company_name": company.company_name,
                "business_type": company.business_type,
                "has_gstin": bool(company.gstin),
                "has_pan": bool(company.pan_number)
            }
        )

        self.db.add(audit_log)

        # Commit transaction
        self.db.commit()
        self.db.refresh(company)

        return {
            "success": True,
            "message": "Company created successfully",
            "company_id": str(company.id),
            "company_name": company.company_name,
            "role": "Owner"
        }

    def get_company_by_id(self, company_id: str) -> Optional[Organization]:
        """Get company by ID"""
        return self.db.query(Organization).filter(
            Organization.id == company_id
        ).first()

    def get_company_details(self, company_id: str) -> dict:
        """Get detailed company information"""
        company = self.get_company_by_id(company_id)

        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )

        return {
            "company_id": str(company.id),
            "company_name": company.company_name,
            "business_type": company.business_type,
            "gstin": company.gstin,
            "pan_number": company.pan_number,
            "business_email": company.business_email,
            "business_phone": company.business_phone,
            "city": company.city,
            "state": company.state,
            "country": company.country,
            "status": company.status
        }

    def join_company(self, user_id: str, company_id: str) -> dict:
        """
        Join an existing company as Pending User.

        Args:
            user_id: User joining the company
            company_id: Company to join

        Returns:
            Join confirmation

        Raises:
            HTTPException: If join fails
        """
        # Get company
        company = self.get_company_by_id(company_id)

        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Company not found"
            )

        # Check if user already joined
        existing = self.db.query(UserOrganization).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.organization_id == company_id
        ).first()

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You have already joined this company"
            )

        # Get Pending User role
        pending_role = self.db.query(Role).filter(
            Role.role_key == 'pending_user'
        ).first()

        if not pending_role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Pending User role not found"
            )

        # Create user-organization relationship
        user_org = UserOrganization(
            user_id=user_id,
            organization_id=company.id,
            role_id=pending_role.id,
            status='pending'
        )

        self.db.add(user_org)
        self.db.commit()

        return {
            "success": True,
            "message": "Successfully joined company. Admin will assign your role.",
            "company_id": str(company.id),
            "company_name": company.company_name,
            "role": "Pending User",
            "status": "pending"
        }
