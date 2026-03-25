# 🔄 Complete Migration Guide - Fleet Management System

Comprehensive guide for managing database migrations in development and production.

---

## 📋 Table of Contents

1. [Quick Fix for Production (Your Current Issue)](#quick-fix-for-production)
2. [Migration Scripts Overview](#migration-scripts-overview)
3. [Local Development](#local-development)
4. [Production Deployment](#production-deployment)
5. [Troubleshooting](#troubleshooting)
6. [Manual Migration](#manual-migration)

---

## 🚨 Quick Fix for Production (Your Current Issue)

**Problem**: API returns `relation "users" does not exist`
**Solution**: Apply migrations on your production server

### **Option A: Using New Migration Script** ✅ (Recommended)

```bash
# 1. Copy script to production server
scp apply-migrations-production.sh your-user@34.127.125.215:/path/to/backend/

# 2. SSH into production
ssh your-user@34.127.125.215

# 3. Navigate to backend directory
cd /path/to/backend

# 4. Make script executable
chmod +x apply-migrations-production.sh

# 5. Run migration script
./apply-migrations-production.sh
```

The script will:
- ✅ Check if containers are running
- ✅ Verify database connection
- ✅ Create backup (optional)
- ✅ Apply migrations safely
- ✅ Verify everything works

### **Option B: Quick Docker Command**

```bash
# SSH to production
ssh your-user@34.127.125.215

# Navigate to backend
cd /path/to/backend

# Apply migrations
docker-compose exec backend alembic upgrade head

# Verify
docker-compose exec backend alembic current
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"
```

### **Verify Fix**

After running migrations, test your API:

```bash
# Test from production server
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "username": "testuser",
    "email": "test@example.com",
    "phone": "1234567890",
    "password": "Test1234@",
    "auth_method": "email",
    "terms_accepted": true
  }'
```

**Expected**: User created successfully (200/201 response)
**No more**: `relation "users" does not exist` error

---

## 📦 Migration Scripts Overview

### **1. apply-migrations-production.sh** ⭐ (Production)

**Purpose**: Safely apply migrations on production server
**Use when**: Deploying to production or fixing production issues

```bash
./apply-migrations-production.sh
```

**Features**:
- Interactive safety prompts
- Database backup option
- Health checks
- Detailed error reporting
- Rollback instructions

---

### **2. create-fresh-migration.sh** (Development)

**Purpose**: Generate new migration from model changes
**Use when**: You've modified SQLAlchemy models

```bash
./create-fresh-migration.sh
```

**What it does**:
- Detects model changes
- Generates Alembic migration file
- Shows migration file location
- Provides next steps

---

### **3. reset-migrations.sh** ⚠️ (Development Only)

**Purpose**: Complete migration reset (DESTRUCTIVE!)
**Use when**: Starting fresh or fixing corrupted migrations

```bash
./reset-migrations.sh
```

**⚠️ WARNING**: This will:
- Delete ALL database tables
- Delete ALL migration files
- Create fresh initial migration
- Apply new migration

**NEVER use in production!**

---

## 🔧 Local Development

### **Workflow for Model Changes**

```bash
# 1. Modify your models in app/models/
# Example: Add new field to User model

# 2. Generate migration
./create-fresh-migration.sh

# 3. Review generated migration
cat alembic/versions/<latest_migration_file>.py

# 4. Apply migration locally
./start.sh migrate

# 5. Verify
./start.sh exec alembic current
```

### **Fresh Start (Clean Database)**

```bash
# Option 1: Using reset script
./reset-migrations.sh

# Option 2: Manual steps
./start.sh down
./start.sh clean  # Removes volumes
./start.sh dev    # Fresh start with migrations
```

### **Create Migration Manually**

```bash
# Auto-generate from model changes
./start.sh exec alembic revision --autogenerate -m "add user profile fields"

# Create empty migration
./start.sh exec alembic revision -m "custom data migration"

# Edit migration file
nano alembic/versions/<migration_file>.py

# Apply migration
./start.sh migrate
```

---

## 🚀 Production Deployment

### **Step-by-Step Production Migration**

#### **1. Backup Production Database**

```bash
# SSH to production
ssh your-user@34.127.125.215

# Create backup
docker-compose exec -T postgres pg_dump -U fleet_user -d fleet_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

#### **2. Copy Migration Files to Production**

```bash
# From local machine
cd E:/Projects/RR4/backend

# Copy migration files
scp alembic/versions/*.py your-user@34.127.125.215:/path/to/backend/alembic/versions/

# Or sync entire alembic directory
rsync -avz alembic/ your-user@34.127.125.215:/path/to/backend/alembic/
```

#### **3. Apply Migrations**

```bash
# SSH to production
ssh your-user@34.127.125.215

# Navigate to backend
cd /path/to/backend

# Run migration script
./apply-migrations-production.sh

# Or manually
docker-compose exec backend alembic upgrade head
```

#### **4. Verify Migration**

```bash
# Check migration status
docker-compose exec backend alembic current

# List tables
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

# Test API
curl http://localhost:8000/health
```

#### **5. Monitor Application**

```bash
# Watch logs
docker-compose logs -f backend

# Check for errors
docker-compose logs backend | grep -i error
```

---

## 🐛 Troubleshooting

### **Issue: Multiple Migration Heads**

**Symptom**: Error about multiple heads

**Solution**:
```bash
# Check heads
docker-compose exec backend alembic heads

# Upgrade to all heads
docker-compose exec backend alembic upgrade heads

# If that fails, merge heads
docker-compose exec backend alembic merge heads -m "merge migration branches"
docker-compose exec backend alembic upgrade head
```

---

### **Issue: Migration Conflicts**

**Symptom**: Migration fails with constraint violations

**Solutions**:

**Option 1: Downgrade and retry**
```bash
# Downgrade one step
docker-compose exec backend alembic downgrade -1

# Fix the issue in migration file
nano alembic/versions/<migration_file>.py

# Retry
docker-compose exec backend alembic upgrade head
```

**Option 2: Stamp database (skip migration)**
```bash
# Mark migration as applied without running
docker-compose exec backend alembic stamp head

# Or stamp specific revision
docker-compose exec backend alembic stamp <revision_id>
```

---

### **Issue: Database Schema Out of Sync**

**Symptom**: Alembic thinks tables exist but they don't

**Solution**:
```bash
# Drop alembic version table
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "DROP TABLE alembic_version;"

# Stamp current state
docker-compose exec backend alembic stamp head

# Or start fresh (development only)
./reset-migrations.sh
```

---

### **Issue: Migration Stuck/Timeout**

**Symptom**: Migration hangs forever

**Solutions**:

**1. Check database locks**
```bash
docker-compose exec postgres psql -U fleet_user -d fleet_db << 'EOF'
SELECT pid, usename, application_name, state, query
FROM pg_stat_activity
WHERE state != 'idle';
EOF
```

**2. Kill blocking queries**
```bash
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid != pg_backend_pid();"
```

**3. Restart PostgreSQL**
```bash
docker-compose restart postgres
sleep 10
docker-compose exec backend alembic upgrade head
```

---

### **Issue: Relation Already Exists**

**Symptom**: `relation "table_name" already exists`

**Solution**:
```bash
# Option 1: Stamp the migration as applied
docker-compose exec backend alembic stamp head

# Option 2: Drop the conflicting table
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "DROP TABLE IF EXISTS table_name CASCADE;"

# Option 3: Start fresh (development only)
./reset-migrations.sh
```

---

## 🔧 Manual Migration

### **SQL Migration Script**

If Alembic fails, use direct SQL:

```bash
# Copy manual migration script to production
scp manual-migration.sql your-user@34.127.125.215:/path/to/backend/

# SSH to production
ssh your-user@34.127.125.215

# Apply SQL migration
docker-compose exec -T postgres psql -U fleet_user -d fleet_db < manual-migration.sql
```

---

## 📊 Migration Checklist

### **Before Migration (Production)**

- [ ] Backup database
- [ ] Test migration in staging environment
- [ ] Review migration file
- [ ] Schedule maintenance window (if needed)
- [ ] Notify team/users
- [ ] Prepare rollback plan

### **During Migration**

- [ ] Monitor database performance
- [ ] Watch application logs
- [ ] Keep backup ready
- [ ] Document any issues

### **After Migration**

- [ ] Verify migration status
- [ ] Test critical API endpoints
- [ ] Monitor application metrics
- [ ] Check database table structure
- [ ] Seed data if needed
- [ ] Update documentation

---

## 🎯 Common Commands Reference

```bash
# Check current migration version
alembic current

# View migration history
alembic history

# Check migration heads
alembic heads

# Upgrade to latest
alembic upgrade head

# Upgrade to all heads (multiple branches)
alembic upgrade heads

# Downgrade one step
alembic downgrade -1

# Downgrade to specific revision
alembic downgrade <revision_id>

# Stamp database (mark as applied without running)
alembic stamp head

# Show SQL without executing
alembic upgrade head --sql

# Merge migration branches
alembic merge heads -m "merge description"
```

---

## 🔄 Complete Production Deployment Process

### **Full Workflow**

```bash
# ========================================
# On Local Machine
# ========================================

# 1. Make model changes
nano app/models/user.py

# 2. Generate migration
./create-fresh-migration.sh

# 3. Review migration
cat alembic/versions/<latest>.py

# 4. Test locally
./start.sh migrate
./start.sh logs backend

# 5. Commit changes
git add alembic/versions/<latest>.py
git commit -m "Add user profile migration"
git push origin main

# ========================================
# On Production Server
# ========================================

# 6. SSH to production
ssh your-user@34.127.125.215

# 7. Navigate to backend
cd /path/to/backend

# 8. Pull latest code
git pull origin main

# 9. Backup database
docker-compose exec -T postgres pg_dump -U fleet_user -d fleet_db > backup.sql

# 10. Apply migration
./apply-migrations-production.sh

# 11. Verify
docker-compose exec backend alembic current
curl http://localhost:8000/health

# 12. Monitor
docker-compose logs -f backend
```

---

## 📚 Additional Resources

- **Alembic Documentation**: https://alembic.sqlalchemy.org/
- **SQLAlchemy Documentation**: https://docs.sqlalchemy.org/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/

---

## 🆘 Emergency Rollback

### **If Migration Fails in Production**

```bash
# 1. Stop application
docker-compose stop backend

# 2. Restore database from backup
cat backup.sql | docker-compose exec -T postgres psql -U fleet_user -d fleet_db

# 3. Downgrade migration (if needed)
docker-compose exec backend alembic downgrade -1

# 4. Restart application
docker-compose start backend

# 5. Verify
docker-compose logs backend
```

---

**Need more help?** Check `DOCKER_SETUP.md` or run `./start.sh help`
