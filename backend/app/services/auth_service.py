"""
Authentication Service
Core business logic for user authentication and authorization
"""

from datetime import datetime, timedelta
from typing import Optional, Tuple
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
import uuid

from app.models.user import User
from app.models.role import Role
from app.models.user_organization import UserOrganization
from app.models.company import Organization
from app.models.security_question import SecurityQuestion
from app.models.user_security_answer import UserSecurityAnswer
from app.models.recovery_attempt import RecoveryAttempt
from app.models.audit_log import AuditLog
from app.core.security import hash_password, verify_password, create_access_token
from app.core.encryption import generate_salt, encrypt_answer, decrypt_and_compare
from app.services.token_service import TokenService
from app.services.email_service import EmailService
from app.config import settings
from app.utils.constants import *


class AuthService:
    """Service for authentication operations"""

    def __init__(self, db: Session):
        self.db = db

    def signup(self, signup_data: dict) -> dict:
        """
        User signup with support for both email and security questions methods.

        Args:
            signup_data: Dictionary containing signup information

        Returns:
            Dictionary with user information and status

        Raises:
            HTTPException: If signup fails
        """
        # Check if username already exists
        existing_user = self.db.query(User).filter(
            User.username == signup_data['username']
        ).first()

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=ERROR_USERNAME_EXISTS
            )

        # Check if email already exists (if provided)
        if signup_data.get('email'):
            existing_email = self.db.query(User).filter(
                User.email == signup_data['email']
            ).first()

            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=ERROR_EMAIL_EXISTS
                )

        # Hash password
        password_hash = hash_password(signup_data['password'])

        # Determine initial status
        if signup_data['auth_method'] == AUTH_METHOD_EMAIL:
            initial_status = USER_STATUS_PENDING_VERIFICATION
        else:
            initial_status = USER_STATUS_ACTIVE

        # Create user
        user = User(
            id=uuid.uuid4(),
            full_name=signup_data['full_name'],
            username=signup_data['username'],
            email=signup_data.get('email'),
            phone=signup_data['phone'],
            password_hash=password_hash,
            auth_method=signup_data['auth_method'],
            status=initial_status,
            email_verified=False if signup_data['auth_method'] == AUTH_METHOD_EMAIL else True
        )

        self.db.add(user)
        self.db.flush()  # Get user.id without committing

        # Handle security questions if provided
        if signup_data['auth_method'] == AUTH_METHOD_SECURITY_QUESTIONS:
            self._save_security_questions(
                user.id,
                signup_data['password'],
                signup_data['security_questions']
            )

        # Handle company association
        company = None
        role = None
        user_org = None

        if signup_data.get('company_type') == COMPANY_TYPE_EXISTING:
            # Join existing company
            company, role, user_org = self._join_existing_company(
                user.id,
                signup_data['company_id']
            )

        elif signup_data.get('company_type') == COMPANY_TYPE_NEW:
            # Create new company
            company, role, user_org = self._create_new_company(
                user.id,
                signup_data['company_details']
            )

        else:
            # Skip company selection - Profile not completed yet
            # User will complete profile on first login
            pass

        # Commit all changes
        self.db.commit()
        self.db.refresh(user)

        # Send verification email if email method
        verification_token = None
        verification_code = None
        verification_expires_at = None

        if signup_data['auth_method'] == AUTH_METHOD_EMAIL:
            verification_token, verification_code = TokenService.create_verification_token(
                self.db,
                str(user.id),
                TOKEN_TYPE_EMAIL_VERIFICATION,
                settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS
            )

            # Send verification email
            EmailService.send_verification_email(
                user.email,
                user.username,
                verification_token
            )

            verification_expires_at = datetime.utcnow() + timedelta(
                hours=settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS
            )

        # Log audit event
        self._log_audit(
            user_id=user.id,
            organization_id=company.id if company else None,
            action=AUDIT_ACTION_USER_SIGNUP,
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id,
            details={
                "auth_method": signup_data['auth_method'],
                "company_type": signup_data.get('company_type'),
                "role": role.role_name if role else None
            }
        )

        # Prepare response
        response = {
            "success": True,
            "user_id": str(user.id),
            "username": user.username,
            "email": user.email,
            "status": user.status,
            "auth_method": user.auth_method,
            "company_id": str(company.id) if company else None,
            "company_name": company.company_name if company else None,
            "role": role.role_name if role else None,
            "capabilities": ['*'] if role and role.is_owner() else [],
            "message": SUCCESS_SIGNUP_EMAIL if signup_data['auth_method'] == AUTH_METHOD_EMAIL else SUCCESS_SIGNUP_SECURITY_QUESTIONS,
            "verification_code": verification_code,  # 6-digit code for easy verification
            "verification_expires_at": verification_expires_at,
            "security_questions_count": len(signup_data.get('security_questions', [])) if signup_data['auth_method'] == AUTH_METHOD_SECURITY_QUESTIONS else None
        }

        return response

    def login(self, username: str, password: str) -> dict:
        """
        User login with username and password.

        Args:
            username: User's username
            password: User's password

        Returns:
            Dictionary with access token and user information

        Raises:
            HTTPException: If login fails
        """
        # Find user
        user = self.db.query(User).filter(User.username == username).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=ERROR_INVALID_CREDENTIALS
            )

        # Check if account is locked
        if user.is_locked():
            minutes_remaining = int((user.locked_until - datetime.utcnow()).total_seconds() / 60)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=ERROR_ACCOUNT_LOCKED.format(minutes=minutes_remaining)
            )

        # Verify password
        if not verify_password(password, user.password_hash):
            # Record failed attempt
            self._record_failed_login(user.id)

            # Increment failed attempts
            user.failed_login_attempts += 1

            # Lock account if max attempts reached
            if user.failed_login_attempts >= settings.MAX_FAILED_LOGIN_ATTEMPTS:
                user.locked_until = datetime.utcnow() + timedelta(
                    minutes=settings.ACCOUNT_LOCKOUT_MINUTES
                )
                user.status = USER_STATUS_LOCKED

                self.db.commit()

                self._log_audit(
                    user_id=user.id,
                    action=AUDIT_ACTION_ACCOUNT_LOCKED,
                    entity_type=ENTITY_TYPE_USER,
                    entity_id=user.id,
                    details={"reason": "max_failed_login_attempts"}
                )

                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=ERROR_ACCOUNT_LOCKED.format(minutes=settings.ACCOUNT_LOCKOUT_MINUTES)
                )

            self.db.commit()

            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=ERROR_INVALID_CREDENTIALS
            )

        # Check if user can login
        if not user.can_login():
            if user.status == USER_STATUS_PENDING_VERIFICATION:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=ERROR_EMAIL_NOT_VERIFIED
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Account status: {user.status}"
                )

        # Reset failed attempts on successful login
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.utcnow()

        # Get user's organization and role
        user_org = self.db.query(UserOrganization).filter(
            UserOrganization.user_id == user.id
        ).first()

        company = None
        role = None

        if user_org:
            role = self.db.query(Role).filter(Role.id == user_org.role_id).first()
            if user_org.organization_id:
                company = self.db.query(Organization).filter(
                    Organization.id == user_org.organization_id
                ).first()

        self.db.commit()

        # Record successful login
        self._record_successful_login(user.id)

        # Log audit event
        self._log_audit(
            user_id=user.id,
            organization_id=company.id if company else None,
            action=AUDIT_ACTION_USER_LOGIN,
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id
        )

        # Create access token
        token_data = {
            "sub": str(user.id),
            "username": user.username,
            "role": role.role_key if role else None,
            "company_id": str(company.id) if company else None
        }

        access_token = create_access_token(token_data)

        # Return response
        return {
            "success": True,
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": str(user.id),
            "username": user.username,
            "email": user.email,
            "profile_completed": user.profile_completed,
            "role": role.role_name if role else None,
            "company_id": str(company.id) if company else None,
            "company_name": company.company_name if company else None
        }

    def verify_email(self, token: str) -> dict:
        """Verify user's email using verification token"""
        is_valid, user_id, error = TokenService.verify_token(
            self.db, token, TOKEN_TYPE_EMAIL_VERIFICATION
        )

        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error
            )

        # Get user
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Update user status
        user.email_verified = True
        user.status = USER_STATUS_ACTIVE

        # Mark token as used
        TokenService.mark_token_used(self.db, token)

        self.db.commit()

        # Log audit event
        self._log_audit(
            user_id=user.id,
            action=AUDIT_ACTION_EMAIL_VERIFIED,
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id
        )

        return {
            "success": True,
            "message": SUCCESS_EMAIL_VERIFIED,
            "user_id": str(user.id),
            "redirect_url": "/dashboard"
        }

    def verify_email_code(self, verification_code: str) -> dict:
        """Verify user's email using 6-digit verification code"""
        is_valid, user_id, error = TokenService.verify_code(
            self.db, verification_code, TOKEN_TYPE_EMAIL_VERIFICATION
        )

        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error
            )

        # Get user
        user = self.db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Update user status
        user.email_verified = True
        user.status = USER_STATUS_ACTIVE

        # Mark code as used
        TokenService.mark_code_used(self.db, verification_code)

        self.db.commit()

        # Log audit event
        self._log_audit(
            user_id=user.id,
            action=AUDIT_ACTION_EMAIL_VERIFIED,
            entity_type=ENTITY_TYPE_USER,
            entity_id=user.id,
            details={"verification_method": "code"}
        )

        return {
            "success": True,
            "message": SUCCESS_EMAIL_VERIFIED,
            "user_id": str(user.id),
            "redirect_url": "/dashboard"
        }

    # Helper methods

    def _save_security_questions(self, user_id: uuid.UUID, password: str, questions: list):
        """Save encrypted security question answers"""
        # Generate unique salt for this user
        user_salt = generate_salt()

        for q in questions:
            # Get question from database
            question = self.db.query(SecurityQuestion).filter(
                SecurityQuestion.question_key == q['question_id']
            ).first()

            if not question:
                continue

            # Encrypt answer
            encrypted_answer = encrypt_answer(q['answer'], password, user_salt)

            # Save answer
            user_answer = UserSecurityAnswer(
                user_id=user_id,
                question_id=question.id,
                encrypted_answer=encrypted_answer,
                encryption_salt=user_salt
            )

            self.db.add(user_answer)

    def _join_existing_company(self, user_id: uuid.UUID, company_id: str) -> Tuple:
        """Join existing company as Pending User"""
        company = self.db.query(Organization).filter(
            Organization.id == company_id
        ).first()

        if not company:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=ERROR_COMPANY_NOT_FOUND
            )

        # Get Pending User role
        role = self._get_role_by_key('pending_user')

        # Create user-organization relationship
        user_org = UserOrganization(
            user_id=user_id,
            organization_id=company.id,
            role_id=role.id,
            status='pending'
        )

        self.db.add(user_org)

        return company, role, user_org

    def _create_new_company(self, user_id: uuid.UUID, company_details: dict) -> Tuple:
        """Create new company and assign user as Owner"""
        # Create organization
        company = Organization(
            id=uuid.uuid4(),
            company_name=company_details['company_name'],
            business_type=company_details['business_type'],
            gstin=company_details.get('gstin'),
            pan_number=company_details.get('pan_number'),
            registration_number=company_details.get('registration_number'),
            registration_date=company_details.get('registration_date'),
            business_email=company_details['business_email'],
            business_phone=company_details['business_phone'],
            address=company_details['address'],
            city=company_details['city'],
            state=company_details['state'],
            pincode=company_details['pincode'],
            country=company_details.get('country', 'India'),
            status='active'
        )

        self.db.add(company)
        self.db.flush()

        # Get Owner role
        role = self._get_role_by_key('owner')

        # Create user-organization relationship with Owner role
        user_org = UserOrganization(
            user_id=user_id,
            organization_id=company.id,
            role_id=role.id,
            status='active',
            approved_at=datetime.utcnow(),
            approved_by=user_id
        )

        self.db.add(user_org)

        # Log company creation
        self._log_audit(
            user_id=user_id,
            organization_id=company.id,
            action=AUDIT_ACTION_COMPANY_CREATED,
            entity_type=ENTITY_TYPE_COMPANY,
            entity_id=company.id
        )

        return company, role, user_org

    def _get_role_by_key(self, role_key: str) -> Role:
        """Get role by role_key"""
        role = self.db.query(Role).filter(Role.role_key == role_key).first()

        if not role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Role '{role_key}' not found in database"
            )

        return role

    def _record_failed_login(self, user_id: uuid.UUID):
        """Record failed login attempt"""
        attempt = RecoveryAttempt(
            user_id=user_id,
            attempt_type=RECOVERY_TYPE_LOGIN,
            success=False
        )
        self.db.add(attempt)

    def _record_successful_login(self, user_id: uuid.UUID):
        """Record successful login attempt"""
        attempt = RecoveryAttempt(
            user_id=user_id,
            attempt_type=RECOVERY_TYPE_LOGIN,
            success=True
        )
        self.db.add(attempt)

    def _log_audit(
        self,
        user_id: Optional[uuid.UUID],
        action: str,
        entity_type: Optional[str] = None,
        entity_id: Optional[uuid.UUID] = None,
        organization_id: Optional[uuid.UUID] = None,
        details: Optional[dict] = None
    ):
        """Log audit event"""
        audit_log = AuditLog(
            user_id=user_id,
            organization_id=organization_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details
        )

        self.db.add(audit_log)
