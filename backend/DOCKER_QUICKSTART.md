# Docker Quick Start Guide

## 🚀 Development (Local)

```bash
# Start everything
make start

# Watch logs
make logs

# Access services
http://localhost:8000/docs   # API Documentation
http://localhost:8000/health  # Health Check

# Database operations
make db-reset                 # Reset database
make db-migrate               # Run migrations
make db-shell                 # PostgreSQL shell

# Container operations
make shell                    # Backend shell
make restart                  # Restart all
make down                     # Stop all
```

## 🏭 Production Deployment

```bash
# 1. Setup environment
cp .env.production.example .env.production
nano .env.production          # Edit with secure values

# 2. Generate secrets
openssl rand -hex 32          # SECRET_KEY
openssl rand -base64 32       # ENCRYPTION_MASTER_KEY

# 3. Deploy
make prod-start

# 4. Monitor
make prod-logs                # View logs
docker stats                  # Resource usage
curl http://localhost:8000/health  # Health check
```

## 📋 Common Tasks

### Reset Database
```bash
make db-reset
```

### View Logs
```bash
make logs                     # Development
make prod-logs                # Production
```

### Update Application
```bash
git pull
make build                    # Development
make up

# OR for production
git pull
make prod-build
docker-compose -f docker-compose.prod.yml up -d --force-recreate backend
```

### Backup Database
```bash
docker-compose exec postgres pg_dump -U fleet_user fleet_db > backup.sql
```

### Access Database
```bash
make db-shell
```

## 🔧 Troubleshooting

### Services won't start
```bash
make logs                     # Check what's wrong
make down                     # Stop everything
make clean                    # Remove volumes
make start                    # Fresh start
```

### Port conflicts
```bash
netstat -ano | findstr :8000  # Find what's using port
make down                     # Stop services
```

### Out of memory
```bash
docker stats                  # Check usage
make restart                  # Restart services
```

### Build issues
```bash
docker builder prune          # Clear build cache
make build                    # Rebuild
```

## 📂 File Structure

```
backend/
├── Dockerfile                # Multi-stage build
├── docker-compose.yml        # Development
├── docker-compose.prod.yml   # Production
├── .env.docker               # Dev environment
├── .env.production           # Prod environment (don't commit!)
├── Makefile                  # Commands
└── docker-entrypoint.sh      # Startup script
```

## 🔐 Security Checklist

Before production:
- [ ] Change POSTGRES_PASSWORD
- [ ] Change REDIS_PASSWORD
- [ ] Generate new SECRET_KEY
- [ ] Generate new ENCRYPTION_MASTER_KEY
- [ ] Update CORS_ORIGINS to your domain
- [ ] Set up SSL/TLS with Nginx
- [ ] Configure firewall

## 🌐 Service URLs

### Development
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432
- Redis: localhost:6379

### Production
- Backend: https://yourdomain.com
- Database & Redis: Internal only (not exposed)

## 💡 Pro Tips

1. Keep `make logs` running while developing
2. Use `make db-reset` for quick data cleanup
3. Use `docker stats` to monitor resource usage
4. Always test with `make prod-build` before deploying
5. Back up database before major changes

## 🆘 Need Help?

1. Check logs: `make logs`
2. Check services: `docker ps`
3. Full documentation: `README_DOCKER.md`
4. Production guide: `PRODUCTION_DEPLOYMENT.md`
5. Improvements summary: `DOCKER_IMPROVEMENTS.md`

---

**Quick Commands Reference**

| Task | Development | Production |
|------|-------------|------------|
| Start | `make start` | `make prod-start` |
| Stop | `make down` | `make prod-down` |
| Logs | `make logs` | `make prod-logs` |
| Shell | `make shell` | `make prod-shell` |
| Restart | `make restart` | `docker-compose -f docker-compose.prod.yml restart` |
| Migrate | `make db-migrate` | `make prod-db-migrate` |
