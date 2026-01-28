"""
User Security Answer Model
Stores encrypted answers to security questions
"""

from sqlalchemy import Column, String, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class UserSecurityAnswer(Base):
    """
    User Security Answer model.

    Stores encrypted answers to security questions.
    Encryption details:
    - Each user has a unique salt (32-byte)
    - Encryption key derived using PBKDF2(password + salt, 100K iterations)
    - Answers encrypted using AES-256 (Fernet)
    - Answers are normalized (lowercase, trimmed) before encryption
    """
    __tablename__ = "user_security_answers"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign Keys
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    question_id = Column(UUID(as_uuid=True), ForeignKey('security_questions.id'), nullable=False)

    # Encrypted Data
    encrypted_answer = Column(Text, nullable=False)
    encryption_salt = Column(String(64), nullable=False)  # Base64-encoded 32-byte salt

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="security_answers")
    question = relationship("SecurityQuestion", back_populates="user_answers")

    # Constraints
    __table_args__ = (
        UniqueConstraint('user_id', 'question_id', name='unique_user_question'),
    )

    def __repr__(self):
        return f"<UserSecurityAnswer(user_id={self.user_id}, question_id={self.question_id})>"
