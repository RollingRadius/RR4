# 🐳 Fleet Management System - Docker Setup Guide

Complete guide for running the Fleet Management System with Docker, PostgreSQL, and automated migrations.

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [First Time Setup](#first-time-setup)
- [Common Operations](#common-operations)
- [Migration Management](#migration-management)
- [Troubleshooting](#troubleshooting)
- [Environment Variables](#environment-variables)

---

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- At least 4GB RAM available for Docker
- Ports 8000, 5432, 6379 available

### Start Development Environment

```bash
# From the backend directory
./start.sh dev
```

That's it! The script will:
1. ✅ Build Docker images
2. ✅ Start PostgreSQL, Redis, and Backend
3. ✅ Wait for database to be ready
4. ✅ Run migrations automatically
5. ✅ Start the FastAPI application

### Access Your Application

- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

---

## 🏗️ Architecture Overview

### Services

1. **PostgreSQL** (`postgres`)
   - Database server
   - Automatic health checks
   - Persistent data storage
   - Internal network only (secure)

2. **Redis** (`redis`)
   - Caching and sessions
   - Persistent storage
   - Health monitoring

3. **Backend** (`backend`)
   - FastAPI application
   - Automatic migrations on startup
   - Hot-reload in development
   - Multiple workers in production

### Startup Flow

```
┌─────────────────────────────────────────────┐
│ 1. Start PostgreSQL & Redis                │
│    - Health checks ensure readiness         │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│ 2. Start Backend Container                 │
│    - Runs docker-entrypoint.sh              │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│ 3. Wait for Database (wait-for-db.sh)      │
│    - Retry logic with timeout               │
│    - Verifies database accessibility        │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│ 4. Check Migration Status                  │
│    - Detects multiple heads                 │
│    - Handles conflicts automatically        │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│ 5. Run Migrations                           │
│    - alembic upgrade head                   │
│    - Automatic retry on temporary failures  │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│ 6. Start FastAPI Application               │
│    - Development: Hot reload enabled        │
│    - Production: Multiple workers           │
└─────────────────────────────────────────────┘
```

---

## 🎯 First Time Setup

### 1. Clone and Navigate

```bash
cd E:/Projects/RR4/backend
```

### 2. Create Environment File

```bash
# Copy the example environment file
cp .env.example .env.docker

# Edit .env.docker if needed (optional)
# Default credentials work fine for development
```

### 3. Start Services

```bash
./start.sh dev
```

### 4. Verify Everything Works

```bash
# Check service status
./start.sh status

# View logs
./start.sh logs backend

# Test API
curl http://localhost:8000/health
```

### 5. (Optional) Seed Initial Data

```bash
./start.sh seed
```

---

## 🛠️ Common Operations

### Service Management

```bash
# Start development environment
./start.sh dev

# Start production environment
./start.sh prod

# Stop all services
./start.sh down

# Restart services
./start.sh restart

# View service status
./start.sh status
```

### Viewing Logs

```bash
# All services
./start.sh logs

# Backend only
./start.sh logs backend

# PostgreSQL only
./start.sh logs postgres

# Follow logs in real-time
./start.sh logs backend  # Already follows by default
```

### Shell Access

```bash
# Open bash shell in backend container
./start.sh shell

# Execute single command
./start.sh exec python --version
./start.sh exec alembic current
```

### Rebuilding

```bash
# Rebuild all images (no cache)
./start.sh rebuild

# Complete fresh start (deletes all data)
./start.sh fresh
```

---

## 🔄 Migration Management

### Automatic Migrations

Migrations run automatically when the backend container starts. No manual intervention needed!

### Manual Migration Commands

```bash
# Check current migration version
./start.sh exec alembic current

# View migration history
./start.sh exec alembic history

# Check for migration heads
./start.sh exec alembic heads

# Run migrations manually
./start.sh migrate

# Fix migration conflicts
./start.sh fix-migrations
```

### Creating New Migrations

```bash
# Auto-generate migration from model changes
./start.sh exec alembic revision --autogenerate -m "description"

# Create empty migration file
./start.sh exec alembic revision -m "description"

# After creating, restart to apply
./start.sh restart
```

### Common Migration Issues

#### Multiple Migration Heads

**Symptom**: Error about multiple heads during startup

**Fix**:
```bash
./start.sh fix-migrations
```

This will:
1. Detect multiple heads
2. Attempt to upgrade to all heads
3. Provide merge command if needed

#### Migration Conflicts

**Symptom**: Migration fails with constraint violations

**Fix**:
```bash
# 1. Check what went wrong
./start.sh logs backend

# 2. Check current state
./start.sh exec alembic current

# 3. Try downgrading one step
./start.sh exec alembic downgrade -1

# 4. Or start fresh
./start.sh clean  # Deletes all data
./start.sh dev    # Fresh start
```

#### Stuck Migration

**Symptom**: Migration hangs or times out

**Fix**:
```bash
# 1. Check database connection
./start.sh exec pg_isready -h postgres -U fleet_user -d fleet_db

# 2. Check PostgreSQL logs
./start.sh logs postgres

# 3. Restart PostgreSQL
docker-compose restart postgres

# 4. Retry migration
./start.sh migrate
```

---

## 🐛 Troubleshooting

### Services Won't Start

```bash
# 1. Check Docker is running
docker info

# 2. Check for port conflicts
netstat -ano | findstr ":8000"  # Windows
lsof -i :8000                   # Linux/Mac

# 3. View detailed logs
./start.sh logs

# 4. Check service status
./start.sh status
```

### Database Connection Issues

```bash
# 1. Verify PostgreSQL is healthy
docker-compose ps postgres

# 2. Check PostgreSQL logs
./start.sh logs postgres

# 3. Test connection manually
./start.sh exec psql -h postgres -U fleet_user -d fleet_db

# 4. Restart PostgreSQL
docker-compose restart postgres
```

### Backend Not Healthy

```bash
# 1. Check startup logs
./start.sh logs backend

# 2. Common issues:
#    - Migration failures -> ./start.sh fix-migrations
#    - Database not ready -> Wait 30s and check again
#    - Code errors -> Check logs for Python traceback

# 3. Restart backend
docker-compose restart backend
```

### Slow Startup

**Normal startup time**: 30-60 seconds

If slower:
1. Database might be initializing (first run) - wait up to 2 minutes
2. Migrations might be complex - check logs
3. Docker resources might be limited - increase Docker memory

### Data Loss

```bash
# View volumes
docker volume ls | grep fleet

# Backup database
docker-compose exec postgres pg_dump -U fleet_user fleet_db > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T postgres psql -U fleet_user -d fleet_db
```

---

## ⚙️ Environment Variables

### Database Configuration

```bash
# Required
DATABASE_URL=postgresql://fleet_user:fleet_password_2024@postgres:5432/fleet_db
DB_HOST=postgres
DB_PORT=5432
DB_NAME=fleet_db
DB_USER=fleet_user
DB_PASSWORD=fleet_password_2024

# Optional - Database Wait Configuration
DB_MAX_RETRIES=60           # Max attempts to connect (default: 60)
DB_RETRY_INTERVAL=2         # Seconds between retries (default: 2)
```

### Application Configuration

```bash
ENVIRONMENT=development     # development or production
PORT=8000                  # Application port
WORKERS=1                  # Number of Uvicorn workers (prod uses 4)
```

### Migration & Initialization

```bash
RUN_INIT_DB=false          # Run init-db.py on startup (not recommended)
RUN_SEED_DATA=false        # Run seed scripts on startup
```

### Redis Configuration

```bash
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_URL=redis://redis:6379/0
```

---

## 🔒 Security Notes

### Development vs Production

**Development** (docker-compose.yml):
- PostgreSQL and Redis accessible from host
- Hot reload enabled
- Debug logging
- Single worker
- Volume mounts for live code updates

**Production** (docker-compose.prod.yml):
- Services on internal network only
- No volume mounts
- Multiple workers
- Optimized for performance
- Uses production environment variables

### Changing Default Credentials

⚠️ **Important**: Change default passwords before deploying!

1. Update `.env.production`:
```bash
DB_PASSWORD=your_secure_password_here
```

2. Update `docker-compose.yml` or use environment variables
3. Rebuild and restart:
```bash
./start.sh rebuild
```

---

## 📊 Monitoring

### Health Checks

All services have automatic health checks:

```bash
# View health status
docker-compose ps

# Check specific service
curl http://localhost:8000/health
```

### Resource Usage

```bash
# View container resource usage
docker stats

# View specific container
docker stats fleet_backend
```

### Logs

```bash
# View logs with timestamps
./start.sh logs | grep "ERROR"

# Export logs to file
./start.sh logs backend > backend.log 2>&1
```

---

## 🚀 Advanced Usage

### Custom Docker Compose Files

```bash
# Use custom compose file
docker-compose -f docker-compose.yml -f docker-compose.custom.yml up

# Production deployment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Scaling Services

```bash
# Run multiple backend instances (requires load balancer)
docker-compose up -d --scale backend=3
```

### Development with Hot Reload

Already enabled by default in development mode:
- Code changes are picked up automatically
- No need to rebuild for Python changes
- Migrations require container restart

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Alembic Migration Guide](https://alembic.sqlalchemy.org/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 🆘 Getting Help

1. **Check logs first**: `./start.sh logs`
2. **Try fix-migrations**: `./start.sh fix-migrations`
3. **Fresh start if needed**: `./start.sh fresh` (deletes data!)
4. **Open an issue**: Include logs and steps to reproduce

---

## ✅ Checklist for Production Deployment

- [ ] Change all default passwords
- [ ] Use environment-specific .env files
- [ ] Enable SSL/TLS for PostgreSQL
- [ ] Configure Redis password
- [ ] Set up automated backups
- [ ] Configure proper logging
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Use docker-compose.prod.yml
- [ ] Configure reverse proxy (nginx)
- [ ] Set up CI/CD pipeline
- [ ] Test migration rollback procedure
- [ ] Document disaster recovery plan

---

**Happy Coding! 🚀**
