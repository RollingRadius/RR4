"""
Verification Token Model
Tokens for email verification, password reset, and username recovery
"""

from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class VerificationToken(Base):
    """
    Verification Token model.

    Used for:
    - Email verification (24-hour expiry)
    - Password reset (24-hour expiry)
    - Username recovery (24-hour expiry)

    Tokens are 32-byte secure random strings, base64-encoded.
    """
    __tablename__ = "verification_tokens"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Keys
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)

    # Token Information
    token = Column(String(255), unique=True, nullable=False, index=True)
    verification_code = Column(String(10), nullable=True, index=True)  # 6-digit code for easy verification
    token_type = Column(String(50), nullable=False)  # 'email_verification', 'password_reset', 'username_recovery'

    # Expiration
    expires_at = Column(DateTime, nullable=False, index=True)

    # Usage Tracking
    used = Column(Boolean, nullable=False, default=False)
    used_at = Column(DateTime, nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="verification_tokens")

    # Constraints
    __table_args__ = (
        CheckConstraint(
            "token_type IN ('email_verification', 'password_reset', 'username_recovery')",
            name='check_token_type'
        ),
    )

    def __repr__(self):
        return f"<VerificationToken(user_id={self.user_id}, type='{self.token_type}', used={self.used})>"

    def is_valid(self) -> bool:
        """Check if token is valid (not used and not expired)"""
        if self.used:
            return False
        from datetime import datetime
        return datetime.utcnow() < self.expires_at

    def is_expired(self) -> bool:
        """Check if token is expired"""
        from datetime import datetime
        return datetime.utcnow() >= self.expires_at
