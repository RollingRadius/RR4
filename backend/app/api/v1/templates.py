"""
Role Templates API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User
from app.services.template_service import TemplateService
from app.core.permissions import require_capability, require_role
from app.models.capability import AccessLevel

router = APIRouter()


# Pydantic schemas
class MergeTemplatesRequest(BaseModel):
    template_keys: List[str]
    strategy: str = "union"


class CompareTemplatesRequest(BaseModel):
    template_keys: List[str]


# API Endpoints
@router.get("/predefined", tags=["Templates"])
async def get_all_predefined_templates(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.view", AccessLevel.VIEW))
):
    """Get all predefined role templates"""
    template_service = TemplateService(db)
    templates = template_service.get_all_predefined_templates()

    return {
        "success": True,
        "count": len(templates),
        "templates": templates
    }


@router.get("/predefined/{role_key}", tags=["Templates"])
async def get_predefined_template(
    role_key: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.view", AccessLevel.VIEW))
):
    """Get a specific predefined role template"""
    template_service = TemplateService(db)
    template = template_service.get_predefined_template(role_key)

    if not template:
        raise HTTPException(status_code=404, detail="Template not found")

    return {
        "success": True,
        "template": template
    }


@router.post("/merge", tags=["Templates"])
async def merge_templates(
    request: MergeTemplatesRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.use", AccessLevel.VIEW))
):
    """
    Merge multiple templates into one capability set.
    strategy: "union" (combine all) or "intersection" (only common)
    """
    template_service = TemplateService(db)

    try:
        merged_capabilities = template_service.merge_templates(
            template_keys=request.template_keys,
            strategy=request.strategy
        )

        return {
            "success": True,
            "merged_from": request.template_keys,
            "strategy": request.strategy,
            "capability_count": len(merged_capabilities),
            "capabilities": merged_capabilities
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/compare", tags=["Templates"])
async def compare_templates(
    request: CompareTemplatesRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.view", AccessLevel.VIEW))
):
    """Compare multiple templates side-by-side"""
    if len(request.template_keys) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 templates to compare")

    template_service = TemplateService(db)

    try:
        comparison = template_service.compare_templates(request.template_keys)

        return {
            "success": True,
            "comparison": comparison
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/custom", tags=["Templates"])
async def get_custom_templates(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.view", AccessLevel.VIEW))
):
    """Get all saved custom role templates"""
    template_service = TemplateService(db)
    templates = template_service.get_custom_templates()

    return {
        "success": True,
        "count": len(templates),
        "templates": templates
    }


@router.get("/custom/{custom_role_id}/sources", tags=["Templates"])
async def get_template_sources(
    custom_role_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.template.view", AccessLevel.VIEW))
):
    """Get the source templates used to create a custom role"""
    template_service = TemplateService(db)

    try:
        sources = template_service.get_template_sources(custom_role_id)

        return {
            "success": True,
            "custom_role_id": custom_role_id,
            "source_templates": sources
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/seed", tags=["Templates"])
async def seed_predefined_roles(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["super_admin"]))
):
    """
    Seed predefined role templates into database.
    Super Admin only. Should be run once during setup.
    """
    template_service = TemplateService(db)

    try:
        count = template_service.seed_predefined_roles()
        return {
            "success": True,
            "message": f"Successfully seeded {count} predefined roles",
            "total_roles": count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
