"""
Organization Branding API Endpoints
Handles white-label branding operations including logo and color customization.
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
import uuid

from app.database import get_db
from app.dependencies import get_current_user, get_current_organization
from app.models.user import User
from app.services.branding_service import BrandingService
from app.schemas.branding import (
    BrandingUpdateRequest,
    BrandingResponse,
    LogoUploadResponse
)
from app.core.permissions import require_capability, AccessLevel


router = APIRouter()


@router.get(
    "",
    response_model=BrandingResponse,
    summary="Get organization branding",
    description="Get current organization's branding configuration. All organization members can view."
)
def get_branding(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db)
):
    """
    Get organization branding configuration.

    Returns logo, colors, and theme configuration.
    All organization members can view branding.
    """
    service = BrandingService(db)
    branding = service.get_branding(uuid.UUID(org_id))

    return BrandingResponse(**branding.to_dict())


@router.put(
    "",
    response_model=BrandingResponse,
    summary="Update organization branding",
    description="Update colors and theme configuration. Owner only."
)
def update_branding(
    branding_data: BrandingUpdateRequest,
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("organization.manage", AccessLevel.FULL))
):
    """
    Update organization branding colors and theme configuration.

    Required capability: organization.manage (FULL access - Owner only)
    """
    service = BrandingService(db)

    branding = service.update_branding(
        org_id=uuid.UUID(org_id),
        user_id=current_user.id,
        colors=branding_data.colors,
        theme_config=branding_data.theme_config
    )

    return BrandingResponse(**branding.to_dict())


@router.post(
    "/logo",
    response_model=LogoUploadResponse,
    summary="Upload organization logo",
    description="Upload logo image (PNG, JPG, JPEG, SVG). Max 2MB. Owner only."
)
def upload_logo(
    file: UploadFile = File(..., description="Logo file (PNG, JPG, JPEG, SVG, max 2MB)"),
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("organization.manage", AccessLevel.FULL))
):
    """
    Upload organization logo.

    Supported formats: PNG, JPG, JPEG, SVG
    Maximum size: 2MB
    Previous logo will be automatically deleted.

    Required capability: organization.manage (FULL access - Owner only)
    """
    service = BrandingService(db)

    branding = service.upload_logo(
        org_id=uuid.UUID(org_id),
        user_id=current_user.id,
        file=file
    )

    return LogoUploadResponse(
        success=True,
        message="Logo uploaded successfully",
        logo_url=branding.logo_url,
        filename=branding.logo_filename,
        size_bytes=branding.logo_size_bytes
    )


@router.delete(
    "/logo",
    response_model=LogoUploadResponse,
    summary="Delete organization logo",
    description="Delete current organization logo. Owner only."
)
def delete_logo(
    current_user: User = Depends(get_current_user),
    org_id: str = Depends(get_current_organization),
    db: Session = Depends(get_db),
    _: None = Depends(require_capability("organization.manage", AccessLevel.FULL))
):
    """
    Delete organization logo.

    Removes the logo file and clears logo information from branding.

    Required capability: organization.manage (FULL access - Owner only)
    """
    service = BrandingService(db)

    service.delete_logo(
        org_id=uuid.UUID(org_id),
        user_id=current_user.id
    )

    return LogoUploadResponse(
        success=True,
        message="Logo deleted successfully"
    )
