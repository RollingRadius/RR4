"""
Template Service
Business logic for role template management
"""
from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
import uuid

from app.models import Role, RoleCapability, CustomRole
from app.core.role_templates import ROLE_TEMPLATES, ROLE_TEMPLATES_DICT, get_role_template
from app.services.capability_service import CapabilityService


class TemplateService:
    """Service for managing role templates"""

    def __init__(self, db: Session):
        self.db = db
        self.capability_service = CapabilityService(db)

    def seed_predefined_roles(self) -> int:
        """
        Seed predefined role templates into database.
        Creates Role entries and assigns capabilities.
        Returns number of roles seeded.
        """
        seeded_count = 0

        for template in ROLE_TEMPLATES:
            # Check if role already exists
            existing = self.db.query(Role).filter(
                Role.role_key == template.role_key
            ).first()

            if not existing:
                # Create role
                role = Role(
                    role_name=template.role_name,
                    role_key=template.role_key,
                    description=template.description,
                    is_system_role=True
                )
                self.db.add(role)
                self.db.flush()  # Get role ID

                # Assign capabilities
                for capability_key, access_level in template.capabilities.items():
                    role_capability = RoleCapability(
                        role_id=role.id,
                        capability_key=capability_key,
                        access_level=access_level
                    )
                    self.db.add(role_capability)

                seeded_count += 1

        try:
            self.db.commit()
            return seeded_count
        except IntegrityError:
            self.db.rollback()
            raise

    def get_all_predefined_templates(self) -> List[Dict]:
        """Get all predefined role templates with their capabilities"""
        result = []

        for template in ROLE_TEMPLATES:
            # Get role from database
            role = self.db.query(Role).filter(
                Role.role_key == template.role_key
            ).first()

            if role:
                capabilities = self.capability_service.get_role_capabilities(str(role.id))
                result.append({
                    "role_id": str(role.id),
                    "role_key": template.role_key,
                    "role_name": template.role_name,
                    "description": template.description,
                    "is_predefined": True,
                    "capability_count": len(capabilities),
                    "capabilities": capabilities
                })

        return result

    def get_predefined_template(self, role_key: str) -> Optional[Dict]:
        """Get a specific predefined role template"""
        template = get_role_template(role_key)
        if not template:
            return None

        role = self.db.query(Role).filter(
            Role.role_key == role_key
        ).first()

        if not role:
            return None

        capabilities = self.capability_service.get_role_capabilities(str(role.id))

        return {
            "role_id": str(role.id),
            "role_key": template.role_key,
            "role_name": template.role_name,
            "description": template.description,
            "is_predefined": True,
            "capability_count": len(capabilities),
            "capabilities": capabilities
        }

    def merge_templates(
        self,
        template_keys: List[str],
        strategy: str = "union"
    ) -> Dict[str, str]:
        """
        Merge multiple templates into one capability set.
        strategy: "union" (combine all) or "intersection" (only common)
        Returns dict of {capability_key: access_level}
        """
        if not template_keys:
            return {}

        # Get templates
        templates = [get_role_template(key) for key in template_keys]
        templates = [t for t in templates if t is not None]

        if not templates:
            return {}

        if strategy == "union":
            # Combine all capabilities, taking highest access level for duplicates
            merged = {}
            access_hierarchy = {"none": 0, "view": 1, "limited": 2, "full": 3}

            for template in templates:
                for cap_key, access_level in template.capabilities.items():
                    if cap_key not in merged:
                        merged[cap_key] = access_level
                    else:
                        # Keep higher access level
                        current_level = access_hierarchy.get(merged[cap_key], 0)
                        new_level = access_hierarchy.get(access_level, 0)
                        if new_level > current_level:
                            merged[cap_key] = access_level

            return merged

        elif strategy == "intersection":
            # Only keep capabilities common to all templates
            if len(templates) == 1:
                return templates[0].capabilities

            # Start with first template
            common_caps = set(templates[0].capabilities.keys())

            # Intersect with other templates
            for template in templates[1:]:
                common_caps &= set(template.capabilities.keys())

            # Build result with lowest access level
            merged = {}
            access_hierarchy = {"none": 0, "view": 1, "limited": 2, "full": 3}

            for cap_key in common_caps:
                levels = [template.capabilities[cap_key] for template in templates if cap_key in template.capabilities]
                # Use most restrictive (lowest) access level
                min_level = min(levels, key=lambda x: access_hierarchy.get(x, 0))
                merged[cap_key] = min_level

            return merged

        return {}

    def apply_customizations(
        self,
        base_capabilities: Dict[str, str],
        customizations: Dict[str, str]
    ) -> Dict[str, str]:
        """
        Apply customizations to base capabilities.
        customizations can override access levels or remove capabilities.
        """
        result = base_capabilities.copy()

        for cap_key, access_level in customizations.items():
            if access_level == "none" or access_level is None:
                # Remove capability
                result.pop(cap_key, None)
            else:
                # Add or update capability
                result[cap_key] = access_level

        return result

    def get_custom_templates(self) -> List[Dict]:
        """Get all saved custom role templates"""
        custom_roles = self.db.query(CustomRole).filter(
            CustomRole.is_template == True
        ).all()

        result = []
        for custom_role in custom_roles:
            role = self.db.query(Role).filter(
                Role.id == custom_role.role_id
            ).first()

            if role:
                capabilities = self.capability_service.get_role_capabilities(str(role.id))
                result.append({
                    "custom_role_id": str(custom_role.id),
                    "role_id": str(role.id),
                    "template_name": custom_role.template_name,
                    "template_description": custom_role.template_description,
                    "template_sources": custom_role.template_sources,
                    "capability_count": len(capabilities),
                    "capabilities": capabilities,
                    "created_at": custom_role.created_at.isoformat() if custom_role.created_at else None
                })

        return result

    def save_as_template(
        self,
        role_id: str,
        template_name: str,
        template_description: Optional[str] = None
    ) -> Dict:
        """Save a custom role as a reusable template"""
        # Get custom role
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.role_id == role_id
        ).first()

        if not custom_role:
            raise ValueError("Custom role not found")

        # Update to template
        custom_role.is_template = True
        custom_role.template_name = template_name
        custom_role.template_description = template_description

        self.db.commit()
        self.db.refresh(custom_role)

        return custom_role.to_dict()

    def compare_templates(self, template_keys: List[str]) -> Dict:
        """
        Compare multiple templates side-by-side.
        Returns differences and commonalities.
        """
        if len(template_keys) < 2:
            raise ValueError("Need at least 2 templates to compare")

        templates = [get_role_template(key) for key in template_keys]
        templates = [t for t in templates if t is not None]

        if len(templates) < 2:
            raise ValueError("Invalid template keys provided")

        # Get all unique capabilities
        all_caps = set()
        for template in templates:
            all_caps.update(template.capabilities.keys())

        # Build comparison matrix
        comparison = []
        common_caps = []
        different_caps = []

        for cap_key in sorted(all_caps):
            cap_data = {"capability_key": cap_key}
            access_levels = []

            for template in templates:
                level = template.capabilities.get(cap_key, "none")
                cap_data[template.role_key] = level
                access_levels.append(level)

            comparison.append(cap_data)

            # Check if common or different
            unique_levels = set(access_levels)
            if len(unique_levels) == 1 and "none" not in unique_levels:
                common_caps.append(cap_key)
            elif "none" not in unique_levels:
                different_caps.append(cap_key)

        return {
            "templates": [{"role_key": t.role_key, "role_name": t.role_name} for t in templates],
            "comparison": comparison,
            "common_capabilities": common_caps,
            "different_capabilities": different_caps,
            "common_count": len(common_caps),
            "different_count": len(different_caps)
        }

    def get_template_sources(self, custom_role_id: str) -> List[Dict]:
        """Get the source templates used to create a custom role"""
        custom_role = self.db.query(CustomRole).filter(
            CustomRole.id == custom_role_id
        ).first()

        if not custom_role or not custom_role.template_sources:
            return []

        sources = []
        for template_key in custom_role.template_sources:
            template = get_role_template(template_key)
            if template:
                sources.append({
                    "role_key": template.role_key,
                    "role_name": template.role_name,
                    "description": template.description
                })

        return sources
