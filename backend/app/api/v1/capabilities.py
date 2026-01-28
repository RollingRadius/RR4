"""
Capabilities API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User
from app.services.capability_service import CapabilityService
from app.core.permissions import require_capability, require_role
from app.models.capability import AccessLevel, FeatureCategory

router = APIRouter()


@router.get("/", tags=["Capabilities"])
async def get_all_capabilities(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all available capabilities.
    Requires authentication.
    """
    capability_service = CapabilityService(db)
    capabilities = capability_service.get_all_capabilities()

    return {
        "success": True,
        "total": len(capabilities),
        "capabilities": capabilities
    }


@router.get("/categories", tags=["Capabilities"])
async def get_capability_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all capability categories with counts"""
    capability_service = CapabilityService(db)
    categories = capability_service.get_categories()

    return {
        "success": True,
        "categories": categories
    }


@router.get("/category/{category}", tags=["Capabilities"])
async def get_capabilities_by_category(
    category: FeatureCategory,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get capabilities for a specific category"""
    capability_service = CapabilityService(db)
    capabilities = capability_service.get_capabilities_by_category(category)

    return {
        "success": True,
        "category": category.value,
        "count": len(capabilities),
        "capabilities": capabilities
    }


@router.get("/{capability_key}", tags=["Capabilities"])
async def get_capability(
    capability_key: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get capability details by key"""
    capability_service = CapabilityService(db)
    capability = capability_service.get_capability_by_key(capability_key)

    if not capability:
        raise HTTPException(status_code=404, detail="Capability not found")

    return {
        "success": True,
        "capability": capability
    }


@router.get("/search", tags=["Capabilities"])
async def search_capabilities(
    keyword: str = Query(..., min_length=2),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Search capabilities by keyword"""
    capability_service = CapabilityService(db)
    capabilities = capability_service.search_capabilities(keyword)

    return {
        "success": True,
        "keyword": keyword,
        "count": len(capabilities),
        "capabilities": capabilities
    }


@router.get("/user/me", tags=["Capabilities"])
async def get_my_capabilities(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user's effective capabilities"""
    if not hasattr(current_user, 'active_organization_id') or not current_user.active_organization_id:
        raise HTTPException(status_code=400, detail="No active organization")

    capability_service = CapabilityService(db)
    capabilities = capability_service.get_user_capabilities(
        user_id=str(current_user.id),
        organization_id=str(current_user.active_organization_id)
    )

    return {
        "success": True,
        "user_id": str(current_user.id),
        "organization_id": str(current_user.active_organization_id),
        "capabilities": capabilities
    }


@router.get("/user/{user_id}", tags=["Capabilities"])
async def get_user_capabilities(
    user_id: str,
    organization_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("user.view", AccessLevel.VIEW))
):
    """Get user's effective capabilities (admin only)"""
    if not organization_id and hasattr(current_user, 'active_organization_id'):
        organization_id = str(current_user.active_organization_id)

    if not organization_id:
        raise HTTPException(status_code=400, detail="Organization ID required")

    capability_service = CapabilityService(db)
    capabilities = capability_service.get_user_capabilities(
        user_id=user_id,
        organization_id=organization_id
    )

    return {
        "success": True,
        "user_id": user_id,
        "organization_id": organization_id,
        "capabilities": capabilities
    }


@router.get("/user/{user_id}/check/{capability_key}", tags=["Capabilities"])
async def check_user_capability(
    user_id: str,
    capability_key: str,
    required_level: str = Query(AccessLevel.VIEW),
    organization_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("user.view", AccessLevel.VIEW))
):
    """Check if user has specific capability"""
    if not organization_id and hasattr(current_user, 'active_organization_id'):
        organization_id = str(current_user.active_organization_id)

    if not organization_id:
        raise HTTPException(status_code=400, detail="Organization ID required")

    capability_service = CapabilityService(db)
    has_capability = capability_service.check_user_capability(
        user_id=user_id,
        organization_id=organization_id,
        capability_key=capability_key,
        required_level=required_level
    )

    return {
        "success": True,
        "user_id": user_id,
        "capability_key": capability_key,
        "required_level": required_level,
        "has_capability": has_capability
    }


@router.post("/seed", tags=["Capabilities"])
async def seed_capabilities(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["super_admin"]))
):
    """
    Seed hardcoded capabilities into database.
    Super Admin only. Should be run once during setup.
    """
    capability_service = CapabilityService(db)

    try:
        count = capability_service.seed_capabilities()
        return {
            "success": True,
            "message": f"Successfully seeded {count} capabilities",
            "total_capabilities": count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
