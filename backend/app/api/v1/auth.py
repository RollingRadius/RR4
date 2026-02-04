"""
Authentication API Endpoints
User signup, login, verification, and recovery
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.auth import (
    SignupRequest, SignupResponse,
    LoginRequest, LoginResponse,
    EmailVerificationRequest, EmailVerificationCodeRequest, EmailVerificationResponse,
    ForgotPasswordRequest, PasswordResetResponse,
    UsernameRecoveryRequest, UsernameRecoveryResponse,
    ResendVerificationRequest
)
from app.schemas.security_question import SecurityQuestionsListResponse, SecurityQuestionResponse
from app.services.auth_service import AuthService
from app.services.recovery_service import RecoveryService
from app.models.security_question import SecurityQuestion

router = APIRouter()


@router.post("/signup", response_model=SignupResponse, status_code=status.HTTP_201_CREATED)
def signup(
    signup_data: SignupRequest,
    db: Session = Depends(get_db)
):
    """
    User signup with support for email and security questions methods.

    **Email Method:**
    - Requires email address
    - Sends verification email
    - Account status: pending_verification
    - Must verify email before login

    **Security Questions Method:**
    - No email required
    - Must provide 3 security question answers
    - Account immediately active
    - Can login right away

    **Company Selection:**
    - Join existing company (becomes Pending User)
    - Create new company (becomes Owner)
    - Skip company selection (becomes Independent User)
    """
    auth_service = AuthService(db)

    # Convert Pydantic model to dict
    signup_dict = signup_data.model_dump()

    # Convert company_details if present
    if signup_dict.get('company_details'):
        signup_dict['company_details'] = signup_dict['company_details']

    # Convert security_questions if present
    if signup_dict.get('security_questions'):
        signup_dict['security_questions'] = [
            {
                'question_id': q.question_id,
                'question_text': q.question_text,
                'answer': q.answer
            }
            for q in signup_data.security_questions
        ]

    result = auth_service.signup(signup_dict)

    return SignupResponse(**result)


@router.post("/login", response_model=LoginResponse)
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """
    User login with username and password.

    **Requirements:**
    - Valid username and password
    - Email verified (if email method)
    - Account not locked

    **Account Lockout:**
    - 3 failed login attempts → 30-minute lockout
    - Lockout automatically expires after 30 minutes

    **Returns:**
    - JWT access token (30-minute expiry)
    - User information
    - Company information (if applicable)
    """
    auth_service = AuthService(db)

    result = auth_service.login(
        username=login_data.username,
        password=login_data.password
    )

    return LoginResponse(**result)


@router.post("/verify-email", response_model=EmailVerificationResponse)
def verify_email(
    verification_data: EmailVerificationRequest,
    db: Session = Depends(get_db)
):
    """
    Verify user's email address using verification token.

    **Process:**
    1. User receives verification email with token
    2. User clicks link or enters token
    3. Account status changes to 'active'
    4. User can now login

    **Token Expiry:** 24 hours
    """
    auth_service = AuthService(db)

    result = auth_service.verify_email(verification_data.token)

    return EmailVerificationResponse(**result)


@router.post("/verify-email-code", response_model=EmailVerificationResponse)
def verify_email_code(
    verification_data: EmailVerificationCodeRequest,
    db: Session = Depends(get_db)
):
    """
    Verify user's email address using 6-digit verification code.

    **Process:**
    1. User receives 6-digit code after signup
    2. User enters the code to verify email
    3. Account status changes to 'active'
    4. User can now login

    **Code Format:** 6 digits (000000-999999)
    **Expiry:** 24 hours

    **Example Request:**
    ```json
    {
        "verification_code": "123456"
    }
    ```
    """
    auth_service = AuthService(db)

    result = auth_service.verify_email_code(verification_data.verification_code)

    return EmailVerificationResponse(**result)


@router.post("/resend-verification")
def resend_verification(
    resend_data: ResendVerificationRequest,
    db: Session = Depends(get_db)
):
    """
    Resend verification email.

    **Use Case:**
    - User didn't receive verification email
    - Verification token expired
    """
    # TODO: Implement resend verification logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Resend verification not yet implemented"
    )


@router.post("/forgot-password/email", response_model=PasswordResetResponse)
def forgot_password_email(
    username: str,
    db: Session = Depends(get_db)
):
    """
    Initiate password reset via email.

    **Process:**
    - Sends password reset link via email
    - User clicks link to reset password
    - Token expires in 1 hour
    """
    recovery_service = RecoveryService(db)
    result = recovery_service.initiate_password_reset_email(username)
    return PasswordResetResponse(**result)


@router.get("/forgot-password/questions/{username}")
def get_user_security_questions(
    username: str,
    db: Session = Depends(get_db)
):
    """
    Get user's security questions for password recovery.

    **Returns:**
    - User's 3 security questions
    """
    recovery_service = RecoveryService(db)
    return recovery_service.get_user_security_questions(username)


@router.post("/forgot-password/verify-answers")
def verify_security_answers(
    username: str,
    answers: list,
    db: Session = Depends(get_db)
):
    """
    Verify security answers for password reset.

    **Process:**
    - User answers 3 security questions
    - If correct, returns reset token
    - 3 failed attempts → 30-minute lockout
    """
    recovery_service = RecoveryService(db)
    return recovery_service.verify_security_answers_for_password_reset(username, answers)


@router.post("/reset-password")
def reset_password(
    reset_token: str,
    new_password: str,
    db: Session = Depends(get_db)
):
    """
    Reset password using reset token.

    **Requirements:**
    - Valid reset token (from email or security questions)
    - New password meeting requirements (min 8 chars)
    """
    recovery_service = RecoveryService(db)
    return recovery_service.reset_password_with_token(reset_token, new_password)


@router.post("/recover-username", response_model=UsernameRecoveryResponse)
def recover_username(
    full_name: str,
    phone: str,
    answers: list,
    db: Session = Depends(get_db)
):
    """
    Recover username using name + phone + security questions.

    **Requirements:**
    - Full name (must match)
    - Phone number (must match)
    - Correct answers to 3 security questions

    **Security:**
    - 3 failed attempts → 30-minute lockout
    """
    recovery_service = RecoveryService(db)
    result = recovery_service.recover_username(full_name, phone, answers)
    return UsernameRecoveryResponse(**result)


@router.get("/security-questions", response_model=SecurityQuestionsListResponse)
def get_security_questions(db: Session = Depends(get_db)):
    """
    Get list of available security questions.

    **Returns:**
    - 10 predefined security questions
    - Each with ID, text, category, and display order

    **Usage:**
    - Display during signup (security questions method)
    - Display during password/username recovery
    """
    questions = db.query(SecurityQuestion).filter(
        SecurityQuestion.is_active == True
    ).order_by(SecurityQuestion.display_order).all()

    question_list = [
        SecurityQuestionResponse(
            question_id=q.question_key,
            question_text=q.question_text,
            category=q.category,
            display_order=q.display_order
        )
        for q in questions
    ]

    return SecurityQuestionsListResponse(
        success=True,
        questions=question_list,
        count=len(question_list)
    )


@router.get("/me")
def get_current_user():
    """
    Get current user information.

    **Requires:** JWT token in Authorization header

    **Returns:**
    - User profile
    - Company information
    - Role and permissions
    """
    # TODO: Implement get current user logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Get current user not yet implemented"
    )


@router.post("/logout")
def logout():
    """
    User logout.

    **Process:**
    - Invalidate JWT token (client-side)
    - Log audit event
    """
    # TODO: Implement logout logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Logout not yet implemented"
    )
