"""
Core Security Utilities
Password hashing with Bcrypt and JWT token management
"""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from passlib.context import CryptContext
from jose import JWTError, jwt

from app.config import settings

# Password hashing context
# Use argon2 instead of bcrypt due to Python 3.13 compatibility issues
# Argon2 is more secure and modern than bcrypt
try:
    pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
except Exception:
    # Fallback to pbkdf2_sha256 if argon2 not available
    pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash a password using Bcrypt.

    Args:
        password: Plain text password

    Returns:
        Hashed password string

    Example:
        hashed = hash_password("mySecurePassword123")

    Note:
        Bcrypt has a maximum password length of 72 bytes.
        Longer passwords are truncated.
    """
    # Bcrypt has a 72-byte limit, truncate if needed
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        password_bytes = password_bytes[:72]
        password = password_bytes.decode('utf-8', errors='ignore')

    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against a hashed password.

    Args:
        plain_password: Plain text password from user input
        hashed_password: Hashed password from database

    Returns:
        True if password matches, False otherwise

    Example:
        is_valid = verify_password("userInput", user.password_hash)
    """
    # Bcrypt has a 72-byte limit, truncate if needed
    password_bytes = plain_password.encode('utf-8')
    if len(password_bytes) > 72:
        password_bytes = password_bytes[:72]
        plain_password = password_bytes.decode('utf-8', errors='ignore')

    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a JWT access token.

    Args:
        data: Dictionary of claims to encode in the token
        expires_delta: Optional custom expiration time

    Returns:
        Encoded JWT token string

    Example:
        token = create_access_token({
            "sub": str(user.id),
            "username": user.username,
            "role": user.role,
            "company_id": str(user.company_id)
        })
    """
    to_encode = data.copy()

    # Set expiration time
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode.update({"exp": expire})
    to_encode.update({"iat": datetime.utcnow()})  # Issued at

    # Encode JWT
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Decode and verify a JWT access token.

    Args:
        token: JWT token string

    Returns:
        Dictionary of decoded token payload, or None if invalid

    Example:
        payload = decode_access_token(token)
        if payload:
            user_id = payload.get("sub")
            username = payload.get("username")
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None


def create_refresh_token(data: Dict[str, Any]) -> str:
    """
    Create a JWT refresh token with longer expiration.

    Args:
        data: Dictionary of claims to encode

    Returns:
        Encoded JWT refresh token
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "iat": datetime.utcnow(), "type": "refresh"})

    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def verify_token_type(token: str, expected_type: str = "access") -> bool:
    """
    Verify token type (access vs refresh).

    Args:
        token: JWT token string
        expected_type: Expected token type ("access" or "refresh")

    Returns:
        True if token is of expected type, False otherwise
    """
    payload = decode_access_token(token)
    if not payload:
        return False

    token_type = payload.get("type", "access")  # Default to access if not specified
    return token_type == expected_type


def extract_user_id_from_token(token: str) -> Optional[str]:
    """
    Extract user ID from JWT token.

    Args:
        token: JWT token string

    Returns:
        User ID string, or None if invalid token
    """
    payload = decode_access_token(token)
    if payload:
        return payload.get("sub")
    return None


def is_token_expired(token: str) -> bool:
    """
    Check if a JWT token is expired.

    Args:
        token: JWT token string

    Returns:
        True if expired, False if still valid
    """
    payload = decode_access_token(token)
    if not payload:
        return True

    exp_timestamp = payload.get("exp")
    if not exp_timestamp:
        return True

    expiration = datetime.fromtimestamp(exp_timestamp)
    return datetime.utcnow() > expiration
