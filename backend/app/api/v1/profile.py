"""
Profile API Endpoints
User profile completion and management
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.profile import (
    ProfileStatusResponse,
    ProfileCompletionRequest,
    ProfileCompletionResponse,
    ProfileUpdateRequest
)
from app.services.profile_service import ProfileService

router = APIRouter()


@router.get("/status", response_model=ProfileStatusResponse)
def get_profile_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's profile completion status.

    **Returns:**
    - Profile completion status
    - Current role information
    - Company information (if applicable)

    **Use Case:**
    - Check if user needs to complete profile
    - Display profile information on dashboard
    """
    profile_service = ProfileService(db)
    result = profile_service.get_profile_status(current_user.id)
    return ProfileStatusResponse(**result)


@router.post("/complete", response_model=ProfileCompletionResponse, status_code=status.HTTP_201_CREATED)
def complete_profile(
    profile_data: ProfileCompletionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Complete user profile by selecting role.

    **IMPORTANT:** This can only be done ONCE. Once profile is completed, role cannot be changed.

    **Role Types:**

    1. **independent** - Independent User (no company affiliation)
       - Can use basic features
       - No company association required

    2. **driver** - Register as a Driver
       - Must provide license_number and license_expiry
       - Creates driver profile
       - Can be hired by companies later

    3. **join_company** - Join Existing Company
       - Must provide company_id
       - Becomes Pending User (awaits admin approval)
       - Cannot use company features until approved

    4. **create_company** - Create New Company
       - Must provide company details (name, business_type, etc.)
       - Becomes Owner immediately
       - Full access to all company features

    **Example Requests:**

    ```json
    // Independent User
    {
        "role_type": "independent"
    }

    // Driver
    {
        "role_type": "driver",
        "license_number": "DL1234567890",
        "license_expiry": "2027-12-31"
    }

    // Join Company
    {
        "role_type": "join_company",
        "company_id": "uuid-here"
    }

    // Create Company
    {
        "role_type": "create_company",
        "company_name": "My Fleet Company",
        "business_type": "Transportation",
        "business_email": "company@example.com",
        "business_phone": "1234567890",
        "address": "123 Main St",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "country": "India"
    }
    ```
    """
    profile_service = ProfileService(db)

    # Convert Pydantic model to dict
    profile_dict = profile_data.model_dump()

    result = profile_service.complete_profile(
        user_id=current_user.id,
        profile_data=profile_dict
    )

    return ProfileCompletionResponse(**result)


@router.post("/change-role", response_model=ProfileCompletionResponse)
def change_user_role(
    profile_data: ProfileCompletionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Allow Independent Users to change their role.

    **Who Can Use This:**
    - Only Independent Users can change their role
    - Users with company affiliations cannot use this endpoint

    **Available Role Changes:**

    1. **driver** - Become a Driver
       - Must provide license_number and license_expiry
       - Creates driver profile
       - Can be hired by companies later

    2. **join_company** - Join Existing Company
       - Must provide company_id
       - Becomes Pending User (awaits admin approval)
       - Cannot use company features until approved

    3. **create_company** - Create New Company
       - Must provide company details (name, business_type, etc.)
       - Becomes Owner immediately
       - Full access to all company features

    **Example Requests:**

    ```json
    // Become Driver
    {
        "role_type": "driver",
        "license_number": "DL1234567890",
        "license_expiry": "2027-12-31"
    }

    // Join Company
    {
        "role_type": "join_company",
        "company_id": "uuid-here"
    }

    // Create Company
    {
        "role_type": "create_company",
        "company_name": "My Fleet Company",
        "business_type": "Transportation",
        "business_email": "company@example.com",
        "business_phone": "1234567890",
        "address": "123 Main St",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pincode": "400001",
        "country": "India"
    }
    ```
    """
    profile_service = ProfileService(db)

    # Convert Pydantic model to dict
    profile_dict = profile_data.model_dump()

    result = profile_service.change_role(
        user_id=current_user.id,
        profile_data=profile_dict
    )

    return ProfileCompletionResponse(**result)


@router.put("/update", response_model=ProfileStatusResponse)
def update_profile(
    profile_data: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update user profile information.

    **Editable Fields:**
    - full_name
    - email
    - phone

    **Non-Editable Fields:**
    - username (permanent, cannot be changed)
    - role (managed separately through role change endpoints)

    **Example Request:**
    ```json
    {
        "full_name": "John Doe",
        "email": "john.doe@example.com",
        "phone": "1234567890"
    }
    ```
    """
    profile_service = ProfileService(db)

    # Convert Pydantic model to dict
    update_dict = profile_data.model_dump(exclude_unset=True)

    result = profile_service.update_profile(
        user_id=current_user.id,
        update_data=update_dict
    )

    return ProfileStatusResponse(**result)
