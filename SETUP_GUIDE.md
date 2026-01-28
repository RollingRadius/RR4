# Fleet Management System - Complete Setup Guide

## 🚀 Quick Start (5 Minutes)

### Prerequisites Check
```bash
# Check Python version (need 3.10+)
python --version

# Check PostgreSQL (need 14+)
psql --version

# Check Flutter (for frontend later)
flutter --version
```

---

## 📦 Backend Setup

### Step 1: Install PostgreSQL

**Windows:**
```bash
# Download from: https://www.postgresql.org/download/windows/
# Or use chocolatey:
choco install postgresql

# Verify installation
psql --version
```

**Mac:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Linux:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### Step 2: Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE fleet_db;

# Create user (optional, for production)
CREATE USER fleet_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE fleet_db TO fleet_user;

# Exit
\q
```

### Step 3: Setup Backend Environment

```bash
# Navigate to backend directory
cd E:\Projects\RR4\backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

```bash
# Copy example env file
copy .env.example .env    # Windows
cp .env.example .env      # Mac/Linux

# Edit .env file with your settings
# IMPORTANT: Set these values!
```

**Critical .env Settings:**
```env
# Database (REQUIRED)
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/fleet_db

# Security Keys (REQUIRED - Generate new ones!)
SECRET_KEY=your-secret-key-min-32-chars-CHANGE-THIS-NOW
ENCRYPTION_MASTER_KEY=your-encryption-key-min-32-chars-CHANGE-THIS-TOO

# Email (Optional for testing, required for production)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@fleetapp.com
```

**Generate Secure Keys:**
```python
# Run this in Python to generate secure keys:
import secrets
print("SECRET_KEY:", secrets.token_urlsafe(32))
print("ENCRYPTION_MASTER_KEY:", secrets.token_urlsafe(32))
```

### Step 5: Run Database Migrations

```bash
# Run migrations to create all tables
alembic upgrade head

# Verify tables were created
psql -U postgres -d fleet_db -c "\dt"
```

**Expected Output:**
```
             List of relations
 Schema |          Name          | Type  |  Owner
--------+------------------------+-------+----------
 public | alembic_version        | table | postgres
 public | audit_logs             | table | postgres
 public | organizations          | table | postgres
 public | recovery_attempts      | table | postgres
 public | roles                  | table | postgres
 public | security_questions     | table | postgres
 public | user_organizations     | table | postgres
 public | user_security_answers  | table | postgres
 public | users                  | table | postgres
 public | verification_tokens    | table | postgres
(10 rows)
```

### Step 6: Start Backend Server

```bash
# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or use the main.py directly
python -m app.main
```

**Expected Output:**
```
INFO:     Will watch for changes in these directories: ['E:\\Projects\\RR4\\backend']
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using StatReload
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
Starting Fleet Management System v1.0.0
Environment: development
Debug mode: True
INFO:     Application startup complete.
```

### Step 7: Test Backend APIs

**Open Browser:**
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

**Run Test Script:**
```bash
# In a new terminal (keep server running)
cd E:\Projects\RR4\backend
python test_api.py
```

---

## 🧪 Testing the APIs

### Test 1: Health Check
```bash
curl http://localhost:8000/health
```

Expected Response:
```json
{
  "status": "healthy",
  "app_name": "Fleet Management System",
  "version": "1.0.0",
  "environment": "development"
}
```

### Test 2: Get Security Questions
```bash
curl http://localhost:8000/api/auth/security-questions
```

### Test 3: Signup with Email
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Doe",
    "username": "johndoe123",
    "email": "john@example.com",
    "phone": "+1234567890",
    "password": "SecurePass123!",
    "auth_method": "email",
    "terms_accepted": true
  }'
```

### Test 4: Signup with Security Questions
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Jane Smith",
    "username": "janesmith123",
    "phone": "+9876543210",
    "password": "SecurePass456!",
    "auth_method": "security_questions",
    "security_questions": [
      {"question_id": "Q1", "question_text": "What is your mother'\''s maiden name?", "answer": "Anderson"},
      {"question_id": "Q2", "question_text": "What was the name of your first pet?", "answer": "Rex"},
      {"question_id": "Q3", "question_text": "In what city were you born?", "answer": "Portland"}
    ],
    "terms_accepted": true
  }'
```

### Test 5: Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "janesmith123",
    "password": "SecurePass456!"
  }'
```

### Test 6: Company Search
```bash
curl "http://localhost:8000/api/companies/search?q=ABC&limit=3"
```

### Test 7: Validate Company Details
```bash
curl -X POST http://localhost:8000/api/companies/validate \
  -H "Content-Type: application/json" \
  -d '{
    "gstin": "29ABCDE1234F1Z5",
    "pan_number": "ABCDE1234F"
  }'
```

---

## 🗄️ Database Management

### View Database Contents

```bash
# Connect to database
psql -U postgres -d fleet_db

# List all tables
\dt

# View users
SELECT username, email, auth_method, status FROM users;

