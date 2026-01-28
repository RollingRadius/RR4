"""
Capability Service
Business logic for capability management
"""
from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models import Capability, RoleCapability, User, Role
from app.models.capability import FeatureCategory, AccessLevel
from app.core.capabilities import ALL_CAPABILITIES, CAPABILITIES_DICT, get_capabilities_by_category


class CapabilityService:
    """Service for managing capabilities"""

    def __init__(self, db: Session):
        self.db = db

    def seed_capabilities(self) -> int:
        """
        Seed all hardcoded capabilities into database.
        Should be run once during initial setup or migration.
        Returns number of capabilities seeded.
        """
        seeded_count = 0

        for cap_def in ALL_CAPABILITIES:
            # Check if capability already exists
            existing = self.db.query(Capability).filter(
                Capability.capability_key == cap_def.key
            ).first()

            if not existing:
                capability = Capability(
                    capability_key=cap_def.key,
                    feature_category=cap_def.category,
                    capability_name=cap_def.name,
                    description=cap_def.description,
                    access_levels=cap_def.access_levels,
                    is_system_critical=cap_def.is_system_critical
                )
                self.db.add(capability)
                seeded_count += 1

        try:
            self.db.commit()
            return seeded_count
        except IntegrityError:
            self.db.rollback()
            raise

    def get_all_capabilities(self) -> List[Dict]:
        """Get all capabilities"""
        capabilities = self.db.query(Capability).all()
        return [cap.to_dict() for cap in capabilities]

    def get_capabilities_by_category(self, category: FeatureCategory) -> List[Dict]:
        """Get capabilities by feature category"""
        capabilities = self.db.query(Capability).filter(
            Capability.feature_category == category
        ).all()
        return [cap.to_dict() for cap in capabilities]

    def get_capability_by_key(self, capability_key: str) -> Optional[Dict]:
        """Get capability by key"""
        capability = self.db.query(Capability).filter(
            Capability.capability_key == capability_key
        ).first()
        return capability.to_dict() if capability else None

    def get_categories(self) -> List[Dict]:
        """Get all feature categories with capability counts"""
        categories = []
        for category in FeatureCategory:
            count = self.db.query(Capability).filter(
                Capability.feature_category == category
            ).count()
            categories.append({
                "category": category.value,
                "count": count
            })
        return categories

    def search_capabilities(self, keyword: str) -> List[Dict]:
        """Search capabilities by keyword"""
        capabilities = self.db.query(Capability).filter(
            (Capability.capability_key.ilike(f"%{keyword}%")) |
            (Capability.capability_name.ilike(f"%{keyword}%")) |
            (Capability.description.ilike(f"%{keyword}%"))
        ).all()
        return [cap.to_dict() for cap in capabilities]

    def get_user_capabilities(self, user_id: str, organization_id: str) -> Dict[str, Dict]:
        """
        Get user's effective capabilities based on their role in the organization.
        Returns dict of {capability_key: {access_level, constraints}}
        """
        # Get user's role in organization
        from app.models import UserOrganization
        user_org = self.db.query(UserOrganization).filter(
            UserOrganization.user_id == user_id,
            UserOrganization.company_id == organization_id
        ).first()

        if not user_org or not user_org.role:
            return {}

        # Get role capabilities
        role_capabilities = self.db.query(RoleCapability).filter(
            RoleCapability.role_id == user_org.role_id
        ).all()

        # Build capabilities dict
        capabilities = {}
        for role_cap in role_capabilities:
            capabilities[role_cap.capability_key] = {
                "access_level": role_cap.access_level,
                "constraints": role_cap.constraints
            }

        return capabilities

    def check_user_capability(
        self,
        user_id: str,
        organization_id: str,
        capability_key: str,
        required_level: str = AccessLevel.VIEW
    ) -> bool:
        """
        Check if user has a specific capability with required access level.
        Access levels hierarchy: none < view < limited < full
        """
        user_caps = self.get_user_capabilities(user_id, organization_id)

        if capability_key not in user_caps:
            return False

        user_level = user_caps[capability_key]["access_level"]

        # Check access level hierarchy
        level_hierarchy = {
            AccessLevel.NONE: 0,
            AccessLevel.VIEW: 1,
            AccessLevel.LIMITED: 2,
            AccessLevel.FULL: 3
        }

        return level_hierarchy.get(user_level, 0) >= level_hierarchy.get(required_level, 0)

    def assign_capability_to_role(
        self,
        role_id: str,
        capability_key: str,
        access_level: str,
        constraints: Optional[Dict] = None,
        granted_by: Optional[str] = None
    ) -> Dict:
        """Assign a capability to a role"""
        # Check if capability exists
        capability = self.db.query(Capability).filter(
            Capability.capability_key == capability_key
        ).first()

        if not capability:
            raise ValueError(f"Capability {capability_key} not found")

        # Check if access level is valid for this capability
        if access_level not in capability.access_levels:
            raise ValueError(f"Invalid access level {access_level} for capability {capability_key}")

        # Check if already assigned
        existing = self.db.query(RoleCapability).filter(
            RoleCapability.role_id == role_id,
            RoleCapability.capability_key == capability_key
        ).first()

        if existing:
            # Update existing
            existing.access_level = access_level
            existing.constraints = constraints
            role_capability = existing
        else:
            # Create new
            role_capability = RoleCapability(
                role_id=role_id,
                capability_key=capability_key,
                access_level=access_level,
                constraints=constraints,
                granted_by=granted_by
            )
            self.db.add(role_capability)

        self.db.commit()
        self.db.refresh(role_capability)
        return role_capability.to_dict()

    def revoke_capability_from_role(self, role_id: str, capability_key: str) -> bool:
        """Revoke a capability from a role"""
        role_capability = self.db.query(RoleCapability).filter(
            RoleCapability.role_id == role_id,
            RoleCapability.capability_key == capability_key
        ).first()

        if role_capability:
            self.db.delete(role_capability)
            self.db.commit()
            return True

        return False

    def get_role_capabilities(self, role_id: str) -> List[Dict]:
        """Get all capabilities for a role"""
        role_capabilities = self.db.query(RoleCapability).filter(
            RoleCapability.role_id == role_id
        ).all()

        result = []
        for role_cap in role_capabilities:
            cap_dict = role_cap.to_dict()
            # Add capability details
            capability = self.db.query(Capability).filter(
                Capability.capability_key == role_cap.capability_key
            ).first()
            if capability:
                cap_dict["capability_name"] = capability.capability_name
                cap_dict["feature_category"] = capability.feature_category.value
                cap_dict["description"] = capability.description

            result.append(cap_dict)

        return result

    def bulk_assign_capabilities(
        self,
        role_id: str,
        capabilities: List[Dict],
        granted_by: Optional[str] = None
    ) -> int:
        """
        Bulk assign capabilities to a role.
        capabilities: List[{capability_key, access_level, constraints}]
        Returns number of capabilities assigned.
        """
        count = 0
        for cap in capabilities:
            try:
                self.assign_capability_to_role(
                    role_id=role_id,
                    capability_key=cap["capability_key"],
                    access_level=cap["access_level"],
                    constraints=cap.get("constraints"),
                    granted_by=granted_by
                )
                count += 1
            except Exception as e:
                # Log error but continue
                print(f"Error assigning capability {cap.get('capability_key')}: {e}")

        return count
