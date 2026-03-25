# Fleet Management System - Quick Start 🚀

**Complete Full-Stack Application**
- Backend: FastAPI + PostgreSQL
- Frontend: Flutter (Web, Android, iOS)

---

## 📦 What's Included

✅ **Authentication System**
- Email signup with verification
- Security questions authentication
- Password recovery
- Username recovery
- Account lockout protection

✅ **Company Management**
- Join existing companies
- Create new companies
- GSTIN/PAN validation
- Multi-tenant support

✅ **Modern UI**
- Professional dashboard
- Vehicle management interface
- Bottom navigation
- Search and filters
- Responsive design

✅ **Security Features**
- JWT authentication
- Bcrypt password hashing
- AES-256 encryption
- Rate limiting
- Audit logging

---

## 🎯 Quick Start (3 Steps)

### 1️⃣ First Time Setup

```batch
setup.bat
```

This will:
- Create Python virtual environment
- Install all dependencies
- Set up database migrations
- Install Flutter dependencies
- Create .env configuration file

**Important:** Edit the `.env` file with your database credentials!

### 2️⃣ Start the Application

```batch
start_all.bat
```

This opens two windows:
- **Backend Server** (Port 8000)
- **Frontend App** (Chrome browser)

### 3️⃣ Open the App

- Frontend: Opens automatically in Chrome
- Backend API Docs: http://localhost:8000/docs

---

## 📋 Prerequisites

Before running setup, install:

- **Python 3.11+** - https://www.python.org/downloads/
- **PostgreSQL** - https://www.postgresql.org/download/
- **Flutter SDK** - https://flutter.dev/docs/get-started/install

**Verify installations:**
```bash
python --version      # Should be 3.11+
psql --version       # Should be 12+
flutter --version    # Should be 3.0+
```

---

## 🗄️ Database Setup

**Create Database:**
```bash
psql -U postgres
CREATE DATABASE fleet_db;
\q
```

**Configure Connection:**
Edit `backend/.env`:
```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/fleet_db
```

---

## 🎮 Control Scripts

### Setup (Run Once)
```batch
setup.bat
```
Sets up everything for first time.

### Start Everything
```batch
start_all.bat
```
Starts both backend and frontend.

### Start Backend Only
```batch
start_backend.bat
```
Runs FastAPI server on port 8000.

### Start Frontend Only
```batch
start_frontend.bat
```
Runs Flutter app in Chrome.

---

## 🌐 Access Points

| Service | URL |
|---------|-----|
| **Frontend (App)** | Auto-opens in Chrome |
| **Backend API** | http://localhost:8000 |
| **API Documentation** | http://localhost:8000/docs |
| **Alternative Docs** | http://localhost:8000/redoc |

---

## ✅ Testing the Setup

### 1. Check Backend
Open http://localhost:8000/docs
- Should see Swagger API documentation
- Try "GET /api/auth/security-questions"
- Should return 10 questions

### 2. Check Frontend
Should auto-open in Chrome showing:
- Login screen
- Fleet Management branding
- Sign up option

### 3. Create Test Account
1. Click "Sign Up"
2. Choose "Security Questions" method
3. Fill form:
   - Username: `testuser`
   - Password: `Test1234!`
   - Full Name: `Test User`
   - Phone: `1234567890`
4. Answer 3 security questions
5. Skip company selection
6. Login with credentials

### 4. Explore the App
After login:
- ✅ See dashboard with stats
- ✅ Click "Vehicles" tab - see 5 mock vehicles
- ✅ Try search and filters
- ✅ Check profile menu
- ✅ Test logout

---

## 🐛 Troubleshooting

### "Module not found" (Backend)
```batch
cd backend
venv\Scripts\activate
pip install -r requirements.txt
```

### "Database connection failed"
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- Ensure fleet_db database exists

### "Port 8000 already in use"
```batch
netstat -ano | findstr :8000
taskkill /PID <process_id> /F
```

### "Flutter command not found"
- Install Flutter SDK
- Add Flutter to PATH
- Run `flutter doctor`

### "Cannot connect to backend" (Frontend)
- Ensure backend is running (Port 8000)
- Check `frontend/lib/core/config/app_config.dart`
- Verify `apiBaseUrl` is `http://localhost:8000`

