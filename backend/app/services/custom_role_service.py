"""
Custom Role Service
Business logic for custom role management
"""
from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
import uuid

from app.models import Role, CustomRole, UserOrganization
from app.services.capability_service import CapabilityService
from app.services.template_service import TemplateService


class CustomRoleService:
    """Service for managing custom roles"""

    def __init__(self, db: Session):
        self.db = db
        self.capability_service = CapabilityService(db)
        self.template_service = TemplateService(db)

    def create_custom_role(
        self,
        role_name: str,
        description: Optional[str] = None,
        template_sources: Optional[List[str]] = None,
        capabilities: Optional[Dict[str, str]] = None,
        customizations: Optional[Dict] = None,
        created_by: Optional[str] = None
    ) -> Dict:
        """
        Create a new custom role.
        Can be created from templates or from scratch.
        """
        # Create Role entry
        role = Role(
            role_name=role_name,
            role_key=f"custom_{uuid.uuid4().hex[:8]}",
            description=description,
            is_system_role=False
        )
        self.db.add(role)
        self.db.flush()  # Get role ID

        # Create CustomRole entry
        custom_role = CustomRole(
            role_id=role.id,
            template_sources=template_sources or [],
            is_template=False,
            customizations=customizations,
            created_by=created_by
        )
        self.db.add(custom_role)
        self.db.flush()

        # Assign capabilities
        if capabilities:
            for cap_key, access_level in capabilities.items():
                try:
                    self.capability_service.assign_capability_to_role(
                        role_id=str(role.id),
                        capability_key=cap_key,
                        access_level=access_level,
                        granted_by=created_by
                    )
                except Exception as e:
                    print(f"Error assigning capability {cap_key}: {e}")

        self.db.commit()
        self.db.refresh(role)
        self.db.refresh(custom_role)

        return self.get_custom_role(str(custom_role.id))

    def create_from_template(
        self,
        role_name: str,
        template_keys: List[str],
        description: Optional[str] = None,
        customizations: Optional[Dict[str, str]] = None,
        merge_strategy: str = "union",
        created_by: Optional[str] = None
    ) -> Dict:
        """
        Create a custom role from one or more predefined templates.
        """
        # Merge templates
        base_capabilities = self.template_service.merge_templates(
            template_keys=template_keys,
            strategy=merge_strategy
        )

        # Apply customizations if provided
        if customizations:
            final_capabilities = self.template_service.apply_customizations(
                base_capabilities=base_capabilities,
                customizations=customizations
            )
        else:
            final_capabilities = base_capabilities

        # Create custom role
        return self.create_custom_role(
            role_name=role_name,
            description=description,
            template_sources=template_keys,
            capabilities=final_capabilities,
            customizations=customizations,
            created_by=created_by
        )

    def get_custom_role(self, custom_role_id: str) -> Dict:
        """Get custom role details"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            return None

        role = self.db.query(Role).filter(
            Role.id == custom_role.role_id
        ).first()

        if not role:
            return None

        capabilities = self.capability_service.get_role_capabilities(str(role.id))

        return {
            "custom_role_id": str(custom_role.id),
            "role_id": str(role.id),
            "role_name": role.role_name,
            "role_key": role.role_key,
            "description": role.description,
            "template_sources": custom_role.template_sources,
            "is_template": custom_role.is_template,
            "template_name": custom_role.template_name,
            "template_description": custom_role.template_description,
            "customizations": custom_role.customizations,
            "capability_count": len(capabilities),
            "capabilities": capabilities,
            "created_by": str(custom_role.created_by) if custom_role.created_by else None,
            "created_at": custom_role.created_at.isoformat() if custom_role.created_at else None,
            "updated_at": custom_role.updated_at.isoformat() if custom_role.updated_at else None
        }

    def get_all_custom_roles(self, include_templates: bool = False) -> List[Dict]:
        """Get all custom roles"""
        query = self.db.query(CustomRole)

        if not include_templates:
            query = query.filter(CustomRole.is_template == False)

        custom_roles = query.all()

        result = []
        for custom_role in custom_roles:
            role_data = self.get_custom_role(str(custom_role.id))
            if role_data:
                result.append(role_data)

        return result

    def update_custom_role(
        self,
        custom_role_id: str,
        role_name: Optional[str] = None,
        description: Optional[str] = None,
        capabilities: Optional[Dict[str, str]] = None
    ) -> Dict:
        """Update custom role"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            raise ValueError("Custom role not found")

        role = self.db.query(Role).filter(
            Role.id == custom_role.role_id
        ).first()

        if not role:
            raise ValueError("Role not found")

        # Update role details
        if role_name:
            role.role_name = role_name
        if description:
            role.description = description

        # Update capabilities if provided
        if capabilities is not None:
            # Remove all existing capabilities
            from app.models import RoleCapability
            self.db.query(RoleCapability).filter(
                RoleCapability.role_id == role.id
            ).delete()

            # Add new capabilities
            for cap_key, access_level in capabilities.items():
                self.capability_service.assign_capability_to_role(
                    role_id=str(role.id),
                    capability_key=cap_key,
                    access_level=access_level
                )

        self.db.commit()
        return self.get_custom_role(custom_role_id)

    def delete_custom_role(self, custom_role_id: str) -> bool:
        """Delete custom role"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            return False

        # Check if role is in use
        users_count = self.db.query(UserOrganization).filter(
            UserOrganization.role_id == custom_role.role_id
        ).count()

        if users_count > 0:
            raise ValueError(f"Cannot delete role. {users_count} users are assigned this role.")

        # Delete role (cascade will delete custom_role and role_capabilities)
        role = self.db.query(Role).filter(
            Role.id == custom_role.role_id
        ).first()

        if role:
            self.db.delete(role)
            self.db.commit()
            return True

        return False

    def clone_custom_role(
        self,
        custom_role_id: str,
        new_role_name: str,
        created_by: Optional[str] = None
    ) -> Dict:
        """Clone an existing custom role"""
        source_role = self.get_custom_role(custom_role_id)

        if not source_role:
            raise ValueError("Source role not found")

        # Get capabilities
        capabilities = {
            cap["capability_key"]: cap["access_level"]
            for cap in source_role["capabilities"]
        }

        # Create new role
        return self.create_custom_role(
            role_name=new_role_name,
            description=f"Cloned from {source_role['role_name']}",
            template_sources=source_role["template_sources"],
            capabilities=capabilities,
            customizations=source_role.get("customizations"),
            created_by=created_by
        )

    def get_impact_analysis(self, role_id: str) -> Dict:
        """
        Analyze impact of role changes.
        Returns count of users who would be affected.
        """
        # Count users with this role
        users_count = self.db.query(UserOrganization).filter(
            UserOrganization.role_id == role_id
        ).count()

        # Get organizations using this role
        user_orgs = self.db.query(UserOrganization).filter(
            UserOrganization.role_id == role_id
        ).all()

        organizations = {}
        for user_org in user_orgs:
            org_id = str(user_org.company_id)
            if org_id not in organizations:
                organizations[org_id] = {
                    "organization_id": org_id,
                    "user_count": 0
                }
            organizations[org_id]["user_count"] += 1

        return {
            "role_id": role_id,
            "total_users_affected": users_count,
            "organizations_affected": len(organizations),
            "organization_breakdown": list(organizations.values())
        }

    def add_capability_to_role(
        self,
        custom_role_id: str,
        capability_key: str,
        access_level: str,
        constraints: Optional[Dict] = None
    ) -> Dict:
        """Add a single capability to custom role"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            raise ValueError("Custom role not found")

        self.capability_service.assign_capability_to_role(
            role_id=str(custom_role.role_id),
            capability_key=capability_key,
            access_level=access_level,
            constraints=constraints
        )

        return self.get_custom_role(custom_role_id)

    def remove_capability_from_role(
        self,
        custom_role_id: str,
        capability_key: str
    ) -> Dict:
        """Remove a capability from custom role"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            raise ValueError("Custom role not found")

        self.capability_service.revoke_capability_from_role(
            role_id=str(custom_role.role_id),
            capability_key=capability_key
        )

        return self.get_custom_role(custom_role_id)

    def bulk_update_capabilities(
        self,
        custom_role_id: str,
        capabilities: List[Dict]
    ) -> Dict:
        """
        Bulk update capabilities for custom role.
        capabilities: List[{capability_key, access_level, constraints}]
        """
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role:
            raise ValueError("Custom role not found")

        self.capability_service.bulk_assign_capabilities(
            role_id=str(custom_role.role_id),
            capabilities=capabilities
        )

        return self.get_custom_role(custom_role_id)
