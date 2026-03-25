# 🚀 Fleet Management Backend

Clean Python FastAPI backend with white-label branding support.

## 📋 Prerequisites

- Python 3.11+
- PostgreSQL database running
- Redis (optional, for caching)

## 🔧 Setup

### 1. Create Virtual Environment

```bash
python -m venv venv
```

### 2. Activate Virtual Environment

**Windows:**
```bash
venv\Scripts\activate
```

**Linux/Mac:**
```bash
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment

Create `.env` file in backend directory:

```env
# Database
DATABASE_URL=postgresql://fleet_user:fleet_password_2024@localhost:5432/fleet_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fleet_db
DB_USER=fleet_user
DB_PASSWORD=fleet_password_2024

# Application
APP_NAME=Fleet Management System
APP_VERSION=1.0.0
ENVIRONMENT=development
DEBUG=True
SECRET_KEY=your-secret-key-here

# Server
HOST=0.0.0.0
PORT=8000

# File Uploads
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=10485760

# CORS
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080","http://localhost:5173"]
```

### 5. Run Database Migrations

```bash
alembic upgrade head
```

### 6. Seed Initial Data (Optional)

```bash
python seed_capabilities.py
```

## 🚀 Start Server

### Quick Start (Windows)

```bash
start.bat
```

### Manual Start

```bash
# Activate virtual environment first
venv\Scripts\activate

# Start server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 📊 Endpoints

Once running, access:

- **API Docs:** http://localhost:8000/docs
- **Health Check:** http://localhost:8000/health
- **Branding API:** http://localhost:8000/api/v1/branding

## 🎨 Branding Features

The backend includes white-label branding support:

### Get Branding
```bash
GET /api/v1/branding
Authorization: Bearer {token}
```

### Update Colors
```bash
PUT /api/v1/branding
Content-Type: application/json
Authorization: Bearer {token}

{
  "colors": {
    "primary_color": "#1E40AF",
    "primary_dark": "#1E3A8A",
    "primary_light": "#3B82F6",
    "secondary_color": "#06B6D4",
    "accent_color": "#0EA5E9",
    "background_primary": "#F8FAFC",
    "background_secondary": "#FFFFFF"
  }
}
```

### Upload Logo
```bash
POST /api/v1/branding/logo
Content-Type: multipart/form-data
Authorization: Bearer {token}

file: [logo.png]
```

### Delete Logo
```bash
DELETE /api/v1/branding/logo
Authorization: Bearer {token}
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/          # API endpoints
│   ├── models/       # Database models
│   ├── schemas/      # Pydantic schemas
│   ├── services/     # Business logic
│   ├── core/         # Core functionality
│   ├── utils/        # Utilities
│   └── main.py       # FastAPI application
├── alembic/          # Database migrations
├── uploads/          # Uploaded files (logos)
├── requirements.txt  # Python dependencies
├── alembic.ini      # Alembic configuration
└── README.md        # This file
```

## 🗄️ Database

### Run Migrations
```bash
alembic upgrade head
```

### Create New Migration
```bash
alembic revision --autogenerate -m "description"
```

### Check Current Migration
```bash
alembic current
```

### Migration History
```bash
alembic history
```

## 🔧 Utilities

### Initialize Database
```bash
python init-db.py
```

### Reset Database (⚠️ Deletes all data)
```bash
python reset-db.py
```

### Seed Capabilities
```bash
python seed_capabilities.py
```

## 📦 Key Dependencies

- **FastAPI** - Web framework
- **SQLAlchemy** - ORM
- **Alembic** - Database migrations
- **Pydantic** - Data validation
- **Uvicorn** - ASGI server
- **PostgreSQL** - Database
- **Python-multipart** - File uploads

## 🛠️ Development

### Install Dev Dependencies
```bash
pip install -r requirements.txt
```

### Run with Auto-reload
```bash
uvicorn app.main:app --reload
```

### Access Interactive API Docs
http://localhost:8000/docs

## 🔐 Authentication

The API uses JWT tokens. Get a token by:

```bash
POST /api/auth/login
Content-Type: application/json

{
  "username": "your_username",
  "password": "your_password"
}
```

Use the returned token in subsequent requests:
```
Authorization: Bearer {access_token}
```

## ✅ Health Check

```bash
curl http://localhost:8000/health
```

Response:
```json
{
  "status": "healthy",
  "app_name": "Fleet Management System",
  "version": "1.0.0"
}
```

## 📝 Environment Variables

Required:
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY` - JWT secret key

Optional:
- `DEBUG` - Enable debug mode (default: False)
- `CORS_ORIGINS` - Allowed CORS origins
- `UPLOAD_DIR` - Upload directory path (default: ./uploads)

## 🚀 Production Deployment

For production, use multiple workers:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

Or use Gunicorn:

```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## 📞 Support

- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

---

**Built with FastAPI** | **White-Label Branding Enabled** 🎨
