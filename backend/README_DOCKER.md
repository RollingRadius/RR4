# Fleet Management System - Docker Setup

## 🚀 Quick Start

### One Command Startup

```bash
# Start everything in development mode
./start.sh

# Or explicitly:
./start.sh dev
```

That's it! Your backend will be available at:
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Interactive API**: http://localhost:8000/redoc

---

## 📋 Prerequisites

1. **Install Docker Desktop**
   - Download from: https://www.docker.com/products/docker-desktop
   - Windows: Requires WSL 2 backend
   - Start Docker Desktop before running commands

2. **Verify Installation**
   ```bash
   docker --version
   docker compose version
   ```

---

## 🎯 Available Commands

### Basic Operations

```bash
# Start in development mode (hot reload enabled)
./start.sh dev

# Start in production mode
./start.sh prod

# Stop all services
./start.sh down

# Stop and remove all data (⚠️ deletes database)
./start.sh clean
```

### Monitoring & Debugging

```bash
# View logs for all services
./start.sh logs

# View logs for specific service
./start.sh logs backend
./start.sh logs postgres

# Check service status
./start.sh status

# Open bash shell in backend container
./start.sh shell
```

### Database Operations

```bash
# Run database migrations
./start.sh migrate

# Initialize database with seed data
./start.sh init-db

# Execute custom command in backend
./start.sh exec python seed_capabilities.py
```

### Maintenance

```bash
# Rebuild all services (after dependency changes)
./start.sh rebuild

# Show help
./start.sh help
```

---

## 🏗️ Architecture

### Services

1. **PostgreSQL** (postgres:15-alpine)
   - Port: 5432
   - Database: fleet_db
   - User: fleet_user
   - Volume: `fleet_postgres_data`

2. **Redis** (redis:7-alpine)
   - Port: 6379
   - Persistence: Append-only file
   - Volume: `fleet_redis_data`

3. **Backend** (Python 3.11 FastAPI)
   - Port: 8000
   - Workers: 4 (production), 1 (development)
   - Hot reload: Enabled in dev mode

### Network

- **fleet-network**: Bridge network for all services
- Service discovery: Services communicate using service names (e.g., `postgres`, `redis`)

### Volumes

- **postgres_data**: Persistent database storage
- **redis_data**: Redis persistence
- **./uploads**: File uploads (bind mount)
- **./logs**: Application logs (bind mount)

---

## 🔧 Configuration Files

### Environment Files

- **`.env.docker`**: Development environment variables
- **`.env.production`**: Production environment variables
- **`.env.production.example`**: Template for production config

### Docker Files

- **`Dockerfile`**: Multi-stage build (base → builder → dev/prod)
- **`docker-compose.yml`**: Development orchestration
- **`docker-compose.prod.yml`**: Production overrides
- **`.dockerignore`**: Files excluded from Docker build
- **`docker-entrypoint.sh`**: Container initialization script

---

## 🔒 Security Best Practices

### Development (Current Setup)

✅ Non-root user (`appuser` UID/GID 1001)
✅ Health checks on all services
✅ Resource limits defined
✅ Comprehensive `.dockerignore`
⚠️  Hardcoded passwords (OK for local dev)
⚠️  Exposed database ports (OK for local dev)

### Production Recommendations

When deploying to production:

1. **Use Docker Secrets** (instead of environment variables)
   ```bash
   echo "secure_password" | docker secret create db_password -
   ```

2. **Network Isolation** (use `docker-compose.prod.yml`)
   - Backend services on internal network only
   - No exposed database ports

3. **Update Secrets**
   - Generate strong random passwords
   - Use different credentials per environment
   - Never commit production secrets to git

4. **Enable HTTPS**
   - Use reverse proxy (nginx, traefik)
   - Let's Encrypt for SSL certificates

---

## 📊 Multi-Stage Build Explained

### Stage 1: Base
- Python 3.11 slim image
- Creates non-root user
- Sets working directory

### Stage 2: Builder
- Installs build dependencies (gcc, etc.)
- Installs Python packages
- Uses build cache for faster rebuilds

### Stage 3: Development
- Includes development tools (vim, curl)
- Hot reload enabled
- Volume mounts for live code updates
- Debug-friendly environment

### Stage 4: Production
- Minimal runtime dependencies only
- No build tools (smaller, more secure)
- Multiple workers for performance
- Health checks enabled
- Runs as non-root user

