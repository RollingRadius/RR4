# 🚀 Production Migration - Quick Start

**Fix your production server in 5 minutes!**

---

## ⚡ Your Current Issue

```
Error: relation "users" does not exist
```

**Cause**: Migrations haven't run on production server
**Fix**: Apply migrations (see below)

---

## 🎯 Quick Fix (3 Steps)

### **Step 1: SSH to Production**

```bash
ssh your-user@34.127.125.215
```

### **Step 2: Navigate to Backend**

```bash
cd /path/to/backend  # Update with your actual path
```

### **Step 3: Run Migrations**

```bash
docker-compose exec backend alembic upgrade head
```

---

## ✅ Verify It Worked

```bash
# Check migration status
docker-compose exec backend alembic current

# List database tables
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

# Test API
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "username": "testuser123",
    "email": "test@example.com",
    "phone": "1234567890",
    "password": "Test1234@",
    "auth_method": "email",
    "terms_accepted": true
  }'
```

**Expected**: User created successfully (no more "users" table error!)

---

## 🛡️ Safe Method (Recommended for Production)

### **Copy Migration Script to Production**

```bash
# From your local machine
scp apply-migrations-production.sh your-user@34.127.125.215:/path/to/backend/
```

### **Run on Production Server**

```bash
# SSH to production
ssh your-user@34.127.125.215

# Navigate to backend
cd /path/to/backend

# Make executable
chmod +x apply-migrations-production.sh

# Run script (includes safety checks and backup option)
./apply-migrations-production.sh
```

This script will:
- ✅ Check if containers are running
- ✅ Verify database is accessible
- ✅ Offer to create backup
- ✅ Apply migrations safely
- ✅ Verify everything works

---

## 📊 Expected Output

### **Before Migration**

```bash
$ docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"
Did not find any relations.
```

### **After Migration**

```bash
$ docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

                      List of relations
 Schema |           Name            | Type  |    Owner
--------+---------------------------+-------+-------------
 public | alembic_version          | table | fleet_user
 public | audit_logs               | table | fleet_user
 public | budgets                  | table | fleet_user
 public | capabilities             | table | fleet_user
 public | companies                | table | fleet_user
 public | custom_roles             | table | fleet_user
 public | dashboards               | table | fleet_user
 public | drivers                  | table | fleet_user
 public | expense_attachments      | table | fleet_user
 public | expenses                 | table | fleet_user
 public | gps_tracking             | table | fleet_user
 public | inspections              | table | fleet_user
 public | invoice_line_items       | table | fleet_user
 public | invoices                 | table | fleet_user
 public | kpis                     | table | fleet_user
 public | maintenance_schedules    | table | fleet_user
 public | organizations            | table | fleet_user
 public | part_usage               | table | fleet_user
 public | parts                    | table | fleet_user
 public | payments                 | table | fleet_user
 public | recovery_attempts        | table | fleet_user
 public | reports                  | table | fleet_user
 public | role_capabilities        | table | fleet_user
 public | roles                    | table | fleet_user
 public | security_questions       | table | fleet_user
 public | user_organizations       | table | fleet_user
 public | user_security_answers    | table | fleet_user
 public | users                    | table | fleet_user
 public | vehicles                 | table | fleet_user
 public | vendors                  | table | fleet_user
 public | verification_tokens      | table | fleet_user
 public | work_orders              | table | fleet_user
 public | zones                    | table | fleet_user
```

---

## 🚨 If Something Goes Wrong

### **Migration Fails**

```bash
# Check backend logs
docker-compose logs backend

# Check PostgreSQL logs
docker-compose logs postgres

# Try migration script with backup
./apply-migrations-production.sh
```

### **Containers Not Running**

```bash
# Check status
docker-compose ps

# Start containers
docker-compose up -d

# Wait 30 seconds for database
sleep 30

# Retry migration
docker-compose exec backend alembic upgrade head
```

### **Still Having Issues?**

```bash
# Create backup first
docker-compose exec -T postgres pg_dump -U fleet_user -d fleet_db > backup.sql

# Use reset script (ONLY if you can afford to lose data)
./reset-migrations.sh
```

---

## 📋 Complete Checklist

- [ ] SSH into production server
- [ ] Navigate to backend directory
- [ ] Verify containers are running (`docker-compose ps`)
- [ ] Backup database (recommended)
- [ ] Run `alembic upgrade head`
- [ ] Verify tables exist
- [ ] Test API endpoints
- [ ] Monitor application logs

---

## 🎉 After Migration Success

Your API will now work! All endpoints should respond correctly:

- ✅ `/api/auth/signup` - Create new users
- ✅ `/api/auth/login` - User authentication
- ✅ All other endpoints

---

## 🔄 For Future Deployments

### **Automated Migration on Container Start**

Your new Docker setup (with enhanced `docker-entrypoint.sh`) automatically runs migrations on container start!

**Deploy new setup:**

```bash
# Copy new files to production
scp docker-entrypoint.sh your-user@34.127.125.215:/path/to/backend/
scp wait-for-db.sh your-user@34.127.125.215:/path/to/backend/
scp Dockerfile your-user@34.127.125.215:/path/to/backend/

# On production server
chmod +x docker-entrypoint.sh wait-for-db.sh

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d
```

Now migrations run automatically every time you deploy! 🎉

---

## 📞 Need More Help?

- **Full Guide**: See `MIGRATION_GUIDE.md`
- **Docker Setup**: See `DOCKER_SETUP.md`
- **Quick Reference**: See `QUICK_REFERENCE.md`

---

**Time to fix**: ~5 minutes
**Difficulty**: Easy
**Risk**: Low (non-destructive operation)

**Go fix your production server now!** 🚀
