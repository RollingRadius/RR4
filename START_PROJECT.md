# Fleet Management System - Quick Start Guide

**Last Updated:** 2026-01-21

---

## Prerequisites Check

Before starting, ensure you have:

- [ ] **Python 3.11+** installed (`python --version`)
- [ ] **PostgreSQL** installed and running
- [ ] **Flutter SDK** installed (`flutter --version`)
- [ ] **Git** (for version control)

---

## 🚀 Quick Start (First Time Setup)

### Step 1: Backend Setup

```bash
# 1. Navigate to backend directory
cd E:\Projects\RR4\backend

# 2. Create virtual environment
python -m venv venv

# 3. Activate virtual environment
venv\Scripts\activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Create .env file from example
copy .env.example .env

# 6. Edit .env file with your settings
notepad .env
```

**Required .env settings:**
```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/fleet_db
SECRET_KEY=your-secret-key-min-32-chars-change-in-production-here
ENCRYPTION_MASTER_KEY=your-encryption-master-key-min-32-chars-change-in-production

# Optional: Email settings (for production)
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Step 2: Database Setup

```bash
# 1. Create PostgreSQL database
psql -U postgres
CREATE DATABASE fleet_db;
\q

# 2. Run migrations (with venv activated)
cd E:\Projects\RR4\backend
venv\Scripts\activate
alembic upgrade head
```

### Step 3: Frontend Setup

```bash
# 1. Navigate to frontend directory
cd E:\Projects\RR4\frontend

# 2. Get dependencies
flutter pub get

# 3. Check Flutter setup
flutter doctor
```

---

## 🎯 Starting the Application

### Option 1: Manual Start (Recommended for Development)

**Terminal 1 - Backend:**
```bash
cd E:\Projects\RR4\backend
venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 - Frontend:**
```bash
cd E:\Projects\RR4\frontend
flutter run -d chrome
```

### Option 2: Using Start Scripts

I'll create these for you below.

---

## 📝 Start Scripts

### Backend Start Script
Save as `start_backend.bat`:
```batch
@echo off
echo Starting Fleet Management Backend...
cd /d E:\Projects\RR4\backend
call venv\Scripts\activate
echo.
echo Backend starting on http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo.
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause
```

### Frontend Start Script
Save as `start_frontend.bat`:
```batch
@echo off
echo Starting Fleet Management Frontend...
cd /d E:\Projects\RR4\frontend
echo.
echo Running Flutter Web App...
echo.
flutter run -d chrome
pause
```

### All-in-One Start Script
Save as `start_all.bat`:
```batch
@echo off
echo Starting Fleet Management System...
echo.
echo This will open two windows:
echo   1. Backend Server (FastAPI)
echo   2. Frontend App (Flutter)
echo.
pause

start "Backend Server" cmd /k "cd /d E:\Projects\RR4\backend && call venv\Scripts\activate && uvicorn app.main:app --reload"
timeout /t 3 /nobreak >nul

start "Frontend App" cmd /k "cd /d E:\Projects\RR4\frontend && flutter run -d chrome"

echo.
echo Both services are starting...
echo Backend: http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo Frontend: Will open in Chrome automatically
echo.
pause
```

---

## 🌐 Access Points

Once started, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend (Web)** | Auto-opens in Chrome | Main application UI |
| **Backend API** | http://localhost:8000 | REST API endpoints |
| **API Documentation** | http://localhost:8000/docs | Swagger UI |
| **Alternative API Docs** | http://localhost:8000/redoc | ReDoc UI |

---

## 🧪 Testing the Setup

### 1. Test Backend

Open http://localhost:8000/docs and try:

**Test Endpoint:**
```
GET /api/auth/security-questions
```

**Expected Response:**
```json
{
  "success": true,
  "questions": [
    {
      "question_id": "Q1",
      "question_text": "What is your mother's maiden name?",
      ...
    }
  ],
  "count": 10
}
```

### 2. Test Frontend

The app should auto-open in Chrome. You should see:
- Login screen
- "Fleet Management System" title
- Username and password fields
- "Sign Up" link

### 3. Create Test Account

