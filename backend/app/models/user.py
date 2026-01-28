"""
User Model
Represents user accounts with support for email and security questions authentication
"""

from sqlalchemy import Column, String, Boolean, Integer, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class User(Base):
    """
    User model for authentication and account management.

    Supports two authentication methods:
    1. Email-based: Requires email verification before login
    2. Security questions: No email needed, immediate access
    """
    __tablename__ = "users"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Basic Information
    full_name = Column(String(255), nullable=False)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    phone = Column(String(20), nullable=False)

    # Authentication
    password_hash = Column(String(255), nullable=False)
    auth_method = Column(String(20), nullable=False)  # 'email' or 'security_questions'

    # Account Status
    status = Column(String(20), nullable=False, default='pending_verification')
    email_verified = Column(Boolean, nullable=False, default=False)
    profile_completed = Column(Boolean, nullable=False, default=False)

    # Security
    failed_login_attempts = Column(Integer, nullable=False, default=0)
    locked_until = Column(DateTime, nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())
    last_login = Column(DateTime, nullable=True)

    # Relationships
    organizations = relationship(
        "UserOrganization",
        foreign_keys="UserOrganization.user_id",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    security_answers = relationship(
        "UserSecurityAnswer",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    verification_tokens = relationship(
        "VerificationToken",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    recovery_attempts = relationship(
        "RecoveryAttempt",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "auth_method IN ('email', 'security_questions')",
            name='check_auth_method'
        ),
        CheckConstraint(
            "(auth_method = 'email' AND email IS NOT NULL) OR (auth_method = 'security_questions')",
            name='check_email_if_email_auth'
        ),
    )

    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}', auth_method='{self.auth_method}')>"

    def is_locked(self) -> bool:
        """Check if account is currently locked"""
        if not self.locked_until:
            return False
        from datetime import datetime
        return datetime.utcnow() < self.locked_until

    def can_login(self) -> bool:
        """Check if user can login (not locked, email verified if needed)"""
        if self.is_locked():
            return False
        if self.status != 'active':
            return False
        if self.auth_method == 'email' and not self.email_verified:
            return False
        return True
