"""
Company Management API Endpoints
Company search, validation, creation, and joining
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.company import (
    CompanySearchResponse,
    CompanyValidationRequest, CompanyValidationResponse,
    CompanyCreateRequest, CompanyResponse,
    CompanyJoinRequest, CompanyJoinResponse
)
from app.services.company_service import CompanyService

router = APIRouter()


@router.get("/search", response_model=CompanySearchResponse)
def search_companies(
    q: str = Query(..., min_length=3, description="Search query (min 3 characters)"),
    limit: int = Query(3, ge=1, le=3, description="Max results (max 3)"),
    db: Session = Depends(get_db)
):
    """
    Search companies by name.

    **Requirements:**
    - Minimum 3 characters in search query
    - Returns maximum 3 results
    - Case-insensitive partial match

    **Use Cases:**
    - User searching for company to join during signup
    - Autocomplete company selection

    **Example:**
    ```
    GET /api/companies/search?q=ABC&limit=3
    ```

    **Returns:**
    - List of matching companies (max 3)
    - Company ID, name, city, state, business type
    - Flag indicating if more results exist
    """
    company_service = CompanyService(db)

    result = company_service.search_companies(query=q, limit=limit)

    return CompanySearchResponse(**result)


@router.post("/validate", response_model=CompanyValidationResponse)
def validate_company_details(
    validation_data: CompanyValidationRequest,
    db: Session = Depends(get_db)
):
    """
    Validate company details (GSTIN, PAN format).

    **Validates:**
    - GSTIN format (15 characters: 29ABCDE1234F1Z5)
    - PAN format (10 characters: ABCDE1234F)
    - GSTIN-PAN linkage (PAN embedded in GSTIN)
    - GSTIN uniqueness (not already registered)

    **Use Cases:**
    - Validate during company creation
    - Check before submitting company details

    **Note:**
    - Currently performs format validation only
    - In production, could integrate with government APIs
    """
    company_service = CompanyService(db)

    result = company_service.validate_company_details(
        gstin=validation_data.gstin,
        pan_number=validation_data.pan_number,
        registration_number=validation_data.registration_number
    )

    return CompanyValidationResponse(**result)


@router.post("/create", response_model=CompanyResponse, status_code=status.HTTP_201_CREATED)
def create_company(
    company_data: CompanyCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new company (for authenticated users).

    **Requires:** JWT authentication

    **Body Parameters:**
    - Company name, business type
    - Contact information (email, phone)
    - Address (address, city, state, pincode)

    **Optional:**
    - GSTIN (Indian tax ID)
    - PAN (Permanent Account Number)
    - Registration number
    - Registration date

    **Process:**
    1. Validate company details
    2. Create organization record
    3. Assign creator as Owner
    4. Set status to 'active'

    **Note:**
    - GSTIN and PAN are optional
    - Can be added later by Owner
    - GSTIN must be unique if provided
    - User will become owner of the new organization
    """
    company_service = CompanyService(db)

    # Convert Pydantic model to dict
    company_dict = company_data.dict()

    result = company_service.create_company(
        user_id=str(current_user.id),
        company_data=company_dict
    )

    return {
        "company_id": result["company_id"],
        "company_name": result["company_name"],
        "business_type": company_dict["business_type"],
        "gstin": company_dict.get("gstin"),
        "pan_number": company_dict.get("pan_number"),
        "business_email": company_dict["business_email"],
        "business_phone": company_dict["business_phone"],
        "city": company_dict["city"],
        "state": company_dict["state"],
        "country": company_dict.get("country", "India"),
        "status": "active"
    }


@router.post("/join", response_model=CompanyJoinResponse)
def join_company(
    join_data: CompanyJoinRequest,
    db: Session = Depends(get_db)
):
    """
    Join an existing company.

    **Requires:**
    - Company ID (from search results)

    **Process:**
    1. Verify company exists
    2. Create user-company relationship
    3. Assign 'Pending User' role
    4. Set status to 'pending'
    5. Admin must approve and assign actual role

    **Note:**
    - User will have no access until admin assigns role
    - Admin receives notification of pending user
    """
    # TODO: Get current user from JWT token
    # For now, we'll need to pass user_id as a parameter
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Join company requires authentication. Use signup endpoint instead."
    )


@router.get("/{company_id}", response_model=CompanyResponse)
def get_company_details(
    company_id: str,
    db: Session = Depends(get_db)
):
    """
    Get company details by ID.

    **Returns:**
    - Complete company information
    - GSTIN, PAN (if available)
    - Contact information
    - Address

    **Access:**
    - Public: Basic information
    - Members: Full information
    - Owner: All details including sensitive data
    """
    company_service = CompanyService(db)

    result = company_service.get_company_details(company_id)

    return CompanyResponse(**result)


@router.get("/", response_model=list)
def list_companies(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """
    List all companies (admin only).

    **Pagination:**
    - skip: Number of records to skip
    - limit: Number of records to return (max 100)

    **Access:** Super Admin only
    """
    # TODO: Implement list companies with admin check
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="List companies not yet implemented"
    )