---

## 🐛 Troubleshooting

### Docker not running
```bash
# Error: Cannot connect to Docker daemon
# Solution: Start Docker Desktop
```

### Port already in use
```bash
# Error: Port 8000 is already allocated
# Solution: Stop conflicting service or change port in docker-compose.yml
docker-compose down
netstat -ano | findstr :8000  # Find process using port
```

### Database connection failed
```bash
# Check if PostgreSQL is healthy
./start.sh status

# View PostgreSQL logs
./start.sh logs postgres

# Reset database (⚠️ deletes data)
./start.sh clean
./start.sh dev
```

### Migrations failed
```bash
# Run migrations manually
./start.sh exec alembic upgrade head

# Check migration history
./start.sh exec alembic current

# Reset and reinitialize
./start.sh down
docker volume rm fleet_postgres_data
./start.sh dev
./start.sh init-db
```

### Permission issues (Windows)
```bash
# If you get permission errors with volumes
# Ensure Docker Desktop has access to your drive
# Settings → Resources → File Sharing → Add E:\
```

### Build cache issues
```bash
# Rebuild without cache
./start.sh rebuild
```

---

## 🔄 Development Workflow

### Daily Development
```bash
# 1. Start services (first time or after computer restart)
./start.sh

# 2. Your code changes auto-reload (no restart needed)
# Edit files in ./app/, ./alembic/, etc.

# 3. View logs if needed
./start.sh logs backend

# 4. Stop when done
./start.sh down
```

### After Dependency Changes
```bash
# When you modify requirements.txt
./start.sh rebuild
```

### Database Schema Changes
```bash
# 1. Create migration
./start.sh exec alembic revision --autogenerate -m "description"

# 2. Apply migration
./start.sh migrate

# Or do both in one step (auto-applied on container start)
```

### Testing
```bash
# Run tests in container
./start.sh exec pytest

# Run specific test
./start.sh exec pytest tests/test_auth.py -v
```

---

## 📈 Resource Usage

### Development Mode
- **CPU**: ~1.75 cores (0.5 + 0.25 + 1.0)
- **Memory**: ~1.75 GB (512MB + 256MB + 1GB)

### Production Mode
- **CPU**: ~1.75 cores
- **Memory**: ~1.75 GB
- **Workers**: 4 (can be adjusted in docker-compose.prod.yml)

### Adjust Resources
Edit `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'      # Increase CPU
      memory: 2G       # Increase memory
```

---

## 🚢 Production Deployment

### Deploy to Production

```bash
# 1. Update production environment file
cp .env.production.example .env.production
# Edit .env.production with production values

# 2. Build production image
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# 3. Start production services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Or use the shortcut
./start.sh prod
```

### Deploy to Docker Swarm
```bash
docker stack deploy -c docker-compose.yml fleet-app
```

### Deploy to Kubernetes
```bash
# Convert compose to k8s manifests
kompose convert -f docker-compose.yml
kubectl apply -f .
```

---

## 💡 Tips & Tricks

### Access Database Directly
```bash
# Using psql in container
docker exec -it fleet_postgres psql -U fleet_user -d fleet_db
```

### Backup Database
```bash
# Create backup
docker exec fleet_postgres pg_dump -U fleet_user fleet_db > backup.sql

# Restore backup
cat backup.sql | docker exec -i fleet_postgres psql -U fleet_user fleet_db
```

### Monitor Resources
```bash
# Real-time container stats
docker stats

# Disk usage
docker system df
```

### Clean Up Docker
```bash
# Remove unused images, containers, networks
docker system prune -a

# Remove all volumes (⚠️ deletes data)
docker volume prune
```

---

## 📞 Support

If you encounter issues:

1. Check logs: `./start.sh logs`
2. Check status: `./start.sh status`
3. Try rebuilding: `./start.sh rebuild`
4. Clean restart: `./start.sh clean` then `./start.sh dev`

---

## 📝 Next Steps

1. ✅ Docker setup complete
2. ⬜ Configure production secrets
3. ⬜ Set up CI/CD pipeline
4. ⬜ Add monitoring (Prometheus, Grafana)
5. ⬜ Configure reverse proxy (nginx)
6. ⬜ Set up automated backups

---

**Happy Coding! 🚀**
