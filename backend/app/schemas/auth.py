"""
Authentication Schemas
Pydantic models for signup, login, and authentication endpoints
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import datetime

from app.utils.validators import (
    validate_username, validate_password, validate_phone,
    validate_gstin, validate_pan
)


# Security Question Schemas
class SecurityQuestionAnswer(BaseModel):
    """Security question with answer for signup"""
    question_id: str = Field(..., description="Question key (Q1-Q10)")
    question_text: str = Field(..., description="Question text")
    answer: str = Field(..., min_length=1, max_length=255, description="Answer to the question")

    @field_validator('answer')
    @classmethod
    def validate_answer(cls, v):
        if not v or not v.strip():
            raise ValueError("Answer cannot be empty")
        return v.strip()


# Company Detail Schemas
class CompanyDetailsCreate(BaseModel):
    """Company details for creating new company during signup"""
    company_name: str = Field(..., min_length=2, max_length=255)
    business_type: str = Field(..., min_length=2, max_length=50)

    # Legal Information (Optional)
    gstin: Optional[str] = Field(None, min_length=15, max_length=15)
    pan_number: Optional[str] = Field(None, min_length=10, max_length=10)
    registration_number: Optional[str] = Field(None, max_length=100)
    registration_date: Optional[str] = None  # ISO date string

    # Contact Information
    business_email: EmailStr
    business_phone: str = Field(..., min_length=10, max_length=20)

    # Address
    address: str = Field(..., min_length=5, max_length=500)
    city: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    pincode: str = Field(..., min_length=6, max_length=10)
    country: str = Field(default="India", max_length=100)

    @field_validator('gstin')
    @classmethod
    def validate_gstin_format(cls, v):
        if v:
            is_valid, error = validate_gstin(v)
            if not is_valid:
                raise ValueError(error)
        return v

    @field_validator('pan_number')
    @classmethod
    def validate_pan_format(cls, v):
        if v:
            is_valid, error = validate_pan(v)
            if not is_valid:
                raise ValueError(error)
        return v


# Signup Schemas
class SignupRequest(BaseModel):
    """User signup request (supports both email and security questions methods)"""
    # Basic Information
    full_name: str = Field(..., min_length=2, max_length=255)
    username: str = Field(..., min_length=3, max_length=50)
    email: Optional[EmailStr] = None  # Required only for email method
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=8, max_length=128)

    # Authentication Method
    auth_method: str = Field(..., pattern="^(email|security_questions)$")

    # Company Selection (Optional)
    company_type: Optional[str] = Field(None, pattern="^(existing|new)$")  # Or null to skip
    company_id: Optional[str] = None  # UUID for existing company
    company_details: Optional[CompanyDetailsCreate] = None  # For new company

    # Security Questions (Required if auth_method='security_questions')
    security_questions: Optional[List[SecurityQuestionAnswer]] = None

    # Terms
    terms_accepted: bool = Field(..., description="Must be true")

    @field_validator('username')
    @classmethod
    def validate_username_format(cls, v):
        is_valid, error = validate_username(v)
        if not is_valid:
            raise ValueError(error)
        return v

    @field_validator('password')
    @classmethod
    def validate_password_strength(cls, v):
        is_valid, error = validate_password(v)
        if not is_valid:
            raise ValueError(error)
        return v

    @field_validator('phone')
    @classmethod
    def validate_phone_format(cls, v):
        is_valid, error = validate_phone(v)
        if not is_valid:
            raise ValueError(error)
        return v

    @field_validator('terms_accepted')
    @classmethod
    def validate_terms(cls, v):
        if not v:
            raise ValueError("You must accept the terms and conditions")
        return v

    @field_validator('security_questions')
    @classmethod
    def validate_security_questions_count(cls, v, values):
        auth_method = values.data.get('auth_method')
        if auth_method == 'security_questions':
            if not v or len(v) != 3:
                raise ValueError("Exactly 3 security questions are required")
            # Check for duplicate questions
            question_ids = [q.question_id for q in v]
            if len(question_ids) != len(set(question_ids)):
                raise ValueError("Security questions must be different")
        return v

    @field_validator('email')
    @classmethod
    def validate_email_required(cls, v, values):
        auth_method = values.data.get('auth_method')
        if auth_method == 'email' and not v:
            raise ValueError("Email is required for email authentication method")
        return v


class SignupResponse(BaseModel):
    """Signup success response"""
    success: bool
    user_id: str
    username: str
    email: Optional[str]
    status: str
    auth_method: str
    company_id: Optional[str]
    company_name: Optional[str]
    role: Optional[str] = None
    capabilities: List[str]  # Empty for Pending User, ['*'] for Owner
    message: str
    verification_code: Optional[str] = None  # 6-digit code for email verification
    verification_expires_at: Optional[datetime] = None
    security_questions_count: Optional[int] = None


# Login Schemas
class LoginRequest(BaseModel):
    """User login request"""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=1)


class LoginResponse(BaseModel):
    """Login success response"""
    success: bool
    access_token: str
    token_type: str = "bearer"
    user_id: str
    username: str
    email: Optional[str]
    profile_completed: bool
    role: Optional[str]
    company_id: Optional[str]
    company_name: Optional[str]


# Email Verification Schemas
class EmailVerificationRequest(BaseModel):
    """Email verification request"""
    token: str = Field(..., min_length=10)


class EmailVerificationCodeRequest(BaseModel):
    """Email verification using 6-digit code"""
    verification_code: str = Field(..., min_length=6, max_length=6, pattern="^[0-9]{6}$")


class EmailVerificationResponse(BaseModel):
    """Email verification response"""
    success: bool
    message: str
    user_id: str
    redirect_url: Optional[str] = "/dashboard"


# Password Recovery Schemas
class ForgotPasswordRequest(BaseModel):
    """Forgot password request (email or security questions)"""
    username: str = Field(..., min_length=3, max_length=50)
    recovery_method: str = Field(..., pattern="^(email|security_questions)$")

    # For security questions method
    security_question_answers: Optional[List[SecurityQuestionAnswer]] = None
    new_password: Optional[str] = Field(None, min_length=8, max_length=128)


class PasswordResetResponse(BaseModel):
    """Password reset response"""
    success: bool
    message: str


# Username Recovery Schemas
class UsernameRecoveryRequest(BaseModel):
    """Username recovery request"""
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: str = Field(..., min_length=10, max_length=20)
    security_question_answers: List[SecurityQuestionAnswer] = Field(..., min_items=3, max_items=3)


class UsernameRecoveryResponse(BaseModel):
    """Username recovery response"""
    success: bool
    message: str
    username: Optional[str] = None


# Resend Verification Email
class ResendVerificationRequest(BaseModel):
    """Resend verification email request"""
    username: str = Field(..., min_length=3, max_length=50)


# Token Response
class TokenResponse(BaseModel):
    """Generic token response"""
    access_token: str
    token_type: str = "bearer"