# View companies
SELECT company_name, city, state, gstin FROM organizations;

# View roles
SELECT role_name, role_key, is_system_role FROM roles;

# View security questions
SELECT question_key, question_text, category FROM security_questions;

# Exit
\q
```

### Reset Database (Clean Start)

```bash
# Drop and recreate database
psql -U postgres -c "DROP DATABASE IF EXISTS fleet_db;"
psql -U postgres -c "CREATE DATABASE fleet_db;"

# Run migrations again
alembic upgrade head
```

---

## 🐛 Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'app'"
**Solution:**
```bash
# Make sure you're in the backend directory
cd E:\Projects\RR4\backend

# Activate virtual environment
venv\Scripts\activate

# Reinstall dependencies
pip install -r requirements.txt
```

### Issue: "could not connect to server: Connection refused"
**Solution:**
```bash
# Check if PostgreSQL is running
# Windows:
sc query postgresql-x64-14

# Mac:
brew services list

# Linux:
sudo systemctl status postgresql

# Start PostgreSQL if not running
# Windows: Start from Services or:
pg_ctl -D "C:\Program Files\PostgreSQL\14\data" start

# Mac:
brew services start postgresql@14

# Linux:
sudo systemctl start postgresql
```

### Issue: "alembic.util.exc.CommandError: Can't locate revision identified by"
**Solution:**
```bash
# Delete alembic_version table
psql -U postgres -d fleet_db -c "DROP TABLE IF EXISTS alembic_version CASCADE;"

# Run migrations again
alembic upgrade head
```

### Issue: "SMTP authentication failed" (Email sending)
**Solution:**
- For Gmail, use an App Password (not your regular password)
- Go to: https://myaccount.google.com/apppasswords
- Generate app password and use it in .env
- Or set SMTP_USER and SMTP_PASSWORD to empty for testing (emails won't send)

### Issue: "SECRET_KEY or ENCRYPTION_MASTER_KEY too short"
**Solution:**
```python
# Generate new keys (Python):
import secrets
print("SECRET_KEY:", secrets.token_urlsafe(32))
print("ENCRYPTION_MASTER_KEY:", secrets.token_urlsafe(32))

# Add to .env file
```

---

## 📊 API Endpoints Summary

### Authentication Endpoints
- `POST /api/auth/signup` - User signup
- `POST /api/auth/login` - User login
- `POST /api/auth/verify-email` - Email verification
- `POST /api/auth/forgot-password` - Password recovery (TODO)
- `POST /api/auth/recover-username` - Username recovery (TODO)
- `GET /api/auth/security-questions` - List security questions

### Company Endpoints
- `GET /api/companies/search?q=ABC` - Search companies
- `POST /api/companies/validate` - Validate GSTIN/PAN
- `GET /api/companies/{id}` - Get company details

---

## 🔒 Security Checklist

Before deploying to production:

- [ ] Change SECRET_KEY to a secure random value (32+ characters)
- [ ] Change ENCRYPTION_MASTER_KEY to a secure random value (32+ characters)
- [ ] Set DEBUG=False in production
- [ ] Use strong database password
- [ ] Configure proper CORS origins (not *)
- [ ] Enable HTTPS/TLS
- [ ] Set up email service (SMTP credentials)
- [ ] Configure rate limiting
- [ ] Set up backup strategy
- [ ] Enable database connection pooling
- [ ] Set up monitoring and logging
- [ ] Review and update ALLOWED_ORIGINS

---

## 📝 Next Steps

1. ✅ Backend is running and tested
2. 🔄 Set up Flutter frontend (next phase)
3. 🎨 Build authentication UI
4. 🏢 Build company management UI
5. 🚀 Deploy to production

---

## 💡 Tips

**Development Workflow:**
```bash
# Terminal 1: Backend server
cd backend
venv\Scripts\activate
uvicorn app.main:app --reload

# Terminal 2: Database monitoring
psql -U postgres -d fleet_db

# Terminal 3: Testing
python test_api.py
```

**Check Logs:**
```bash
# View server logs
tail -f logs/app.log

# View database queries (if DEBUG=True)
# Logs will show in terminal
```

**API Documentation:**
- Interactive docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

---

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Check .env configuration
4. Review server logs
5. Test with curl or Postman
6. Check database connection

**Common Commands:**
```bash
# Check what's running on port 8000
netstat -ano | findstr :8000    # Windows
lsof -i :8000                   # Mac/Linux

# Kill process on port 8000
taskkill /PID <PID> /F          # Windows
kill -9 <PID>                   # Mac/Linux
```

---

## ✅ Success Indicators

You'll know everything is working when:

1. ✅ `http://localhost:8000/health` returns status "healthy"
2. ✅ `http://localhost:8000/docs` shows Swagger UI
3. ✅ `test_api.py` shows all tests passing
4. ✅ You can signup, login, and create companies
5. ✅ Database has data in users and organizations tables

**Congratulations! Your backend is ready! 🎉**
