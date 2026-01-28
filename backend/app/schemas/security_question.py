"""
Security Question Schemas
Pydantic models for security questions
"""

from pydantic import BaseModel, Field
from typing import List


class SecurityQuestionResponse(BaseModel):
    """Single security question"""
    question_id: str = Field(..., description="Question key (Q1-Q10)")
    question_text: str = Field(..., description="Question text")
    category: str = Field(..., description="Category (personal, memorable_events, preferences)")
    display_order: int = Field(..., description="Display order")


class SecurityQuestionsListResponse(BaseModel):
    """List of all available security questions"""
    success: bool
    questions: List[SecurityQuestionResponse]
    count: int
