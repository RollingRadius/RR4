# Fleet Management System - Docker Setup Guide

Complete Docker setup for the Fleet Management System backend with PostgreSQL and Redis.

## 🚀 Quick Start

### One Command Setup

```bash
make start
```

This will:
- Build Docker images
- Start PostgreSQL, Redis, OSRM, and Backend
- Run database migrations
- Show you the URLs

### Access Your Application

- 📍 **API Docs**: http://localhost:8000/docs
- 📍 **Backend**: http://localhost:8000
- 📍 **PostgreSQL**: localhost:5432
- 📍 **Redis**: localhost:6379

## 📋 Available Commands

### Docker Operations
```bash
make help          # Show all commands
make build         # Build Docker images
make up            # Start all services
make down          # Stop all services
make restart       # Restart all services
make logs          # View logs (Ctrl+C to exit)
make shell         # Open shell in backend container
```

### Database Operations
```bash
make db-init       # Initialize database (create all tables)
make db-reset      # ⚠️  DELETE ALL DATA and reset database
make db-migrate    # Run Alembic migrations
make db-shell      # Open PostgreSQL shell
```

### Cleanup
```bash
make clean         # Stop services and remove volumes
make clean-all     # Remove everything (images, volumes, networks)
```

## 🗑️ Database Reset - DELETE ALL DATA

⚠️ **WARNING: This will permanently delete all data!**

```bash
# Method 1: Using Make (recommended)
make db-reset

# Method 2: Direct command
docker-compose exec -it backend python reset-db.py
```

**You'll see this menu:**
```
Select reset option:
1. Drop and recreate all tables (complete reset)
2. Truncate tables (delete data, keep structure)
3. Cancel

Enter choice (1/2/3):
```

Then type **`DELETE ALL DATA`** to confirm.

### Reset Options Explained

**Option 1: Complete Reset**
- Drops ALL tables
- Recreates fresh schema
- Resets migration history
- Use when schema changed

**Option 2: Truncate Tables**
- Keeps table structure
- Deletes all data
- Preserves migration history
- Faster, use for testing

## 🏗️ Architecture

### Services in docker-compose.yml

| Service | Port | Description |
|---------|------|-------------|
| **postgres** | 5432 | PostgreSQL 15 database |
| **redis** | 6379 | Redis cache |
| **backend** | 8000 | FastAPI application |
| **osrm** | 5000 | Routing service |

### Database Credentials (Development)

```
Host: localhost (or postgres from containers)
Port: 5432
Database: fleet_db
Username: fleet_user
Password: fleet_password_2024
```

## 🧪 Development Workflow

### 1. First Time Setup

```bash
cd backend
make start
```

### 2. Making Code Changes

Your code is live-reloaded! Just save files and the server restarts automatically.

```bash
# Watch logs while developing
make logs
```

### 3. Database Migrations

```bash
# Create new migration
docker-compose exec backend alembic revision --autogenerate -m "add new table"

# Apply migrations
make db-migrate

# Check migration history
docker-compose exec backend alembic history
```

### 4. Resetting Data During Development

```bash
# Quick reset
make db-reset

# Or full teardown
make clean
make start
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check what's wrong
make logs

# Check if ports are in use
netstat -an | findstr "8000 5432"

# Nuclear option
make clean-all
make start
```

### Database connection errors

```bash
# Check PostgreSQL health
docker-compose ps

# Test connection
docker-compose exec postgres pg_isready -U fleet_user

# View database logs
docker-compose logs postgres
```

### Permission issues on Windows

```bash
# Make sure Docker Desktop is running as admin
# Check WSL2 is enabled
wsl --list --verbose
```

## 📊 Accessing Services

### API Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### Database Access
```bash
# Using make command
make db-shell

# Then in psql:
\dt                    # List all tables
\d users              # Describe users table
SELECT * FROM users;  # Query users
```

### Redis Access
```bash
docker-compose exec redis redis-cli
> PING
> KEYS *
```

## 📁 Important Files

```
backend/
├── Dockerfile              # Backend container definition
├── docker-compose.yml      # All services orchestration
├── docker-entrypoint.sh    # Startup script (auto-runs migrations)
├── .env.docker             # Docker environment variables
├── .dockerignore           # Exclude files from Docker image
├── Makefile                # Shortcut commands
├── init-db.py              # Manual DB initialization script
├── reset-db.py             # ⚠️ Database reset script
└── README_DOCKER.md        # This file
```

## 🔒 Security Notes

### ⚠️ For Production - Change These!

1. **Database password** in `docker-compose.yml` and `.env.docker`
2. **SECRET_KEY** in `.env.docker`
3. **ENCRYPTION_MASTER_KEY** in `.env.docker`
4. **CORS origins** - restrict to your domain
5. Enable **SSL** for PostgreSQL connections

## 📝 Common Commands

```bash
# View all containers
docker-compose ps

# Check resource usage
docker stats

# Backup database
docker-compose exec postgres pg_dump -U fleet_user fleet_db > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T postgres psql -U fleet_user -d fleet_db

# Execute Python in container
docker-compose exec backend python
>>> from app.database import SessionLocal
>>> db = SessionLocal()
```

## 🎯 Quick Reference

```bash
# Start everything
make start

# View logs
make logs

# Reset database
make db-reset

# Stop everything
make down

# Clean everything
make clean-all
```

## 💡 Pro Tips

1. **Keep docker-compose running** while developing (auto-reload works)
2. **Use `make logs`** to watch what's happening
3. **Commit before** running `make db-reset` (can't undo!)
4. **Check health** with `docker-compose ps` if something's wrong
5. **Read the logs** - they usually tell you what's wrong

---

## 🆘 Need Help?

- Check logs: `make logs`
- View services: `docker-compose ps`
- Access shell: `make shell`
- Reset everything: `make clean-all && make start`

Made with ❤️ for Fleet Management System