**Via Frontend:**
1. Click "Sign Up"
2. Fill in the form:
   - Full Name: Test User
   - Username: testuser
   - Phone: 1234567890
   - Password: Test1234!
   - Select "Security Questions" method
3. Answer 3 security questions
4. Skip company selection
5. Login immediately

**Via API (Alternative):**
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "username": "testuser",
    "phone": "1234567890",
    "password": "Test1234!",
    "auth_method": "security_questions",
    "security_questions": [
      {"question_id": "Q1", "question_text": "...", "answer": "TestAnswer1"},
      {"question_id": "Q2", "question_text": "...", "answer": "TestAnswer2"},
      {"question_id": "Q3", "question_text": "...", "answer": "TestAnswer3"}
    ],
    "terms_accepted": true
  }'
```

---

## 🐛 Troubleshooting

### Backend Issues

**Issue: "Module not found" error**
```bash
# Make sure venv is activated
cd E:\Projects\RR4\backend
venv\Scripts\activate

# Reinstall dependencies
pip install -r requirements.txt
```

**Issue: "Database connection error"**
```bash
# Check PostgreSQL is running
psql -U postgres -c "SELECT version();"

# Check DATABASE_URL in .env
# Format: postgresql://username:password@localhost:5432/database_name

# Recreate database if needed
psql -U postgres
DROP DATABASE IF EXISTS fleet_db;
CREATE DATABASE fleet_db;
\q

# Run migrations
alembic upgrade head
```

**Issue: "Port 8000 already in use"**
```bash
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace PID)
taskkill /PID <process_id> /F

# Or use a different port
uvicorn app.main:app --reload --port 8001
```

### Frontend Issues

**Issue: "Target of URI doesn't exist"**
```bash
flutter clean
flutter pub get
```

**Issue: "Cannot connect to backend"**
- Ensure backend is running on port 8000
- Check `lib/core/config/app_config.dart`:
  ```dart
  static const String apiBaseUrl = 'http://localhost:8000';
  ```
- For Android emulator: Use `http://10.0.2.2:8000`

**Issue: "Chrome not found"**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d windows  # For Windows desktop
flutter run -d edge     # For Edge browser
```

**Issue: "Flutter version mismatch"**
```bash
flutter upgrade
flutter pub get
```

### Database Issues

**Issue: "Relation does not exist"**
```bash
# Check if migrations ran
cd E:\Projects\RR4\backend
venv\Scripts\activate
alembic current

# If no migrations, run them
alembic upgrade head

# If issues persist, reset database
psql -U postgres
DROP DATABASE fleet_db;
CREATE DATABASE fleet_db;
\q
alembic upgrade head
```

**Issue: "Password authentication failed"**
- Check PostgreSQL password in .env
- Update DATABASE_URL with correct credentials
- Test connection: `psql -U postgres -d fleet_db`

---

## 📊 Development Workflow

### Daily Startup

1. **Start Backend**
   ```bash
   cd E:\Projects\RR4\backend
   venv\Scripts\activate
   uvicorn app.main:app --reload
   ```

2. **Start Frontend** (in new terminal)
   ```bash
   cd E:\Projects\RR4\frontend
   flutter run -d chrome
   ```

3. **Open API Docs**
   - Browser: http://localhost:8000/docs

### Making Changes

**Backend Changes:**
- Edit Python files in `backend/app/`
- Server auto-reloads (--reload flag)
- No restart needed for most changes

**Frontend Changes:**
- Edit Dart files in `frontend/lib/`
- Hot reload: Press `r` in terminal
- Hot restart: Press `R` in terminal
- Full restart: Press `q` then re-run

**Database Changes:**
```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

### Testing Changes

**Backend:**
```bash
# Run tests (when implemented)
pytest

# Test specific endpoint
curl http://localhost:8000/api/auth/security-questions
```

**Frontend:**
```bash
# Run tests (when implemented)
flutter test

# Run with verbose logging
flutter run -d chrome --verbose
```

---

## 🔐 Production Deployment

### Environment Variables

