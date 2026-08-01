"""
Refresh Token Model
Long-lived, rotating tokens that let the app restore a login session even
after the short-lived access token has genuinely expired (e.g. the app
wasn't opened for a day or more) -- without the user seeing a login screen.

Only a hash of the token is stored, never the raw value -- same principle
as password hashing, so a DB leak doesn't directly expose usable tokens.
"""

from sqlalchemy import Column, String, TIMESTAMP, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.database import Base


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String(64), nullable=False, unique=True)
    created_at = Column(TIMESTAMP(timezone=True), nullable=False)
    expires_at = Column(TIMESTAMP(timezone=True), nullable=False)
    revoked = Column(Boolean, nullable=False, default=False)
