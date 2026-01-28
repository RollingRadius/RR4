"""
Seed Script for Capabilities and Role Templates
Run this script once to populate the database with hardcoded capabilities and predefined roles.
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.services.capability_service import CapabilityService
from app.services.template_service import TemplateService


def seed_all():
    """Seed capabilities and role templates"""
    db: Session = SessionLocal()

    try:
        print("=" * 60)
        print("SEEDING FLEET MANAGEMENT SYSTEM")
        print("=" * 60)

        # Seed capabilities
        print("\n1. Seeding Capabilities...")
        capability_service = CapabilityService(db)
        capability_count = capability_service.seed_capabilities()
        print(f"   ✓ Seeded {capability_count} capabilities")

        # Seed predefined roles
        print("\n2. Seeding Predefined Role Templates...")
        template_service = TemplateService(db)
        role_count = template_service.seed_predefined_roles()
        print(f"   ✓ Seeded {role_count} predefined roles")

        print("\n" + "=" * 60)
        print("SEEDING COMPLETED SUCCESSFULLY")
        print("=" * 60)
        print(f"\nTotal Capabilities: {capability_count}")
        print(f"Total Predefined Roles: {role_count}")
        print("\nYou can now use the capability-based permission system!")
        print("\nAPI Endpoints:")
        print("  - GET  /api/capabilities          - List all capabilities")
        print("  - GET  /api/templates/predefined  - List all role templates")
        print("  - POST /api/custom-roles          - Create custom roles")
        print("\n")

    except Exception as e:
        print(f"\n✗ Error during seeding: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    print("\nThis script will seed capabilities and role templates into the database.")
    print("Make sure you have run database migrations first (alembic upgrade head).\n")

    response = input("Continue? (yes/no): ").strip().lower()

    if response in ['yes', 'y']:
        seed_all()
    else:
        print("Seeding cancelled.")
        sys.exit(0)
