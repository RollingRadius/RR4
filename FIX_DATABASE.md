# 🔧 Fix Database - Run Migrations

## ❌ Problem

**Error:** `relation "users" does not exist`

**Cause:** Database tables were never created. The backend is running but Alembic migrations didn't run during startup.

---

## ✅ Solution - Run These Commands on Your Server

### **Step 1: SSH to Your Server**

```bash
ssh root@fc3
```

### **Step 2: Navigate to Backend Directory**

```bash
cd /home/RR4/backend
```

### **Step 3: Check Services are Running**

```bash
docker-compose ps
```

You should see:
```
fleet_postgres - Up
fleet_redis    - Up
fleet_backend  - Up
```

### **Step 4: Run Database Migrations**

```bash
# Run Alembic migrations to create all tables
docker-compose exec backend alembic upgrade head
```

You should see output like:
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> xxxxx, initial migration
INFO  [alembic.runtime.migration] Running upgrade xxxxx -> yyyyy, add users table
...
```

### **Step 5: Initialize Database with Default Data (Optional)**

```bash
# Create default companies, capabilities, etc.
docker-compose exec backend python init-db.py
```

### **Step 6: Verify Database**

```bash
# Connect to PostgreSQL and check tables
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"
```

You should see tables like:
```
 users
 companies
 organizations
 drivers
 vehicles
 capabilities
 ...
```

### **Step 7: Test API**

```bash
# From your server
curl http://localhost:8000/

# Should return:
# {"message":"Fleet Management System API",...}
```

---

## 🎯 Quick One-Command Fix

Run this single command to do everything:

```bash
ssh root@fc3 'cd /home/RR4/backend && docker-compose exec backend alembic upgrade head && docker-compose exec backend python init-db.py && echo "✅ Database initialized!"'
```

---

## 🔍 Troubleshooting

### If migrations fail:

```bash
# Check backend logs
docker-compose logs backend | tail -100

# Restart backend
docker-compose restart backend

# Try migrations again
docker-compose exec backend alembic upgrade head
```

### If init-db.py fails:

```bash
# It might fail if data already exists - that's OK
# The important part is that migrations completed
```

### Check database connection:

```bash
# Test database connectivity
docker-compose exec backend python -c "from app.database import engine; engine.connect(); print('✅ DB Connected')"
```

---

## 📱 After Fixing Database

1. **Test from browser:**
   ```
   http://34.127.125.215:8000/docs
   ```

2. **Test signup endpoint:**
   ```bash
   curl -X POST http://34.127.125.215:8000/api/auth/signup \
     -H "Content-Type: application/json" \
     -d '{
       "username": "testuser",
       "email": "test@example.com",
       "password": "Test123!@#",
       "full_name": "Test User",
       "phone": "1234567890"
     }'
   ```

3. **Open your app and try signup/login**

---

## ✅ Expected Result

After running migrations:
- ✅ All database tables created
- ✅ Users can sign up
- ✅ Users can log in
- ✅ App works without errors

---

## 📊 What Happened

**Issue:** The docker-entrypoint.sh script tried to run migrations but failed silently.

**Why:** The entrypoint might have had permission issues or alembic wasn't in the PATH correctly.

**Fix:** Manually run migrations once, then they'll persist in the database volume.

---

## 🔄 Prevent This in Future

Update docker-entrypoint.sh to be more robust:

```bash
# Better error handling
if command -v alembic > /dev/null 2>&1; then
  echo "Running migrations..."
  alembic upgrade head || {
    echo "Migration failed, check logs"
    exit 1
  }
else
  echo "ERROR: Alembic not found!"
  exit 1
fi
```

---

## 📝 Summary

Run these commands on your server:

```bash
# 1. SSH to server
ssh root@fc3

# 2. Go to backend directory
cd /home/RR4/backend

# 3. Run migrations
docker-compose exec backend alembic upgrade head

# 4. Initialize data (optional)
docker-compose exec backend python init-db.py

# 5. Verify
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

# Done!
```

Then test your app again - it should work! 🚀
