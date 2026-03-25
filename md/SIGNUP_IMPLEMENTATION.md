# Signup Module - Developer Implementation Guide

## Overview

This document provides technical implementation details for the Signup/Registration module of the Fleet Management System. Use this guide to implement, customize, and maintain the signup functionality.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Backend Setup](#backend-setup)
3. [Database Models](#database-models)
4. [FastAPI Endpoints](#fastapi-endpoints)
5. [Email Service](#email-service)
6. [Frontend Setup](#frontend-setup)
7. [Configuration](#configuration)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      SIGNUP SYSTEM                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │   Flutter    │─────▶│   FastAPI    │─────▶│PostgreSQL │ │
│  │   Frontend   │◀─────│   Backend    │◀─────│ Database  │ │
│  └──────────────┘      └──────────────┘      └───────────┘ │
│         │                      │                            │
│         │                      │                            │
│         │                      ▼                            │
│         │              ┌──────────────┐                     │
│         │              │ Email Service│                     │
│         │              │  (SMTP/SES)  │                     │
│         │              └──────────────┘                     │
│         │                      │                            │
│         │                      ▼                            │
│         │              ┌──────────────┐                     │
│         └─────────────▶│   User Gets  │                     │
│                        │ Invitation   │                     │
│                        └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure

```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── auth.py                    # Signup/registration endpoints
│   │       └── users.py                   # User management endpoints
│   ├── models/
│   │   ├── user.py                        # User model
│   │   ├── invitation.py                  # Invitation token model
│   │   ├── email_verification.py          # Email verification model
│   │   └── application.py                 # Driver application model
│   ├── schemas/
│   │   ├── auth.py                        # Auth request/response schemas
│   │   ├── user.py                        # User schemas
│   │   └── invitation.py                  # Invitation schemas
│   ├── services/
│   │   ├── auth_service.py                # Authentication business logic
│   │   ├── user_service.py                # User creation and management
│   │   ├── email_service.py               # Email sending service
│   │   ├── token_service.py               # Token generation and validation
│   │   └── role_service.py                # Role and capability assignment
│   ├── core/
│   │   ├── security.py                    # Password hashing, token generation
│   │   ├── config.py                      # Configuration settings
│   │   └── dependencies.py                # FastAPI dependencies
│   └── utils/
│       ├── validators.py                  # Input validation utilities
│       └── email_templates.py             # Email HTML templates
│
flutter_app/
├── lib/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── password_setup_screen.dart
│   │   │   ├── organization_signup_screen.dart
│   │   │   └── driver_application_screen.dart
│   │   └── admin/
│   │       └── create_user_screen.dart
│   ├── services/
│   │   ├── auth_service.dart              # API calls for authentication
│   │   └── user_service.dart              # API calls for user management
│   ├── models/
│   │   ├── user.dart                      # User model
│   │   └── role.dart                      # Role model
│   └── widgets/
│       ├── password_strength_indicator.dart
│       └── role_selector.dart
```

---

## Backend Setup

### Step 1: Install Dependencies

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn sqlalchemy psycopg2-binary alembic pydantic pydantic-settings python-jose passlib bcrypt python-multipart slowapi
```

### Step 2: Create `.env` File

```bash
# backend/.env
DATABASE_URL=postgresql://user:password@localhost:5432/fleet_db
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@fleetmanagement.com
SMTP_FROM_NAME=Fleet Management System

# Frontend URL (for email links)
FRONTEND_URL=http://localhost:3000

# Token Expiry (in hours)
INVITATION_TOKEN_EXPIRY=48
VERIFICATION_TOKEN_EXPIRY=48

# Rate Limiting
RATE_LIMIT_REGISTRATIONS_PER_HOUR=5
RATE_LIMIT_VERIFICATIONS_PER_HOUR=10

# Optional: Enable driver self-registration
ENABLE_DRIVER_SELF_REGISTRATION=true

# Optional: Require admin approval for organizations
REQUIRE_ORGANIZATION_APPROVAL=false
```

---

## Database Models

### User Model

```python
# backend/app/models/user.py

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)  # Nullable for invited users
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    employee_id = Column(String, nullable=True)
    department = Column(String, nullable=True)

    # Status
    status = Column(String, default="pending_activation")  # pending_activation, active, suspended, deleted
    email_verified = Column(Boolean, default=False)

    # Relationships
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=True)
    organization = relationship("Organization", back_populates="users")

    # Role (user has one role)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id"), nullable=False)
    role = relationship("Role")

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    activated_at = Column(DateTime, nullable=True)
    last_login_at = Column(DateTime, nullable=True)

    # Additional info (JSON field)
    additional_info = Column(JSON, nullable=True)

    def to_dict(self):
        return {
            "id": str(self.id),
            "email": self.email,
            "full_name": self.full_name,
            "phone": self.phone,
            "status": self.status,
            "email_verified": self.email_verified,
            "role": self.role.name if self.role else None,
            "organization_id": str(self.organization_id) if self.organization_id else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
```

### Invitation Model

```python
# backend/app/models/invitation.py

from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime, timedelta
from app.database import Base

class Invitation(Base):
    __tablename__ = "invitations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    token = Column(String, unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    def is_expired(self):
        return datetime.utcnow() > self.expires_at
```

### Email Verification Model

```python
# backend/app/models/email_verification.py

from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.database import Base

class EmailVerification(Base):
    __tablename__ = "email_verifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    token = Column(String, unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)
    verified = Column(Boolean, default=False)
    verified_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
```

### Driver Application Model

```python
# backend/app/models/application.py

from sqlalchemy import Column, String, DateTime, Date, JSON
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.database import Base

class DriverApplication(Base):
    __tablename__ = "driver_applications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_number = Column(String, unique=True, nullable=False)  # DR-2024-0001

    # Personal Info
    full_name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=False)
    address = Column(String, nullable=False)

    # Driver Info
    license_number = Column(String, nullable=False)
    license_state = Column(String, nullable=False)
    license_expiry = Column(Date, nullable=False)
    license_document_url = Column(String, nullable=True)
    years_experience = Column(Integer, nullable=False)
    vehicle_types = Column(JSON, nullable=True)  # ["truck", "van"]

    # Status
    status = Column(String, default="under_review")  # under_review, approved, rejected
    reviewed_by = Column(UUID(as_uuid=True), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    rejection_reason = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

---

## FastAPI Endpoints

### Authentication Endpoints

```python
# backend/app/api/v1/auth.py

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from slowapi import Limiter
from slowapi.util import get_remote_address
from datetime import datetime, timedelta
import secrets

from app.database import get_db
from app.schemas.auth import *
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.email_service import EmailService
from app.services.token_service import TokenService
from app.core.security import hash_password, verify_password, create_access_token
from app.core.dependencies import get_current_user, require_capability

router = APIRouter(prefix="/auth", tags=["Authentication"])
limiter = Limiter(key_func=get_remote_address)


@router.post("/users/create", response_model=UserCreateResponse)
async def create_user(
    user_data: UserCreateRequest,
    db: Session = Depends(get_db),
    current_user = Depends(require_capability("user.create"))
):
    """
    Admin creates a new user account.

    Required capability: user.create
    """
    try:
        user_service = UserService(db)
        email_service = EmailService()
        token_service = TokenService(db)

        # Check if email already exists
        existing_user = user_service.get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        # Create user with pending status
        new_user = user_service.create_user(
            email=user_data.email,
            full_name=user_data.full_name,
            phone=user_data.phone,
            employee_id=user_data.employee_id,
            department=user_data.department,
            role_id=user_data.role_id,
            organization_id=user_data.organization_id or current_user.organization_id,
            status="pending_activation",
            created_by=current_user.id,
            additional_info=user_data.additional_info
        )

        # Generate invitation token
        if user_data.send_invitation:
            invitation = token_service.create_invitation_token(
                user_id=new_user.id,
                created_by=current_user.id,
                expires_hours=48
            )

            # Send invitation email
            await email_service.send_invitation_email(
                to_email=new_user.email,
                user_name=new_user.full_name,
                role_name=new_user.role.name,
                invitation_token=invitation.token
            )

        return UserCreateResponse(
            user_id=str(new_user.id),
            email=new_user.email,
            status=new_user.status,
            invitation_sent=user_data.send_invitation,
            invitation_expires_at=invitation.expires_at if user_data.send_invitation else None,
            role={
                "role_id": str(new_user.role.id),
                "role_name": new_user.role.name,
                "capabilities": new_user.role.get_capabilities()
            }
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/register/organization")
@limiter.limit("5/hour")
async def register_organization(
    request: Request,
    registration_data: OrganizationRegistrationRequest,
    db: Session = Depends(get_db)
):
    """
    Organization self-registration.

    Rate limited: 5 registrations per hour per IP.
    """
    try:
        user_service = UserService(db)
        email_service = EmailService()
        token_service = TokenService(db)

        # Check if email already exists
        if user_service.get_user_by_email(registration_data.owner.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        # Create organization
        organization = user_service.create_organization(
            name=registration_data.organization.name,
            business_type=registration_data.organization.business_type,
            fleet_size=registration_data.organization.fleet_size,
            country=registration_data.organization.country,
            registration_number=registration_data.organization.registration_number,
            business_email=registration_data.organization.business_email,
            phone=registration_data.organization.phone
        )

        # Get Super Admin role
        super_admin_role = user_service.get_role_by_name("Super Admin")

        # Create owner user
        owner = user_service.create_user(
            email=registration_data.owner.email,
            full_name=registration_data.owner.full_name,
            phone=registration_data.owner.phone,
            password_hash=hash_password(registration_data.owner.password),
            role_id=super_admin_role.id,
            organization_id=organization.id,
            status="pending_verification"
        )

        # Create verification token
        verification = token_service.create_verification_token(
            user_id=owner.id,
            expires_hours=48
        )

        # Send verification email
        await email_service.send_verification_email(
            to_email=owner.email,
            user_name=owner.full_name,
            verification_token=verification.token
        )

        return {
            "organization_id": str(organization.id),
            "user_id": str(owner.id),
            "status": "pending_verification",
            "verification_email_sent": True,
            "message": "Please check your email to verify your account"
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/verify-email")
@limiter.limit("10/hour")
async def verify_email(
    request: Request,
    verification_data: EmailVerificationRequest,
    db: Session = Depends(get_db)
):
    """
    Verify user email address.

    Rate limited: 10 verifications per hour per IP.
    """
    try:
        token_service = TokenService(db)
        user_service = UserService(db)

        # Validate token
        verification = token_service.get_verification_token(verification_data.token)

        if not verification:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification token"
            )

        if verification.is_expired():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification token expired"
            )

        if verification.verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already verified"
            )

        # Update user
        user = user_service.get_user_by_id(verification.user_id)
        user.email_verified = True
        user.status = "active"

        # Mark verification as completed
        verification.verified = True
        verification.verified_at = datetime.utcnow()

        db.commit()

        return {
            "success": True,
            "message": "Email verified successfully",
            "user_id": str(user.id),
            "redirect_url": "/dashboard"
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/activate", response_model=ActivationResponse)
async def activate_account(
    activation_data: ActivationRequest,
    db: Session = Depends(get_db)
):
    """
    Activate account for invited users (set password).
    """
    try:
        token_service = TokenService(db)
        user_service = UserService(db)

        # Validate invitation token
        invitation = token_service.get_invitation_token(activation_data.token)

        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid invitation token"
            )

        if invitation.is_expired():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invitation token expired"
            )

        if not activation_data.terms_accepted:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Must accept terms of service"
            )

        # Validate password strength
        if not user_service.validate_password_strength(activation_data.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password does not meet requirements"
            )

        # Update user
        user = user_service.get_user_by_id(invitation.user_id)
        user.password_hash = hash_password(activation_data.password)
        user.status = "active"
        user.email_verified = True
        user.activated_at = datetime.utcnow()

        # Delete invitation token
        db.delete(invitation)
        db.commit()

        # Generate access tokens
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_access_token(
            data={"sub": str(user.id)},
            expires_delta=timedelta(days=7)
        )

        return ActivationResponse(
            success=True,
            user_id=str(user.id),
            message="Account activated successfully",
            access_token=access_token,
            refresh_token=refresh_token,
            user=user.to_dict()
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/register/driver")
@limiter.limit("10/hour")
async def register_driver(
    request: Request,
    application_data: DriverApplicationRequest,
    db: Session = Depends(get_db)
):
    """
    Driver self-registration (submit application).

    Rate limited: 10 applications per hour per IP.
    """
    try:
        from app.models.application import DriverApplication
        from app.core.config import settings

        # Check if feature is enabled
        if not settings.ENABLE_DRIVER_SELF_REGISTRATION:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Driver self-registration is not enabled"
            )

        # Generate application number
        application_number = f"DR-{datetime.utcnow().year}-{secrets.token_hex(4).upper()}"

        # Create application
        application = DriverApplication(
            application_number=application_number,
            full_name=application_data.personal_info.full_name,
            email=application_data.personal_info.email,
            phone=application_data.personal_info.phone,
            date_of_birth=application_data.personal_info.date_of_birth,
            address=application_data.personal_info.address,
            license_number=application_data.driver_info.license_number,
            license_state=application_data.driver_info.license_state,
            license_expiry=application_data.driver_info.license_expiry,
            license_document_url=application_data.driver_info.license_document_url,
            years_experience=application_data.driver_info.years_experience,
            vehicle_types=application_data.driver_info.vehicle_types,
            status="under_review"
        )

        db.add(application)
        db.commit()
        db.refresh(application)

        # Send confirmation email to applicant
        email_service = EmailService()
        await email_service.send_application_received_email(
            to_email=application.email,
            applicant_name=application.full_name,
            application_number=application.application_number
        )

        # Notify managers about new application
        await email_service.notify_managers_new_application(
            application_id=str(application.id),
            application_number=application.application_number,
            applicant_name=application.full_name
        )

        return {
            "application_id": application.application_number,
            "status": "under_review",
            "message": "Your application has been submitted successfully",
            "estimated_review_time": "2-3 business days"
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/users/{user_id}/resend-invitation")
async def resend_invitation(
    user_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(require_capability("user.create"))
):
    """
    Resend invitation email to user.

    Required capability: user.create
    """
    try:
        user_service = UserService(db)
        token_service = TokenService(db)
        email_service = EmailService()

        # Get user
        user = user_service.get_user_by_id(user_id)

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if user.status == "active":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User account is already active"
            )

        # Delete old invitation tokens for this user
        token_service.delete_user_invitations(user_id)

        # Create new invitation token
        invitation = token_service.create_invitation_token(
            user_id=user.id,
            created_by=current_user.id,
            expires_hours=48
        )

        # Send invitation email
        await email_service.send_invitation_email(
            to_email=user.email,
            user_name=user.full_name,
            role_name=user.role.name,
            invitation_token=invitation.token
        )

        return {
            "success": True,
            "message": "Invitation email sent successfully",
            "expires_at": invitation.expires_at.isoformat()
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
```

---

## Email Service

### Email Service Implementation

```python
# backend/app/services/email_service.py

from typing import Optional
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings
from app.utils.email_templates import (
    get_invitation_email_template,
    get_verification_email_template,
    get_application_received_template,
    get_application_approved_template
)

class EmailService:
    def __init__(self):
        self.smtp_host = settings.SMTP_HOST
        self.smtp_port = settings.SMTP_PORT
        self.smtp_user = settings.SMTP_USER
        self.smtp_password = settings.SMTP_PASSWORD
        self.from_email = settings.SMTP_FROM_EMAIL
        self.from_name = settings.SMTP_FROM_NAME
        self.frontend_url = settings.FRONTEND_URL

    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None
    ):
        """Send email via SMTP."""
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = f"{self.from_name} <{self.from_email}>"
            message["To"] = to_email

            # Add plain text version
            if text_content:
                part1 = MIMEText(text_content, "plain")
                message.attach(part1)

            # Add HTML version
            part2 = MIMEText(html_content, "html")
            message.attach(part2)

            # Send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(message)

            return True

        except Exception as e:
            print(f"Error sending email: {str(e)}")
            raise

    async def send_invitation_email(
        self,
        to_email: str,
        user_name: str,
        role_name: str,
        invitation_token: str
    ):
        """Send invitation email to new user."""
        activation_link = f"{self.frontend_url}/activate?token={invitation_token}"

        html_content = get_invitation_email_template(
            user_name=user_name,
            role_name=role_name,
            activation_link=activation_link
        )

        await self.send_email(
            to_email=to_email,
            subject=f"Welcome to {self.from_name}",
            html_content=html_content
        )

    async def send_verification_email(
        self,
        to_email: str,
        user_name: str,
        verification_token: str
    ):
        """Send email verification link."""
        verification_link = f"{self.frontend_url}/verify?token={verification_token}"

        html_content = get_verification_email_template(
            user_name=user_name,
            verification_link=verification_link
        )

        await self.send_email(
            to_email=to_email,
            subject="Verify Your Email Address",
            html_content=html_content
        )

    async def send_application_received_email(
        self,
        to_email: str,
        applicant_name: str,
        application_number: str
    ):
        """Send confirmation email to driver applicant."""
        html_content = get_application_received_template(
            applicant_name=applicant_name,
            application_number=application_number
        )

        await self.send_email(
            to_email=to_email,
            subject="Driver Application Received",
            html_content=html_content
        )

    async def send_application_approved_email(
        self,
        to_email: str,
        applicant_name: str,
        activation_token: str
    ):
        """Send approval email with activation link."""
        activation_link = f"{self.frontend_url}/activate?token={activation_token}"

        html_content = get_application_approved_template(
            applicant_name=applicant_name,
            activation_link=activation_link
        )

        await self.send_email(
            to_email=to_email,
            subject="Driver Application Approved",
            html_content=html_content
        )

    async def notify_managers_new_application(
        self,
        application_id: str,
        application_number: str,
        applicant_name: str
    ):
        """Notify fleet managers about new driver application."""
        # Get all fleet managers
        # Send notification email to them
        pass
```

### Email Templates

```python
# backend/app/utils/email_templates.py

def get_invitation_email_template(user_name: str, role_name: str, activation_link: str) -> str:
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; background-color: #f9f9f9; }}
            .button {{ display: inline-block; padding: 12px 24px; background-color: #4CAF50;
                      color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }}
            .footer {{ padding: 20px; text-align: center; font-size: 12px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to Fleet Management System</h1>
            </div>
            <div class="content">
                <p>Hi {user_name},</p>

                <p>You have been invited to join the Fleet Management System as a <strong>{role_name}</strong>.</p>

                <p>To activate your account and set up your password, please click the button below:</p>

                <p style="text-align: center;">
                    <a href="{activation_link}" class="button">Activate Your Account</a>
                </p>

                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #666;">{activation_link}</p>

                <p><strong>This link will expire in 48 hours.</strong></p>

                <p>Your assigned role: <strong>{role_name}</strong></p>

                <p>If you didn't expect this invitation, please ignore this email.</p>

                <p>Best regards,<br>Fleet Management Team</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 Fleet Management System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

def get_verification_email_template(user_name: str, verification_link: str) -> str:
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #2196F3; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; background-color: #f9f9f9; }}
            .button {{ display: inline-block; padding: 12px 24px; background-color: #2196F3;
                      color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }}
            .footer {{ padding: 20px; text-align: center; font-size: 12px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Verify Your Email</h1>
            </div>
            <div class="content">
                <p>Hi {user_name},</p>

                <p>Thank you for registering with Fleet Management System!</p>

                <p>Please verify your email address by clicking the button below:</p>

                <p style="text-align: center;">
                    <a href="{verification_link}" class="button">Verify Email</a>
                </p>

                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #666;">{verification_link}</p>

                <p><strong>This link will expire in 48 hours.</strong></p>

                <p>Once verified, you can:</p>
                <ul>
                    <li>Access your dashboard</li>
                    <li>Add vehicles to your fleet</li>
                    <li>Invite team members</li>
                    <li>Start tracking in real-time</li>
                </ul>

                <p>If you didn't create this account, please ignore this email.</p>

                <p>Best regards,<br>Fleet Management Team</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 Fleet Management System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

def get_application_received_template(applicant_name: str, application_number: str) -> str:
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #FF9800; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; background-color: #f9f9f9; }}
            .info-box {{ background-color: white; padding: 15px; border-left: 4px solid #FF9800; margin: 20px 0; }}
            .footer {{ padding: 20px; text-align: center; font-size: 12px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Application Received</h1>
            </div>
            <div class="content">
                <p>Hi {applicant_name},</p>

                <p>Thank you for submitting your driver application!</p>

                <div class="info-box">
                    <strong>Application ID:</strong> {application_number}<br>
                    <strong>Status:</strong> Under Review
                </div>

                <p><strong>Next Steps:</strong></p>
                <ol>
                    <li>Background check (2-3 business days)</li>
                    <li>Application review by our team</li>
                    <li>You'll receive an email notification once approved</li>
                </ol>

                <p>We'll contact you if we need any additional information.</p>

                <p>Thank you for your interest in joining our team!</p>

                <p>Best regards,<br>Fleet Management Team</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 Fleet Management System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

def get_application_approved_template(applicant_name: str, activation_link: str) -> str:
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
            .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; background-color: #f9f9f9; }}
            .button {{ display: inline-block; padding: 12px 24px; background-color: #4CAF50;
                      color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }}
            .footer {{ padding: 20px; text-align: center; font-size: 12px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Application Approved!</h1>
            </div>
            <div class="content">
                <p>Hi {applicant_name},</p>

                <p><strong>Congratulations!</strong> Your driver application has been approved.</p>

                <p>You're now ready to set up your account and start working with us.</p>

                <p style="text-align: center;">
                    <a href="{activation_link}" class="button">Set Up Your Account</a>
                </p>

                <p>Click the button above to:</p>
                <ul>
                    <li>Create your password</li>
                    <li>Complete your profile</li>
                    <li>Access your driver dashboard</li>
                    <li>View available trips</li>
                </ul>

                <p><strong>This link will expire in 48 hours.</strong></p>

                <p>We're excited to have you on our team!</p>

                <p>Best regards,<br>Fleet Management Team</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 Fleet Management System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
```

---

## Frontend Setup

### Flutter Service Layer

```dart
// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/user.dart';
import '../models/role.dart';

class AuthService {
  static final String baseUrl = Environment.apiBaseUrl;

  // Admin creates user
  static Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String roleId,
    String? employeeId,
    String? department,
    String? organizationId,
    bool sendInvitation = true,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/users/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getAccessToken()}',
      },
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'employee_id': employeeId,
        'department': department,
        'role_id': roleId,
        'organization_id': organizationId,
        'send_invitation': sendInvitation,
        'additional_info': additionalInfo,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Get invitation details
  static Future<Map<String, dynamic>> getInvitationDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/invitation/$token'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid or expired invitation');
    }
  }

  // Activate account (set password)
  static Future<Map<String, dynamic>> activateAccount({
    required String token,
    required String password,
    required bool termsAccepted,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'password': password,
        'terms_accepted': termsAccepted,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save tokens
      await _saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );

      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Verify email
  static Future<void> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Organization registration
  static Future<Map<String, dynamic>> registerOrganization({
    required Map<String, dynamic> organizationData,
    required Map<String, dynamic> ownerData,
    required String plan,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/organization'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'organization': organizationData,
        'owner': ownerData,
        'plan': plan,
        'terms_accepted': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Driver application
  static Future<Map<String, dynamic>> submitDriverApplication({
    required Map<String, dynamic> personalInfo,
    required Map<String, dynamic> driverInfo,
    required Map<String, bool> consent,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/driver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'personal_info': personalInfo,
        'driver_info': driverInfo,
        'consent': consent,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Resend invitation
  static Future<void> resendInvitation(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/users/$userId/resend-invitation'),
      headers: {
        'Authorization': 'Bearer ${await _getAccessToken()}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail']);
    }
  }

  // Helper methods
  static Future<String> _getAccessToken() async {
    // Retrieve from secure storage
    return '';
  }

  static Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Save to secure storage
  }
}
```

---

## Configuration

### Backend Configuration

```python
# backend/app/core/config.py

from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Fleet Management System"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Email
    SMTP_HOST: str
    SMTP_PORT: int
    SMTP_USER: str
    SMTP_PASSWORD: str
    SMTP_FROM_EMAIL: str
    SMTP_FROM_NAME: str

    # Frontend
    FRONTEND_URL: str

    # Token Expiry (hours)
    INVITATION_TOKEN_EXPIRY: int = 48
    VERIFICATION_TOKEN_EXPIRY: int = 48

    # Rate Limiting
    RATE_LIMIT_REGISTRATIONS_PER_HOUR: int = 5
    RATE_LIMIT_VERIFICATIONS_PER_HOUR: int = 10

    # Features
    ENABLE_DRIVER_SELF_REGISTRATION: bool = False
    REQUIRE_ORGANIZATION_APPROVAL: bool = False

    class Config:
        env_file = ".env"

settings = Settings()
```

---

## Testing

### Unit Tests

```python
# backend/tests/test_signup.py

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import get_db
from app.models.user import User
from sqlalchemy.orm import Session

client = TestClient(app)

def test_create_user_admin():
    """Test admin creates user account."""
    # Login as admin
    login_response = client.post("/auth/login", json={
        "email": "admin@test.com",
        "password": "admin123"
    })
    token = login_response.json()["access_token"]

    # Create user
    response = client.post(
        "/auth/users/create",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "full_name": "Test Driver",
            "email": "test.driver@test.com",
            "phone": "+1234567890",
            "role_id": "driver_role_id",
            "send_invitation": True
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test.driver@test.com"
    assert data["invitation_sent"] == True

def test_organization_registration():
    """Test organization self-registration."""
    response = client.post("/auth/register/organization", json={
        "organization": {
            "name": "Test Fleet Inc",
            "business_type": "transportation",
            "fleet_size": "10-50",
            "country": "USA",
            "business_email": "info@testfleet.com",
            "phone": "+1234567890"
        },
        "owner": {
            "full_name": "John Owner",
            "email": "john@testfleet.com",
            "phone": "+1234567890",
            "job_title": "CEO",
            "password": "SecurePass123!"
        },
        "plan": "professional",
        "terms_accepted": True
    })

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "pending_verification"
    assert data["verification_email_sent"] == True

def test_activate_account():
    """Test account activation with password setup."""
    # First, create user with invitation
    # ... (setup code)

    response = client.post("/auth/activate", json={
        "token": "valid_invitation_token",
        "password": "SecurePass123!",
        "terms_accepted": True
    })

    assert response.status_code == 200
    data = response.json()
    assert data["success"] == True
    assert "access_token" in data
    assert "refresh_token" in data

def test_invalid_invitation_token():
    """Test activation with invalid token."""
    response = client.post("/auth/activate", json={
        "token": "invalid_token",
        "password": "SecurePass123!",
        "terms_accepted": True
    })

    assert response.status_code == 400
    assert "Invalid invitation token" in response.json()["detail"]

def test_weak_password():
    """Test password validation."""
    response = client.post("/auth/activate", json={
        "token": "valid_token",
        "password": "weak",
        "terms_accepted": True
    })

    assert response.status_code == 400
    assert "Password does not meet requirements" in response.json()["detail"]

def test_duplicate_email():
    """Test duplicate email registration."""
    # Create first user
    # ... (setup code)

    # Try to create another user with same email
    response = client.post("/auth/users/create", json={
        "email": "duplicate@test.com",
        # ... other fields
    })

    assert response.status_code == 400
    assert "Email already registered" in response.json()["detail"]
```

### Integration Tests

```python
# backend/tests/test_signup_integration.py

import pytest
from app.services.email_service import EmailService
from app.services.token_service import TokenService
from unittest.mock import Mock, patch

@pytest.mark.asyncio
async def test_complete_signup_flow():
    """Test complete user signup flow from invitation to activation."""

    # 1. Admin creates user
    # 2. User receives invitation email
    # 3. User clicks link and sets password
    # 4. User can log in

    # ... (implementation)
    pass

@pytest.mark.asyncio
async def test_email_service():
    """Test email sending functionality."""
    email_service = EmailService()

    with patch('smtplib.SMTP') as mock_smtp:
        await email_service.send_invitation_email(
            to_email="test@test.com",
            user_name="Test User",
            role_name="Driver",
            invitation_token="test_token"
        )

        assert mock_smtp.called
```

---

## Deployment

### Docker Setup

```dockerfile
# backend/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY ./app ./app

# Run migrations and start server
CMD alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: fleet_db
      POSTGRES_USER: fleet_user
      POSTGRES_PASSWORD: fleet_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://fleet_user:fleet_password@postgres:5432/fleet_db
      SECRET_KEY: ${SECRET_KEY}
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      FRONTEND_URL: ${FRONTEND_URL}
    depends_on:
      - postgres
    ports:
      - "8000:8000"

  frontend:
    build: ./flutter_app
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres_data:
```

---

## Troubleshooting

### Common Issues

#### 1. Email Not Sending

**Problem:** Invitation/verification emails not being sent.

**Solutions:**
- Check SMTP credentials in `.env` file
- Verify SMTP host and port
- Check firewall rules
- For Gmail, enable "Less secure app access" or use App Password
- Check spam folder

```python
# Test email service
from app.services.email_service import EmailService

email_service = EmailService()
await email_service.send_email(
    to_email="test@example.com",
    subject="Test Email",
    html_content="<p>Test</p>"
)
```

#### 2. Token Expired

**Problem:** Invitation/verification token expired.

**Solutions:**
- Increase token expiry time in `.env`:
  ```
  INVITATION_TOKEN_EXPIRY=72  # 3 days instead of 2
  ```
- Resend invitation:
  ```
  POST /auth/users/{user_id}/resend-invitation
  ```

#### 3. Database Connection Error

**Problem:** Cannot connect to PostgreSQL.

**Solutions:**
- Verify DATABASE_URL in `.env`
- Check PostgreSQL is running: `pg_isready`
- Check connection string format:
  ```
  postgresql://user:password@host:port/database
  ```

#### 4. Password Validation Failing

**Problem:** Users unable to set password.

**Solutions:**
- Review password requirements in `app/core/security.py`
- Update frontend validation to match backend requirements
- Show clear password requirements to user

#### 5. Rate Limiting Blocking Registrations

**Problem:** Users getting rate limit errors.

**Solutions:**
- Adjust rate limits in `.env`:
  ```
  RATE_LIMIT_REGISTRATIONS_PER_HOUR=10
  ```
- Whitelist specific IPs if needed
- Use Redis for distributed rate limiting

---

## Summary

This implementation guide covers:

✅ **Complete backend setup** with FastAPI, SQLAlchemy, PostgreSQL
✅ **Database models** for users, invitations, verifications, applications
✅ **API endpoints** for all signup flows
✅ **Email service** with SMTP configuration and templates
✅ **Frontend service layer** for Flutter integration
✅ **Security measures** (password hashing, token generation, rate limiting)
✅ **Testing** (unit tests and integration tests)
✅ **Deployment** with Docker and docker-compose
✅ **Troubleshooting** guide for common issues

The signup module is now ready for implementation and deployment!
