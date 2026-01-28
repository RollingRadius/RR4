"""
Security Question Model
Predefined security questions for authentication
"""

from sqlalchemy import Column, String, Text, Integer, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.database import Base


class SecurityQuestion(Base):
    """
    Security Question model.

    Stores predefined security questions (10 questions).
    Users must select 3 different questions during signup with security_questions method.
    Questions are also used for password/username recovery.
    """
    __tablename__ = "security_questions"

    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Question Information
    question_key = Column(String(10), unique=True, nullable=False)  # 'Q1', 'Q2', ..., 'Q10'
    question_text = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)  # 'personal', 'memorable_events', 'preferences'
    display_order = Column(Integer, nullable=False)

    # Status
    is_active = Column(Boolean, nullable=False, default=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, server_default=func.now())

    # Relationships
    user_answers = relationship(
        "UserSecurityAnswer",
        back_populates="question"
    )

    def __repr__(self):
        return f"<SecurityQuestion(key='{self.question_key}', text='{self.question_text[:50]}...')>"

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "question_id": self.question_key,
            "question_text": self.question_text,
            "category": self.category,
            "display_order": self.display_order
        }
