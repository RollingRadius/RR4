#!/usr/bin/env python3
"""
Database Initialization Script
Creates all tables and optionally seeds initial data
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import create_engine, text
from app.database import Base
from app.config import settings

# Import all models to ensure they're registered with Base
from app.models.user import User
from app.models.company import Organization, Company
from app.models.role import Role
from app.models.custom_role import CustomRole
from app.models.capability import Capability
from app.models.role_capability import RoleCapability
from app.models.user_organization import UserOrganization
from app.models.driver import Driver
from app.models.vehicle import Vehicle
from app.models.zone import Zone
from app.models.vendor import Vendor
from app.models.expense import Expense, ExpenseAttachment
from app.models.invoice import Invoice, InvoiceLineItem
from app.models.payment import Payment
from app.models.budget import Budget
from app.models.tracking import GPSTracking
from app.models.maintenance import MaintenanceSchedule, WorkOrder, Inspection
from app.models.part import Part, PartUsage
from app.models.report import Report
from app.models.dashboard import Dashboard
from app.models.kpi import KPI
from app.models.audit_log import AuditLog
from app.models.security_question import SecurityQuestion
from app.models.user_security_answer import UserSecurityAnswer
from app.models.recovery_attempt import RecoveryAttempt
from app.models.verification_token import VerificationToken


def init_database():
    """Initialize database by creating all tables"""
    print("🔧 Initializing Fleet Management Database...")
    print(f"📍 Database URL: {settings.DATABASE_URL}")

    try:
        # Create engine
        engine = create_engine(settings.DATABASE_URL)

        # Create all tables
        print("📊 Creating all tables...")
        Base.metadata.create_all(bind=engine)

        print("✅ Database initialized successfully!")
        print(f"✅ Created {len(Base.metadata.tables)} tables:")

        # Print all created tables
        for table_name in sorted(Base.metadata.tables.keys()):
            print(f"   - {table_name}")

        return True

    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        return False


def check_database_connection():
    """Check if database connection is working"""
    print("🔍 Checking database connection...")

    try:
        engine = create_engine(settings.DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"✅ Connected to PostgreSQL: {version}")
            return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("Fleet Management System - Database Initialization")
    print("=" * 60)
    print()

    # Check connection first
    if not check_database_connection():
        print("\n❌ Cannot proceed without database connection")
        sys.exit(1)

    print()

    # Initialize database
    if init_database():
        print("\n✨ Database setup complete!")
        print("🚀 You can now start the application")
        sys.exit(0)
    else:
        print("\n❌ Database initialization failed")
        sys.exit(1)
