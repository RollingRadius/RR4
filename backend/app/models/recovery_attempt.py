"""
Recovery Attempt Model
Tracks password recovery and login attempts for rate limiting
"""

from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class RecoveryAttempt(Base):
    """
    Recovery Attempt model.

    Tracks:
    - Login attempts (for account lockout after 3 failed attempts)
    - Password recovery attempts via security questions
    - Username recovery attempts

    Used for rate limiting and security monitoring.
    """
    __tablename__ = "recovery_attempts"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Keys
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)

    # Attempt Information
    attempt_type = Column(String(50), nullable=False)  # 'login', 'security_questions', 'password_reset'
    success = Column(Boolean, nullable=False)

    # Request Metadata
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="recovery_attempts")

    def __repr__(self):
        return f"<RecoveryAttempt(user_id={self.user_id}, type='{self.attempt_type}', success={self.success})>"
