"""
Token Service
Generate and manage verification tokens
"""

import secrets
import base64
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.verification_token import VerificationToken
from app.config import settings


class TokenService:
    """Service for managing verification tokens"""

    @staticmethod
    def generate_secure_token(length: int = 32) -> str:
        """
        Generate a secure random token.

        Args:
            length: Token length in bytes (default: 32)

        Returns:
            Base64-encoded token string
        """
        token_bytes = secrets.token_bytes(length)
        return base64.urlsafe_b64encode(token_bytes).decode('utf-8')

    @staticmethod
    def generate_verification_code() -> str:
        """
        Generate a 6-digit verification code.

        Returns:
            6-digit code as string (e.g., "123456")
        """
        return str(secrets.randbelow(1000000)).zfill(6)

    @staticmethod
    def create_verification_token(
        db: Session,
        user_id: str,
        token_type: str,
        expiry_hours: int = 24
    ) -> tuple:
        """
        Create a verification token for user.

        Args:
            db: Database session
            user_id: User UUID
            token_type: 'email_verification', 'password_reset', 'username_recovery'
            expiry_hours: Token expiry in hours (default: 24)

        Returns:
            Tuple of (token_string, verification_code)
        """
        # Generate secure token and verification code
        token = TokenService.generate_secure_token()
        verification_code = TokenService.generate_verification_code()

        # Calculate expiration
        expires_at = datetime.utcnow() + timedelta(hours=expiry_hours)

        # Create token record
        verification_token = VerificationToken(
            user_id=user_id,
            token=token,
            verification_code=verification_code,
            token_type=token_type,
            expires_at=expires_at
        )

        db.add(verification_token)
        db.commit()
        db.refresh(verification_token)

        return token, verification_code

    @staticmethod
    def verify_token(db: Session, token: str, token_type: str) -> tuple:
        """
        Verify a token and return user_id if valid.

        Args:
            db: Database session
            token: Token string
            token_type: Expected token type

        Returns:
            Tuple of (is_valid, user_id, error_message)
        """
        # Find token
        token_record = db.query(VerificationToken).filter(
            VerificationToken.token == token,
            VerificationToken.token_type == token_type
        ).first()

        if not token_record:
            return False, None, "Invalid or expired token"

        # Check if already used
        if token_record.used:
            return False, None, "Token has already been used"

        # Check if expired
        if token_record.is_expired():
            return False, None, "Token has expired"

        return True, str(token_record.user_id), None

    @staticmethod
    def verify_code(db: Session, verification_code: str, token_type: str) -> tuple:
        """
        Verify a 6-digit code and return user_id if valid.

        Args:
            db: Database session
            verification_code: 6-digit verification code
            token_type: Expected token type

        Returns:
            Tuple of (is_valid, user_id, error_message)
        """
        # Find token by code
        token_record = db.query(VerificationToken).filter(
            VerificationToken.verification_code == verification_code,
            VerificationToken.token_type == token_type
        ).first()

        if not token_record:
            return False, None, "Invalid verification code"

        # Check if already used
        if token_record.used:
            return False, None, "Verification code has already been used"

        # Check if expired
        if token_record.is_expired():
            return False, None, "Verification code has expired"

        return True, str(token_record.user_id), None

    @staticmethod
    def mark_token_used(db: Session, token: str):
        """Mark token as used"""
        token_record = db.query(VerificationToken).filter(
            VerificationToken.token == token
        ).first()

        if token_record:
            token_record.used = True
            token_record.used_at = datetime.utcnow()
            db.commit()

    @staticmethod
    def mark_code_used(db: Session, verification_code: str):
        """Mark verification code as used"""
        token_record = db.query(VerificationToken).filter(
            VerificationToken.verification_code == verification_code
        ).first()

        if token_record:
            token_record.used = True
            token_record.used_at = datetime.utcnow()
            db.commit()

    @staticmethod
    def invalidate_user_tokens(db: Session, user_id: str, token_type: str):
        """Invalidate all unused tokens of a specific type for a user"""
        db.query(VerificationToken).filter(
            VerificationToken.user_id == user_id,
            VerificationToken.token_type == token_type,
            VerificationToken.used == False
        ).update({"used": True, "used_at": datetime.utcnow()})
        db.commit()
