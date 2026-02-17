# 🐳 Docker Backend - Quick Start Guide

## Prerequisites
- Docker Desktop installed and running
- Docker Compose installed (included with Docker Desktop)

## 🚀 Quick Start

### Option 1: Using Docker Compose (Recommended)
```bash
# Start all services (PostgreSQL + Redis + Backend)
cd backend
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

### Option 2: Using start-prod.sh script
```bash
cd backend
./start-prod.sh
```

## 📋 Services

The docker-compose setup includes:

1. **PostgreSQL** (port 5432)
   - Database: fleet_db
   - User: fleet_user
   - Password: fleet_password_2024

2. **Redis** (port 6379)
   - For caching and sessions

3. **Backend API** (port 8000)
   - FastAPI with hot-reload
   - Automatic migrations on startup
   - Health check: http://localhost:8000/health

4. **OSRM** (port 5000)
   - Routing service

## 🔍 Verify Everything Works

1. **Check service status:**
   ```bash
   docker-compose ps
   ```

2. **Check backend health:**
   ```bash
   curl http://localhost:8000/health
   ```

3. **View API docs:**
   Open http://localhost:8000/docs in your browser

4. **Check branding endpoint:**
   ```bash
   # After logging in and getting a token
   curl -H "Authorization: Bearer <your-token>" http://localhost:8000/api/v1/branding
   ```

## 📁 Persistent Data

All data is persisted in Docker volumes:
- `fleet_postgres_data` - Database data
- `fleet_redis_data` - Redis cache
- `./uploads` - Uploaded logos (mapped to host)
- `./logs` - Application logs (mapped to host)

## 🔄 Database Migrations

Migrations run automatically on container startup via `docker-entrypoint.sh`.

The new `012_add_organization_branding` migration will create the branding table automatically.

## 🎨 Branding Features

The Docker setup includes:
- ✅ `/uploads` directory for logo storage
- ✅ Static file serving at `/uploads`
- ✅ Automatic branding table creation
- ✅ Default branding for existing organizations

## 🛠️ Common Commands

```bash
# Restart backend only
docker-compose restart backend

# View backend logs
docker-compose logs -f backend

# Access backend container shell
docker-compose exec backend bash

# Run Alembic commands
docker-compose exec backend alembic history
docker-compose exec backend alembic current

# Reset database (WARNING: Deletes all data)
docker-compose down -v
docker-compose up -d

# Rebuild backend (after code changes)
docker-compose up -d --build backend
```

## 🔧 Troubleshooting

### Backend won't start
```bash
# Check logs
docker-compose logs backend

# Ensure PostgreSQL is healthy
docker-compose ps postgres

# Restart services
docker-compose restart
```

### Migration errors
```bash
# Check migration status
docker-compose exec backend alembic current

# View migration history
docker-compose exec backend alembic history

# Manually run migrations
docker-compose exec backend alembic upgrade head
```

### Port already in use
```bash
# Change ports in docker-compose.yml:
# ports:
#   - "8001:8000"  # Change 8000 to 8001
```

### File upload not working
```bash
# Check uploads directory permissions
ls -la backend/uploads

# Recreate uploads directory
docker-compose exec backend mkdir -p /app/uploads
docker-compose exec backend chown -R appuser:appgroup /app/uploads
```

## 🌐 Connect Frontend

Update your Flutter app config:
```dart
// frontend/lib/core/config/app_config.dart
static const String apiBaseUrl = 'http://localhost:8000';
```

Then run:
```bash
cd frontend
flutter run
```

## 🎯 Test Branding API

1. **Login and get token:**
   ```bash
   curl -X POST http://localhost:8000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"your_username","password":"your_password"}'
   ```

2. **Get branding:**
   ```bash
   curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/v1/branding
   ```

3. **Upload logo:**
   ```bash
   curl -X POST http://localhost:8000/api/v1/branding/logo \
     -H "Authorization: Bearer <token>" \
     -F "file=@/path/to/logo.png"
   ```

4. **Update colors:**
   ```bash
   curl -X PUT http://localhost:8000/api/v1/branding \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{
       "colors": {
         "primary_color": "#FF5733",
         "primary_dark": "#C70039",
         "primary_light": "#FF8D7D"
       }
     }'
   ```

## 📊 Access Uploaded Logos

Logos are accessible at:
```
http://localhost:8000/uploads/logos/{organization_id}/{filename}
```

Example:
```
http://localhost:8000/uploads/logos/123e4567-e89b-12d3-a456-426614174000/logo_20260217_120000.png
```

## 🔐 Production Deployment

For production, use `docker-compose.prod.yml`:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

This uses:
- Multi-worker Uvicorn
- Non-root user
- Production environment variables
- Optimized Docker image

---

**Need Help?** Check the logs:
```bash
docker-compose logs -f
```
