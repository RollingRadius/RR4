"""
Database Configuration and Session Management
SQLAlchemy setup for PostgreSQL
"""

from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator, AsyncGenerator

from app.config import settings

# Create SQLAlchemy engine (sync — used by all standard endpoints)
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,  # Verify connections before using
    pool_size=20,  # Maximum number of connections
    max_overflow=30,  # Maximum overflow connections
    echo=settings.SQL_ECHO,  # Log SQL queries — controlled independently of DEBUG
    hide_parameters=True,  # Never print real bind values (PII, tokens) even when echo is on
)

# Session factory (sync)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Async engine — used only by the GPS tracking module
_async_database_url = settings.DATABASE_URL.replace(
    "postgresql://", "postgresql+asyncpg://", 1
).replace(
    "postgresql+psycopg2://", "postgresql+asyncpg://", 1
)
async_engine = create_async_engine(
    _async_database_url,
    pool_pre_ping=True,
    echo=settings.SQL_ECHO,
    hide_parameters=True,
)
AsyncSessionLocal = async_sessionmaker(async_engine, expire_on_commit=False)

# Base class for SQLAlchemy models
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    Dependency function to get database session.
    Used with FastAPI's Depends() to inject DB session into endpoints.

    Usage:
        @app.get("/users")
        def get_users(db: Session = Depends(get_db)):
            return db.query(User).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def async_get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Async dependency for endpoints that need an async SQLAlchemy session.
    Used exclusively by the GPS tracking module.
    """
    async with AsyncSessionLocal() as session:
        yield session


def init_db():
    """
    Initialize database by creating all tables.
    Should be called on application startup.
    Note: In production, use Alembic migrations instead.
    """
    Base.metadata.create_all(bind=engine)
