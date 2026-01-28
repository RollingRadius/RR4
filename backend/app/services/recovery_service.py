"""
Recovery Service
Handles password recovery and username recovery operations
"""
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import datetime, timedelta
import secrets
from typing import Dict, List

from app.models.user import User
from app.models.security_question import SecurityQuestion
from app.models.user_security_answer import UserSecurityAnswer
from app.models.verification_token import VerificationToken
from app.models.recovery_attempt import RecoveryAttempt
from app.core.security import hash_password
from app.core.encryption import decrypt_and_compare
from app.services.email_service import EmailService


class RecoveryService:
    def __init__(self, db: Session):
        self.db = db
        self.email_service = EmailService()

    def _check_recovery_attempts(self, user_id: str, attempt_type: str) -> None:
        """Check if user has exceeded recovery attempts limit"""
        cutoff_time = datetime.utcnow() - timedelta(minutes=30)

        failed_attempts = self.db.query(RecoveryAttempt).filter(
            RecoveryAttempt.user_id == user_id,
            RecoveryAttempt.attempt_type == attempt_type,
            RecoveryAttempt.success == False,
            RecoveryAttempt.attempted_at > cutoff_time
        ).count()

        if failed_attempts >= 3:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed recovery attempts. Please try again in 30 minutes."
            )

    def _log_recovery_attempt(
        self,
        user_id: str,
        attempt_type: str,
        success: bool,
        details: Dict = None
    ) -> None:
        """Log a recovery attempt"""
        attempt = RecoveryAttempt(
            user_id=user_id,
            attempt_type=attempt_type,
            success=success,
            details=details or {}
        )
        self.db.add(attempt)
        self.db.commit()

    def initiate_password_reset_email(self, username: str) -> Dict:
        """Initiate password reset via email"""
        # Find user by username
        user = self.db.query(User).filter(User.username == username).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if user.auth_method != 'email':
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email recovery is only available for email-authenticated accounts"
            )

        if not user.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No email address associated with this account"
            )

        # Check recovery attempts
        self._check_recovery_attempts(user.id, 'password_reset_email')

        # Generate reset token
        reset_token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + timedelta(hours=1)  # 1 hour expiry

        # Create or update verification token
        token_record = self.db.query(VerificationToken).filter(
            VerificationToken.user_id == user.id,
            VerificationToken.token_type == 'password_reset'
        ).first()

        if token_record:
            token_record.token = reset_token
            token_record.expires_at = expires_at
            token_record.used = False
        else:
            token_record = VerificationToken(
                user_id=user.id,
                token=reset_token,
                token_type='password_reset',
                expires_at=expires_at
            )
            self.db.add(token_record)

        self.db.commit()

        # Send reset email
        self.email_service.send_password_reset_email(user.email, user.username, reset_token)

        # Log successful attempt
        self._log_recovery_attempt(user.id, 'password_reset_email', True)

        return {
            "message": "Password reset link sent to your email",
            "success": True
        }

    def get_user_security_questions(self, username: str) -> Dict:
        """Get user's security questions for recovery"""
        # Find user
        user = self.db.query(User).filter(User.username == username).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Get user's security questions
        user_answers = self.db.query(UserSecurityAnswer).filter(
            UserSecurityAnswer.user_id == user.id
        ).all()

        if not user_answers:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No security questions set up for this account"
            )

        # Get question details
        question_ids = [ua.question_id for ua in user_answers]
        questions = self.db.query(SecurityQuestion).filter(
            SecurityQuestion.id.in_(question_ids)
        ).all()

        return {
            "username": username,
            "questions": [
                {
                    "question_id": str(q.id),
                    "question_key": q.question_key,
                    "question_text": q.question_text
                }
                for q in questions
            ]
        }

    def verify_security_answers_for_password_reset(
        self,
        username: str,
        answers: List[Dict]
    ) -> Dict:
        """Verify security answers for password reset"""
        # Find user
        user = self.db.query(User).filter(User.username == username).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Check recovery attempts
        self._check_recovery_attempts(user.id, 'password_reset_security')

        # Get user's security answers
        user_answers = self.db.query(UserSecurityAnswer).filter(
            UserSecurityAnswer.user_id == user.id
        ).all()

        if len(answers) != len(user_answers):
            self._log_recovery_attempt(user.id, 'password_reset_security', False)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Expected {len(user_answers)} answers"
            )

        # Verify all answers
        correct_answers = 0
        for answer_input in answers:
            question_id = answer_input.get('question_id')
            user_answer_text = answer_input.get('answer')

            # Find stored answer
            stored_answer = next(
                (ua for ua in user_answers if str(ua.question_id) == question_id),
                None
            )

            if not stored_answer:
                continue

            # Decrypt and compare
            if decrypt_and_compare(
                stored_answer.encrypted_answer,
                user_answer_text,
                user.password_hash,  # Using password hash as key material
                stored_answer.encryption_salt
            ):
                correct_answers += 1

        # All answers must be correct
        if correct_answers == len(user_answers):
            self._log_recovery_attempt(user.id, 'password_reset_security', True)

            # Generate reset token
            reset_token = secrets.token_urlsafe(32)
            expires_at = datetime.utcnow() + timedelta(minutes=30)

            token_record = VerificationToken(
                user_id=user.id,
                token=reset_token,
                token_type='password_reset',
                expires_at=expires_at
            )
            self.db.add(token_record)
            self.db.commit()

            return {
                "message": "Security answers verified",
                "success": True,
                "reset_token": reset_token
            }
        else:
            self._log_recovery_attempt(user.id, 'password_reset_security', False)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect security answers"
            )

    def reset_password_with_token(
        self,
        reset_token: str,
        new_password: str
    ) -> Dict:
        """Reset password using reset token"""
        # Find token
        token_record = self.db.query(VerificationToken).filter(
            VerificationToken.token == reset_token,
            VerificationToken.token_type == 'password_reset',
            VerificationToken.used == False
        ).first()

        if not token_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )

        # Check expiration
        if token_record.expires_at < datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reset token has expired"
            )

        # Get user
        user = self.db.query(User).filter(User.id == token_record.user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        # Update password
        user.password_hash = hash_password(new_password)
        user.failed_login_attempts = 0
        user.locked_until = None

        # Mark token as used
        token_record.used = True

        self.db.commit()

        return {
            "message": "Password reset successful",
            "success": True
        }

    def recover_username(
        self,
        full_name: str,
        phone: str,
        answers: List[Dict]
    ) -> Dict:
        """Recover username using security questions"""
        # Find user by full name and phone
        user = self.db.query(User).filter(
            User.full_name == full_name,
            User.phone == phone
        ).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No account found with the provided details"
            )

        # Check recovery attempts
        self._check_recovery_attempts(user.id, 'username_recovery')

        # Get user's security answers
        user_answers = self.db.query(UserSecurityAnswer).filter(
            UserSecurityAnswer.user_id == user.id
        ).all()

        if not user_answers:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No security questions set up for this account"
            )

        if len(answers) != len(user_answers):
            self._log_recovery_attempt(user.id, 'username_recovery', False)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Expected {len(user_answers)} answers"
            )

        # Verify all answers
        correct_answers = 0
        for answer_input in answers:
            question_id = answer_input.get('question_id')
            user_answer_text = answer_input.get('answer')

            stored_answer = next(
                (ua for ua in user_answers if str(ua.question_id) == question_id),
                None
            )

            if not stored_answer:
                continue

            if decrypt_and_compare(
                stored_answer.encrypted_answer,
                user_answer_text,
                user.password_hash,
                stored_answer.encryption_salt
            ):
                correct_answers += 1

        # All answers must be correct
        if correct_answers == len(user_answers):
            self._log_recovery_attempt(user.id, 'username_recovery', True)

            return {
                "message": "Username recovered successfully",
                "success": True,
                "username": user.username
            }
        else:
            self._log_recovery_attempt(user.id, 'username_recovery', False)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect security answers"
            )
