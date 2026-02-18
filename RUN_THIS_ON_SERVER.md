# 🚀 FIX YOUR 500 ERROR - RUN THIS ON YOUR SERVER

## ❌ The Problem

Your phone app gets **500 Internal Server Error** because:
- ✅ Backend is running
- ✅ Phone can connect to backend
- ❌ **Database tables don't exist**

Error: `relation "users" does not exist`

---

## ✅ THE FIX - Copy & Paste These Commands

### **OPTION 1: Automated Fix Script** (Recommended)

```bash
# Step 1: Copy the fix script to your server
scp E:/Projects/RR4/backend/fix-database.sh root@fc3:/home/RR4/backend/

# Step 2: SSH to server
ssh root@fc3

# Step 3: Go to backend directory
cd /home/RR4/backend

# Step 4: Make script executable
chmod +x fix-database.sh

# Step 5: Run the fix script
./fix-database.sh
```

The script will:
1. ✅ Check Docker containers
2. ✅ Verify database connection
3. ✅ Run all migrations (create tables)
4. ✅ Verify tables were created
5. ✅ Initialize default data
6. ✅ Test API endpoints

---

### **OPTION 2: Manual Commands** (If script doesn't work)

```bash
# SSH to server
ssh root@fc3

# Go to backend
cd /home/RR4/backend

# Check containers are running
docker-compose ps

# Run migrations (THIS IS THE MOST IMPORTANT STEP)
docker-compose exec backend alembic upgrade head

# Initialize default data
docker-compose exec backend python init-db.py

# Verify tables exist
docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"

# Restart backend
docker-compose restart backend

# Done!
```

---

### **OPTION 3: One Single Command** (Quickest)

```bash
ssh root@fc3 'cd /home/RR4/backend && docker-compose exec backend alembic upgrade head && docker-compose exec backend python init-db.py && docker-compose restart backend && echo "✅ FIXED!"'
```

---

## 🔍 After Running the Fix

### **Test from browser:**

Open: http://34.127.125.215:8000/docs

Try the signup endpoint with these values:
- username: `testuser`
- email: `test@test.com`
- password: `Test123!`
- full_name: `Test User`
- phone: `1234567890`
- auth_method: `email` (IMPORTANT: must be "email" or "security_questions")
- terms_accepted: `true`

Click "Execute" - should get success response.

---

### **Test from your phone:**

1. Open **Fleet Management System** app
2. Click **Sign Up**
3. Fill in the form
4. Should work without 500 error!

---

## 📊 What Tables Will Be Created

After running migrations, you'll have these tables:

```
users
companies
organizations
organization_users
drivers
vehicles
capabilities
user_capabilities
organization_capabilities
custom_roles
role_templates
...and more
```

---

## 🐛 Troubleshooting

### If migrations fail:

```bash
# Check backend logs
docker-compose logs backend | tail -100

# Check if alembic is available
docker-compose exec backend which alembic

# Check if backend can connect to database
docker-compose exec backend python -c "from app.database import engine; engine.connect(); print('Connected')"
```

### If still getting 500 error after fix:

```bash
# Restart all services
docker-compose restart

# Check all containers are healthy
docker-compose ps

# View real-time logs
docker-compose logs -f backend
```

### If you get "alembic: command not found":

```bash
# Rebuild backend container
docker-compose build backend --no-cache
docker-compose up -d backend

# Try migrations again
docker-compose exec backend alembic upgrade head
```

---

## ✅ Verification Checklist

After running the fix, verify:

- [ ] Migrations completed without errors
- [ ] Tables exist in database
- [ ] API docs accessible: http://34.127.125.215:8000/docs
- [ ] Signup endpoint works (test in browser)
- [ ] Login endpoint works (test in browser)
- [ ] Phone app can signup/login

---

## 📝 Expected Output

When you run the migrations, you should see:

```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> 123abc, initial schema
INFO  [alembic.runtime.migration] Running upgrade 123abc -> 456def, add users table
INFO  [alembic.runtime.migration] Running upgrade 456def -> 789ghi, add companies
...
```

---

## 🎯 Why This Happened

The `docker-entrypoint.sh` script should have run migrations automatically, but it failed silently. Reasons:
1. Permission issues
2. Alembic not in PATH
3. Database wasn't ready when migrations tried to run

**Fix:** Run migrations manually once. After that, database persists in Docker volume.

---

## 🔄 To Prevent This in Future

Update `docker-entrypoint.sh` to add better error handling:

```bash
# Wait longer for database
sleep 15

# Try migrations with retry
for i in {1..3}; do
  if alembic upgrade head; then
    echo "✅ Migrations successful"
    break
  else
    echo "⚠️  Migration attempt $i failed, retrying..."
    sleep 5
  fi
done
```

---

## 📞 Need Help?

If you run the fix and still get errors:

1. **Share backend logs:**
   ```bash
   docker-compose logs backend | tail -200
   ```

2. **Share migration output:**
   ```bash
   docker-compose exec backend alembic current
   docker-compose exec backend alembic upgrade head
   ```

3. **Share database status:**
   ```bash
   docker-compose exec postgres psql -U fleet_user -d fleet_db -c "\dt"
   ```

---

## 🚀 QUICK START - Just Run This!

```bash
ssh root@fc3 'cd /home/RR4/backend && docker-compose exec backend alembic upgrade head && echo "✅ Database fixed! Test your app now!"'
```

---

**After running this, your app will work!** 🎉

Your phone is fine - it's the server database that needed initialization.
