"""
Custom Roles API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User
from app.services.custom_role_service import CustomRoleService
from app.services.template_service import TemplateService
from app.core.permissions import require_capability, require_role
from app.models.capability import AccessLevel

router = APIRouter()


# Pydantic schemas
class CreateCustomRoleRequest(BaseModel):
    role_name: str
    description: Optional[str] = None
    capabilities: dict  # {capability_key: access_level}


class CreateFromTemplateRequest(BaseModel):
    role_name: str
    template_keys: List[str]
    description: Optional[str] = None
    customizations: Optional[dict] = None
    merge_strategy: str = "union"


class UpdateCustomRoleRequest(BaseModel):
    role_name: Optional[str] = None
    description: Optional[str] = None
    capabilities: Optional[dict] = None


class AddCapabilityRequest(BaseModel):
    capability_key: str
    access_level: str
    constraints: Optional[dict] = None


class BulkCapabilitiesRequest(BaseModel):
    capabilities: List[dict]  # [{capability_key, access_level, constraints}]


class SaveAsTemplateRequest(BaseModel):
    template_name: str
    template_description: Optional[str] = None


# API Endpoints
@router.get("/", tags=["Custom Roles"])
def get_all_custom_roles(
    include_templates: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.view", AccessLevel.VIEW))
):
    """Get all custom roles"""
    custom_role_service = CustomRoleService(db)
    custom_roles = custom_role_service.get_all_custom_roles(include_templates=include_templates)

    return {
        "success": True,
        "count": len(custom_roles),
        "custom_roles": custom_roles
    }


@router.post("/", tags=["Custom Roles"])
def create_custom_role(
    request: CreateCustomRoleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.create", AccessLevel.FULL))
):
    """Create a new custom role from scratch"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.create_custom_role(
            role_name=request.role_name,
            description=request.description,
            capabilities=request.capabilities,
            created_by=str(current_user.id)
        )

        return {
            "success": True,
            "message": "Custom role created successfully",
            "custom_role": custom_role
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/from-template", tags=["Custom Roles"])
def create_from_template(
    request: CreateFromTemplateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.create", AccessLevel.FULL))
):
    """Create a custom role from one or more templates"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.create_from_template(
            role_name=request.role_name,
            template_keys=request.template_keys,
            description=request.description,
            customizations=request.customizations,
            merge_strategy=request.merge_strategy,
            created_by=str(current_user.id)
        )

        return {
            "success": True,
            "message": "Custom role created from template successfully",
            "custom_role": custom_role
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{custom_role_id}", tags=["Custom Roles"])
def get_custom_role(
    custom_role_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.view", AccessLevel.VIEW))
):
    """Get custom role details"""
    custom_role_service = CustomRoleService(db)
    custom_role = custom_role_service.get_custom_role(custom_role_id)

    if not custom_role:
        raise HTTPException(status_code=404, detail="Custom role not found")

    return {
        "success": True,
        "custom_role": custom_role
    }


@router.put("/{custom_role_id}", tags=["Custom Roles"])
def update_custom_role(
    custom_role_id: str,
    request: UpdateCustomRoleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.edit", AccessLevel.FULL))
):
    """Update custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.update_custom_role(
            custom_role_id=custom_role_id,
            role_name=request.role_name,
            description=request.description,
            capabilities=request.capabilities
        )

        return {
            "success": True,
            "message": "Custom role updated successfully",
            "custom_role": custom_role
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{custom_role_id}", tags=["Custom Roles"])
def delete_custom_role(
    custom_role_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.delete", AccessLevel.FULL))
):
    """Delete custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        success = custom_role_service.delete_custom_role(custom_role_id)

        if success:
            return {
                "success": True,
                "message": "Custom role deleted successfully"
            }
        else:
            raise HTTPException(status_code=404, detail="Custom role not found")

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{custom_role_id}/clone", tags=["Custom Roles"])
def clone_custom_role(
    custom_role_id: str,
    new_role_name: str = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.create", AccessLevel.FULL))
):
    """Clone an existing custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.clone_custom_role(
            custom_role_id=custom_role_id,
            new_role_name=new_role_name,
            created_by=str(current_user.id)
        )

        return {
            "success": True,
            "message": "Custom role cloned successfully",
            "custom_role": custom_role
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{custom_role_id}/capabilities", tags=["Custom Roles"])
def get_custom_role_capabilities(
    custom_role_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.view", AccessLevel.VIEW))
):
    """Get all capabilities for a custom role"""
    custom_role_service = CustomRoleService(db)
    custom_role = custom_role_service.get_custom_role(custom_role_id)

    if not custom_role:
        raise HTTPException(status_code=404, detail="Custom role not found")

    return {
        "success": True,
        "custom_role_id": custom_role_id,
        "capabilities": custom_role["capabilities"]
    }


@router.post("/{custom_role_id}/capabilities", tags=["Custom Roles"])
def add_capability(
    custom_role_id: str,
    request: AddCapabilityRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.capability.assign", AccessLevel.FULL))
):
    """Add a capability to custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.add_capability_to_role(
            custom_role_id=custom_role_id,
            capability_key=request.capability_key,
            access_level=request.access_level,
            constraints=request.constraints
        )

        return {
            "success": True,
            "message": "Capability added successfully",
            "custom_role": custom_role
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{custom_role_id}/capabilities/{capability_key}", tags=["Custom Roles"])
def remove_capability(
    custom_role_id: str,
    capability_key: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.capability.revoke", AccessLevel.FULL))
):
    """Remove a capability from custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.remove_capability_from_role(
            custom_role_id=custom_role_id,
            capability_key=capability_key
        )

        return {
            "success": True,
            "message": "Capability removed successfully",
            "custom_role": custom_role
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/{custom_role_id}/capabilities/bulk", tags=["Custom Roles"])
def bulk_update_capabilities(
    custom_role_id: str,
    request: BulkCapabilitiesRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.capability.assign", AccessLevel.FULL))
):
    """Bulk update capabilities for custom role"""
    custom_role_service = CustomRoleService(db)

    try:
        custom_role = custom_role_service.bulk_update_capabilities(
            custom_role_id=custom_role_id,
            capabilities=request.capabilities
        )

        return {
            "success": True,
            "message": "Capabilities updated successfully",
            "custom_role": custom_role
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/{custom_role_id}/impact-analysis", tags=["Custom Roles"])
def get_impact_analysis(
    custom_role_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.view", AccessLevel.VIEW))
):
    """Analyze impact of role changes"""
    custom_role_service = CustomRoleService(db)
    custom_role = custom_role_service.get_custom_role(custom_role_id)

    if not custom_role:
        raise HTTPException(status_code=404, detail="Custom role not found")

    impact = custom_role_service.get_impact_analysis(custom_role["role_id"])

    return {
        "success": True,
        "impact_analysis": impact
    }


@router.post("/{custom_role_id}/save-as-template", tags=["Custom Roles"])
def save_as_template(
    custom_role_id: str,
    request: SaveAsTemplateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_capability("role.custom.create", AccessLevel.FULL))
):
    """Save custom role as a reusable template"""
    template_service = TemplateService(db)
    custom_role_service = CustomRoleService(db)

    # Get custom role first
    custom_role = custom_role_service.get_custom_role(custom_role_id)
    if not custom_role:
        raise HTTPException(status_code=404, detail="Custom role not found")

    try:
        template = template_service.save_as_template(
            role_id=custom_role["role_id"],
            template_name=request.template_name,
            template_description=request.template_description
        )

        return {
            "success": True,
            "message": "Custom role saved as template",
            "template": template
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
