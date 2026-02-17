"""
Branding Service
Business logic for organization branding management
"""

from sqlalchemy.orm import Session
from fastapi import HTTPException, status, UploadFile
from typing import Optional, Dict, Any
import uuid
import os
from datetime import datetime
from pathlib import Path

from app.models.organization_branding import OrganizationBranding
from app.models.audit_log import AuditLog
from app.schemas.branding import BrandingColors
from app.config import settings


# Audit actions
AUDIT_ACTION_BRANDING_UPDATED = "branding_updated"
AUDIT_ACTION_LOGO_UPLOADED = "logo_uploaded"
AUDIT_ACTION_LOGO_DELETED = "logo_deleted"
ENTITY_TYPE_BRANDING = "branding"

# Logo upload constants
ALLOWED_LOGO_TYPES = {"image/png", "image/jpeg", "image/jpg", "image/svg+xml"}
ALLOWED_LOGO_EXTENSIONS = {".png", ".jpg", ".jpeg", ".svg"}
MAX_LOGO_SIZE = 2 * 1024 * 1024  # 2MB


class BrandingService:
    """Service for organization branding operations"""

    def __init__(self, db: Session):
        self.db = db

    def get_branding(self, org_id: uuid.UUID) -> OrganizationBranding:
        """
        Get organization branding, create default if not exists.

        Args:
            org_id: Organization UUID

        Returns:
            OrganizationBranding instance

        Raises:
            HTTPException: If organization doesn't exist
        """
        # Check if branding exists
        branding = self.db.query(OrganizationBranding).filter(
            OrganizationBranding.organization_id == org_id
        ).first()

        # Create default branding if not exists
        if not branding:
            branding = OrganizationBranding(
                id=uuid.uuid4(),
                organization_id=org_id
            )
            self.db.add(branding)
            self.db.commit()
            self.db.refresh(branding)

        return branding

    def update_branding(
        self,
        org_id: uuid.UUID,
        user_id: uuid.UUID,
        colors: Optional[BrandingColors] = None,
        theme_config: Optional[Dict[str, Any]] = None
    ) -> OrganizationBranding:
        """
        Update organization branding colors and theme config.

        Args:
            org_id: Organization UUID
            user_id: User making the update
            colors: Updated color configuration
            theme_config: Additional theme configuration

        Returns:
            Updated OrganizationBranding instance

        Raises:
            HTTPException: If branding not found
        """
        branding = self.get_branding(org_id)

        # Track what changed
        changes = {}

        # Update colors if provided
        if colors:
            color_changes = {}
            if colors.primary_color != branding.primary_color:
                color_changes['primary_color'] = {'old': branding.primary_color, 'new': colors.primary_color}
                branding.primary_color = colors.primary_color
            if colors.primary_dark != branding.primary_dark:
                color_changes['primary_dark'] = {'old': branding.primary_dark, 'new': colors.primary_dark}
                branding.primary_dark = colors.primary_dark
            if colors.primary_light != branding.primary_light:
                color_changes['primary_light'] = {'old': branding.primary_light, 'new': colors.primary_light}
                branding.primary_light = colors.primary_light
            if colors.secondary_color != branding.secondary_color:
                color_changes['secondary_color'] = {'old': branding.secondary_color, 'new': colors.secondary_color}
                branding.secondary_color = colors.secondary_color
            if colors.accent_color != branding.accent_color:
                color_changes['accent_color'] = {'old': branding.accent_color, 'new': colors.accent_color}
                branding.accent_color = colors.accent_color
            if colors.background_primary != branding.background_primary:
                color_changes['background_primary'] = {'old': branding.background_primary, 'new': colors.background_primary}
                branding.background_primary = colors.background_primary
            if colors.background_secondary != branding.background_secondary:
                color_changes['background_secondary'] = {'old': branding.background_secondary, 'new': colors.background_secondary}
                branding.background_secondary = colors.background_secondary

            if color_changes:
                changes['colors'] = color_changes

        # Update theme_config if provided
        if theme_config is not None:
            changes['theme_config'] = {'old': branding.theme_config, 'new': theme_config}
            branding.theme_config = theme_config

        # Update metadata
        branding.updated_by = user_id
        branding.updated_at = datetime.utcnow()

        self.db.commit()
        self.db.refresh(branding)

        # Audit log
        if changes:
            audit_log = AuditLog(
                id=uuid.uuid4(),
                user_id=user_id,
                organization_id=org_id,
                entity_type=ENTITY_TYPE_BRANDING,
                entity_id=branding.id,
                action=AUDIT_ACTION_BRANDING_UPDATED,
                details=changes
            )
            self.db.add(audit_log)
            self.db.commit()

        return branding

    def upload_logo(
        self,
        org_id: uuid.UUID,
        user_id: uuid.UUID,
        file: UploadFile
    ) -> OrganizationBranding:
        """
        Upload logo for organization branding.

        Args:
            org_id: Organization UUID
            user_id: User uploading the logo
            file: Logo file

        Returns:
            Updated OrganizationBranding instance

        Raises:
            HTTPException: If file validation fails
        """
        # Validate file type
        if file.content_type not in ALLOWED_LOGO_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid file type. Allowed types: PNG, JPG, JPEG, SVG"
            )

        # Validate file extension
        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in ALLOWED_LOGO_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid file extension. Allowed extensions: .png, .jpg, .jpeg, .svg"
            )

        # Read file content to check size
        file_content = file.file.read()
        file_size = len(file_content)

        if file_size > MAX_LOGO_SIZE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File size exceeds maximum allowed size of {MAX_LOGO_SIZE / 1024 / 1024}MB"
            )

        # Get branding
        branding = self.get_branding(org_id)

        # Delete old logo if exists
        if branding.logo_url:
            self._delete_logo_file(branding.logo_url)

        # Create upload directory structure
        org_logo_dir = Path(settings.UPLOAD_DIR) / "logos" / str(org_id)
        org_logo_dir.mkdir(parents=True, exist_ok=True)

        # Generate unique filename
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        filename = f"logo_{timestamp}{file_ext}"
        file_path = org_logo_dir / filename

        # Save file
        with open(file_path, "wb") as f:
            f.write(file_content)

        # Update branding
        branding.logo_url = f"/uploads/logos/{org_id}/{filename}"
        branding.logo_filename = filename
        branding.logo_size_bytes = file_size
        branding.logo_uploaded_at = datetime.utcnow()
        branding.updated_by = user_id
        branding.updated_at = datetime.utcnow()

        self.db.commit()
        self.db.refresh(branding)

        # Audit log
        audit_log = AuditLog(
            id=uuid.uuid4(),
            user_id=user_id,
            organization_id=org_id,
            entity_type=ENTITY_TYPE_BRANDING,
            entity_id=branding.id,
            action=AUDIT_ACTION_LOGO_UPLOADED,
            details={
                'filename': filename,
                'size_bytes': file_size,
                'content_type': file.content_type
            }
        )
        self.db.add(audit_log)
        self.db.commit()

        return branding

    def delete_logo(
        self,
        org_id: uuid.UUID,
        user_id: uuid.UUID
    ) -> OrganizationBranding:
        """
        Delete logo from organization branding.

        Args:
            org_id: Organization UUID
            user_id: User deleting the logo

        Returns:
            Updated OrganizationBranding instance

        Raises:
            HTTPException: If branding not found or logo doesn't exist
        """
        branding = self.get_branding(org_id)

        if not branding.logo_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No logo found to delete"
            )

        # Delete file
        old_filename = branding.logo_filename
        self._delete_logo_file(branding.logo_url)

        # Update branding
        branding.logo_url = None
        branding.logo_filename = None
        branding.logo_size_bytes = None
        branding.logo_uploaded_at = None
        branding.updated_by = user_id
        branding.updated_at = datetime.utcnow()

        self.db.commit()
        self.db.refresh(branding)

        # Audit log
        audit_log = AuditLog(
            id=uuid.uuid4(),
            user_id=user_id,
            organization_id=org_id,
            entity_type=ENTITY_TYPE_BRANDING,
            entity_id=branding.id,
            action=AUDIT_ACTION_LOGO_DELETED,
            details={'filename': old_filename}
        )
        self.db.add(audit_log)
        self.db.commit()

        return branding

    def _delete_logo_file(self, logo_url: str) -> None:
        """
        Delete logo file from filesystem.

        Args:
            logo_url: Logo URL (e.g., /uploads/logos/{org_id}/{filename})
        """
        if not logo_url:
            return

        # Convert URL to file path
        # URL format: /uploads/logos/{org_id}/{filename}
        # Remove leading slash and convert to path
        relative_path = logo_url.lstrip('/')
        file_path = Path(relative_path)

        # Delete file if exists
        if file_path.exists():
            try:
                file_path.unlink()
            except Exception as e:
                # Log error but don't fail the operation
                print(f"Error deleting logo file {file_path}: {e}")
