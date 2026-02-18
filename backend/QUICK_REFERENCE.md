# 🚀 Fleet Management System - Quick Reference Card

One-page reference for common Docker operations.

---

## ⚡ Essential Commands

```bash
# Start everything
./start.sh dev

# Stop everything
./start.sh down

# View logs
./start.sh logs backend

# Check status
./start.sh status

# Open shell
./start.sh shell
```

---

## 🔄 Migration Commands

```bash
# Check current migration
./start.sh exec alembic current

# View history
./start.sh exec alembic history

# Fix migration issues
./start.sh fix-migrations

# Run migrations manually
./start.sh migrate

# Create new migration
./start.sh exec alembic revision --autogenerate -m "description"
```

---

## 🐛 Troubleshooting

### Backend won't start
```bash
./start.sh logs backend
./start.sh fix-migrations
```

### Database issues
```bash
./start.sh logs postgres
docker-compose restart postgres
```

### Fresh start (deletes all data)
```bash
./start.sh fresh
```

---

## 📊 Monitoring

```bash
# Service health
docker-compose ps

# Resource usage
docker stats

# Database connection
./start.sh exec psql -h postgres -U fleet_user -d fleet_db
```

---

## 🔧 Development

```bash
# Install new package
./start.sh exec pip install package_name

# Run tests
./start.sh exec pytest

# Django shell
./start.sh exec python manage.py shell

# Seed data
./start.sh seed
```

---

## 🎯 Access Points

- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- PostgreSQL: localhost:5432
- Redis: localhost:6379

---

## ⚠️ Emergency Commands

```bash
# Remove all containers and volumes
./start.sh clean

# Rebuild everything
./start.sh rebuild

# Complete reset
./start.sh fresh
```

---

## 📝 Environment Variables

Edit `.env.docker`:
- `RUN_INIT_DB=true` - Initialize database on first run
- `RUN_SEED_DATA=true` - Load seed data on startup
- `ENVIRONMENT=production` - Use production settings

---

## 🆘 Common Issues

| Issue | Solution |
|-------|----------|
| Port 8000 in use | Stop other services or change port |
| Migration fails | `./start.sh fix-migrations` |
| Database not ready | Wait 30s, check `./start.sh logs postgres` |
| Container unhealthy | Check logs: `./start.sh logs backend` |

---

**For detailed documentation, see [DOCKER_SETUP.md](./DOCKER_SETUP.md)**
