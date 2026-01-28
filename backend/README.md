# Fleet Management System - Backend API

FastAPI backend for Fleet Management System with authentication and company management.

## Setup Instructions

### 1. Prerequisites
- Python 3.10 or higher
- PostgreSQL 14 or higher
- pip (Python package manager)

### 2. Installation

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configuration

```bash
# Copy environment example
copy .env.example .env

# Edit .env with your settings:
# - DATABASE_URL: PostgreSQL connection string
# - SECRET_KEY: JWT secret (min 32 characters)
# - ENCRYPTION_MASTER_KEY: Security questions encryption key (min 32 characters)
# - SMTP settings for email functionality
```

### 4. Database Setup

```bash
# Create PostgreSQL database
createdb fleet_db

# Or using psql:
psql -U postgres
CREATE DATABASE fleet_db;
\q

# Initialize Alembic (if not already done)
alembic init alembic

# Run migrations
alembic upgrade head
```

### 5. Run Application

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or using the main.py directly
python -m app.main
```

### 6. API Documentation

Once running, access:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## Project Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI application
│   ├── config.py               # Configuration management
│   ├── database.py             # Database connection
│   ├── models/                 # SQLAlchemy models
│   ├── schemas/                # Pydantic schemas
│   ├── api/                    # API endpoints
│   │   └── v1/                 # API version 1
│   ├── services/               # Business logic
│   ├── core/                   # Core utilities
│   │   ├── security.py         # Password hashing, JWT
│   │   └── encryption.py       # Security questions encryption
│   └── utils/                  # Helper functions
├── alembic/                    # Database migrations
├── tests/                      # Test files
├── requirements.txt            # Python dependencies
├── .env.example                # Environment template
└── README.md                   # This file
```

## Features

### Authentication
- Email-based signup with verification
- Security questions signup (no email required)
- JWT authentication
- Password recovery (email + security questions)
- Username recovery
- Account lockout after failed attempts

### Company Management
- Search companies by name
- Join existing company
- Create new company with optional GSTIN/PAN
- GSTIN/PAN format validation

### Security
- Bcrypt password hashing
- AES-256 encryption for security answers
- PBKDF2 key derivation (100K iterations)
- JWT token-based authentication
- Rate limiting
- Audit logging

## API Endpoints

### Authentication
- `POST /api/auth/signup` - User signup
- `POST /api/auth/login` - User login
- `POST /api/auth/verify-email` - Email verification
- `POST /api/auth/forgot-password` - Password recovery
- `POST /api/auth/recover-username` - Username recovery
- `GET /api/auth/security-questions` - Get security questions list

### Company Management
- `GET /api/companies/search` - Search companies
- `POST /api/companies/validate` - Validate GSTIN/PAN
- `POST /api/companies/create` - Create new company

## Development

### Running Tests
```bash
pytest
```

### Database Migrations
```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1
```

### Code Quality
```bash
# Format code
black app/

# Type checking
mypy app/

# Linting
ruff check app/
```

## Environment Variables

Key environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT signing secret (min 32 chars)
- `ENCRYPTION_MASTER_KEY`: Security questions encryption (min 32 chars)
- `SMTP_*`: Email configuration for verification emails
- `MAX_FAILED_LOGIN_ATTEMPTS`: Account lockout threshold (default: 3)
- `ACCOUNT_LOCKOUT_MINUTES`: Lockout duration (default: 30)

## Security Notes

1. **Never commit** .env file or secrets to version control
2. Use strong SECRET_KEY and ENCRYPTION_MASTER_KEY in production
3. Enable HTTPS in production
4. Configure proper CORS origins
5. Use environment-specific configuration
6. Rotate secrets regularly
7. Monitor audit logs for suspicious activity

## Support

For issues or questions, refer to the main project documentation.