**More help:** See `START_PROJECT.md` for detailed troubleshooting.

---

## 📚 Documentation

- **`START_PROJECT.md`** - Detailed startup guide
- **`PROJECT_STATUS.md`** - Complete feature status
- **`IMPLEMENTATION_COMPLETE.md`** - Phase 1-4 details
- **`FRONTEND_IMPROVEMENTS.md`** - UI/UX enhancements
- **`SETUP_GUIDE.md`** - Backend setup guide
- **`frontend/README.md`** - Flutter app guide

---

## 🏗️ Project Structure

```
E:\Projects\RR4\
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── core/           # Security & config
│   │   ├── models/         # Database models
│   │   ├── services/       # Business logic
│   │   └── schemas/        # Request/response models
│   ├── alembic/            # Database migrations
│   ├── venv/               # Virtual environment
│   └── requirements.txt    # Python dependencies
│
├── frontend/               # Flutter frontend
│   ├── lib/
│   │   ├── presentation/   # UI screens
│   │   ├── providers/      # State management
│   │   ├── data/          # Models & services
│   │   └── routes/        # Navigation
│   └── pubspec.yaml       # Flutter dependencies
│
├── setup.bat              # First-time setup
├── start_all.bat          # Start everything
├── start_backend.bat      # Start backend only
└── start_frontend.bat     # Start frontend only
```

---

## 🎨 Features Overview

### Authentication ✅
- Dual signup methods (Email/Security Questions)
- Email verification
- Password recovery (Email or Security Questions)
- Username recovery
- JWT tokens with 30-min expiry
- Account lockout after 3 failed attempts

### Company Management ✅
- Search existing companies
- Create new companies
- Join as Pending User
- GSTIN/PAN validation
- Multi-tenant isolation
- Role-based access (Owner, Pending, Independent)

### Dashboard ✅
- Welcome header with user info
- Statistics cards (Vehicles, Drivers, Trips, Alerts)
- Quick action buttons
- Recent activity feed
- Profile menu
- Bottom navigation

### Vehicle Management 🚧
- Vehicle list with search
- Filter by status
- Mock data (5 vehicles)
- Status badges
- Driver assignments
- *Coming soon: Add/Edit vehicles*

### Coming Soon 🔜
- Driver management
- Trip tracking
- GPS integration
- Reports & analytics
- Real-time notifications
- Mobile apps (Android/iOS)

---

## 🚀 Next Steps

1. **Run Setup:**
   ```batch
   setup.bat
   ```

2. **Start Application:**
   ```batch
   start_all.bat
   ```

3. **Create Account:**
   - Sign up with security questions
   - Skip company selection
   - Login and explore

4. **Explore Features:**
   - Dashboard statistics
   - Vehicle list
   - Search and filters
   - Profile menu

5. **Read Documentation:**
   - Check `FRONTEND_IMPROVEMENTS.md` for UI details
   - Check `PROJECT_STATUS.md` for complete status

---

## 💡 Development Mode

### Backend Development
```bash
cd backend
venv\Scripts\activate
uvicorn app.main:app --reload
```
Changes auto-reload on file save.

### Frontend Development
```bash
cd frontend
flutter run -d chrome
```
Hot reload: Press `r` in terminal

### Database Changes
```bash
cd backend
venv\Scripts\activate
alembic revision --autogenerate -m "description"
alembic upgrade head
```

---

## 🎯 Success Checklist

You're ready when:
- [ ] Backend starts without errors
- [ ] Frontend opens in Chrome
- [ ] Can see login screen
- [ ] Can create new account
- [ ] Can login successfully
- [ ] See dashboard with navigation
- [ ] Can navigate to Vehicles tab
- [ ] Can search and filter vehicles
- [ ] Can logout successfully

---

## 📞 Support

**Check logs:**
- Backend: Terminal shows all requests
- Frontend: Chrome DevTools (F12)
- Database: `psql -U postgres -d fleet_db`

**Common issues:** See `START_PROJECT.md`

---

## 📄 License

[Add your license here]

---

**Ready to start building?** 🎉

Run `setup.bat` → `start_all.bat` → Create account → Explore!