**Backend (.env):**
```env
# Change these in production!
DEBUG=False
ENVIRONMENT=production
SECRET_KEY=<generate-strong-key-here>
ENCRYPTION_MASTER_KEY=<generate-strong-key-here>

# Use production database
DATABASE_URL=postgresql://user:password@prod-db-host:5432/fleet_db

# Configure email
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-production-email@gmail.com
SMTP_PASSWORD=your-app-password

# Update frontend URLs
FRONTEND_URL=https://your-domain.com
EMAIL_VERIFICATION_URL=https://your-domain.com/verify-email
PASSWORD_RESET_URL=https://your-domain.com/reset-password
```

**Generate Strong Keys:**
```bash
# Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Or online: https://www.grc.com/passwords.htm
```

### Backend Deployment

**Option 1: Docker**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Option 2: Railway/Render**
- Connect GitHub repository
- Set environment variables in dashboard
- Deploy automatically on git push

**Option 3: VPS (DigitalOcean, AWS)**
```bash
# Install dependencies
sudo apt update
sudo apt install python3-pip postgresql

# Clone repository
git clone <your-repo>
cd backend

# Setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run with production server
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### Frontend Deployment

**Web:**
```bash
cd E:\Projects\RR4\frontend

# Build for web
flutter build web --release

# Deploy 'build/web' folder to:
# - Firebase Hosting
# - Netlify
# - Vercel
# - GitHub Pages
```

**Mobile:**
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (requires Mac)
flutter build ios --release
```

---

## 📈 Monitoring

### Backend Health Check

```bash
# Check if backend is running
curl http://localhost:8000/

# Check specific endpoint
curl http://localhost:8000/api/auth/security-questions
```

### Frontend Health

- Open http://localhost:XXXX (port shown in terminal)
- Should see login screen
- Check browser console for errors (F12)

### Database Check

```bash
# Connect to database
psql -U postgres -d fleet_db

# Check tables
\dt

# Count users
SELECT COUNT(*) FROM users;

# Exit
\q
```

---

## 📚 Additional Resources

### Documentation
- **Project Status:** `PROJECT_STATUS.md`
- **Implementation Details:** `IMPLEMENTATION_COMPLETE.md`
- **Frontend Improvements:** `FRONTEND_IMPROVEMENTS.md`
- **Backend Setup:** `SETUP_GUIDE.md`
- **Signup Flow:** `SIGNUP.md`

### API Documentation
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

### Flutter Resources
- **Frontend README:** `frontend/README.md`
- **Flutter Docs:** https://flutter.dev/docs

---

## ✅ Quick Checklist

Before reporting issues, verify:

- [ ] PostgreSQL is running
- [ ] Database `fleet_db` exists
- [ ] Migrations have been run (`alembic upgrade head`)
- [ ] .env file exists with correct values
- [ ] Virtual environment is activated (backend)
- [ ] Dependencies are installed (both backend and frontend)
- [ ] Correct ports (8000 for backend)
- [ ] No firewall blocking ports
- [ ] Flutter is up to date (`flutter upgrade`)

---

## 🎉 Success Indicators

You're all set when you can:

1. ✅ Open http://localhost:8000/docs and see API documentation
2. ✅ Open the Flutter app and see the login screen
3. ✅ Create a new account via signup
4. ✅ Login successfully
5. ✅ See the dashboard with navigation
6. ✅ Navigate to Vehicles tab and see mock data
7. ✅ Use search and filters on vehicles screen
8. ✅ Logout successfully

---

## 🆘 Getting Help

**Check Logs:**

Backend:
- Terminal output shows all requests
- Error tracebacks are displayed

Frontend:
- Browser console (F12)
- Flutter terminal output

**Common Commands:**

```bash
# Backend
cd E:\Projects\RR4\backend
venv\Scripts\activate
uvicorn app.main:app --reload

# Frontend
cd E:\Projects\RR4\frontend
flutter run -d chrome

# Database
psql -U postgres -d fleet_db

# Reset everything
# Backend: Drop DB, recreate, run migrations
# Frontend: flutter clean && flutter pub get
```

---

**Ready to start? Run the scripts or follow the manual steps above!** 🚀
