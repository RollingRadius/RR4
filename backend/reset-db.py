#!/usr/bin/env python3
"""
Database Reset Script
⚠️ WARNING: This will DELETE ALL DATA in the database!
Use with caution - intended for development only.
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import create_engine, text
from app.database import Base
from app.config import settings


def confirm_reset():
    """Ask user to confirm database reset"""
    print("=" * 60)
    print("⚠️  DATABASE RESET - WARNING")
    print("=" * 60)
    print()
    print("This will DELETE ALL DATA from the database!")
    print(f"Database: {settings.DATABASE_URL}")
    print()

    # Ask for confirmation
    response = input("Type 'DELETE ALL DATA' to confirm: ")

    return response == "DELETE ALL DATA"


def reset_database():
    """Drop all tables and recreate them"""
    try:
        engine = create_engine(settings.DATABASE_URL)

        print("\n🗑️  Dropping all tables...")
        Base.metadata.drop_all(bind=engine)
        print("✅ All tables dropped")

        print("\n📊 Recreating all tables...")
        Base.metadata.create_all(bind=engine)
        print("✅ All tables recreated")

        # Also reset Alembic version table
        print("\n🔄 Resetting Alembic migration history...")
        with engine.connect() as conn:
            # Drop alembic_version table if it exists
            conn.execute(text("DROP TABLE IF EXISTS alembic_version CASCADE"))
            conn.commit()
        print("✅ Alembic history reset")

        print("\n✅ Database reset complete!")
        print("📝 Note: Run 'alembic upgrade head' if using migrations")

        return True

    except Exception as e:
        print(f"\n❌ Error resetting database: {e}")
        return False


def truncate_all_tables():
    """Alternative: Truncate all tables (keeps structure, deletes data only)"""
    try:
        engine = create_engine(settings.DATABASE_URL)

        print("\n🗑️  Truncating all tables...")

        with engine.connect() as conn:
            # Get all table names
            result = conn.execute(text("""
                SELECT tablename
                FROM pg_tables
                WHERE schemaname = 'public'
                AND tablename != 'alembic_version'
            """))
            tables = [row[0] for row in result]

            # Truncate all tables
            for table in tables:
                print(f"   Truncating {table}...")
                conn.execute(text(f'TRUNCATE TABLE "{table}" CASCADE'))

            conn.commit()

        print("✅ All tables truncated (data deleted, structure preserved)")
        return True

    except Exception as e:
        print(f"\n❌ Error truncating tables: {e}")
        return False


if __name__ == "__main__":
    print()

    # Check if user wants to keep structure
    print("Select reset option:")
    print("1. Drop and recreate all tables (complete reset)")
    print("2. Truncate tables (delete data, keep structure)")
    print("3. Cancel")
    print()

    choice = input("Enter choice (1/2/3): ").strip()

    if choice == "3":
        print("❌ Cancelled")
        sys.exit(0)

    # Confirm action
    if not confirm_reset():
        print("\n❌ Reset cancelled - confirmation text did not match")
        sys.exit(1)

    print()

    if choice == "1":
        # Complete reset (drop and recreate)
        if reset_database():
            print("\n✨ Database reset successful!")
            sys.exit(0)
        else:
            print("\n❌ Database reset failed")
            sys.exit(1)

    elif choice == "2":
        # Truncate only (keep structure)
        if truncate_all_tables():
            print("\n✨ Tables truncated successfully!")
            sys.exit(0)
        else:
            print("\n❌ Truncate failed")
            sys.exit(1)

    else:
        print("❌ Invalid choice")
        sys.exit(1)
