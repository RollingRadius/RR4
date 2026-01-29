# 🚀 Quick Start Guide

## Issues Fixed

✅ **Login Screen Overflow** - Fixed UI layout issue in login screen
📝 **Created Enhanced Help Screen** - Comprehensive help with all features from README.md

## ⚠️ Current Issue: Backend Not Running

The Flutter app cannot connect because the backend server is not running.

## 🔧 Solution: Start the Backend Server

### Method 1: Using Startup Script (Easiest)

1. Open Command Prompt or PowerShell
2. Navigate to backend folder:
   ```bash
   cd E:\Projects\RR4\backend
   ```
3. Run the startup script:
   ```bash
   start_server.bat
   ```
4. Wait for "Application startup complete" message
5. Verify at: http://192.168.1.4:8000/docs

### Method 2: Manual Start

```bash
# 1. Go to backend directory
cd E:\Projects\RR4\backend

# 2. Activate virtual environment
venv\Scripts\activate

# 3. Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## ✅ Verify Backend is Running

Open your browser and visit:
- **API Documentation:** http://192.168.1.4:8000/docs
- **Alternative Docs:** http://192.168.1.4:8000/redoc
- **Health Check:** http://192.168.1.4:8000/api/health (if endpoint exists)

You should see the Swagger UI with all API endpoints.

## 📱 Start the Flutter App

After backend is running:

```bash
# 1. Go to frontend directory
cd E:\Projects\RR4\frontend

# 2. Run Flutter app
flutter run
```

## 🔍 Troubleshooting

### Issue: "uvicorn: command not found"
**Solution:** Install dependencies first
```bash
cd E:\Projects\RR4\backend
pip install -r requirements.txt
```

### Issue: "Cannot connect to database"
**Solution:** Start PostgreSQL
```bash
# Check if PostgreSQL is running
sc query postgresql-x64-14

# Start if needed
net start postgresql-x64-14
```

### Issue: "Port 8000 already in use"
**Solution:** Kill existing process or use different port
```bash
# Find process using port 8000
netstat -ano | findstr :8000

# Kill process (replace PID with actual process ID)
taskkill /F /PID <PID>

# Or use different port
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

### Issue: Still getting network error after starting backend
**Solution:** Check IP address
```bash
# Get your IP address
ipconfig

# Update frontend/lib/core/config/app_config.dart if needed
# Change line 6 to your actual IP address
```

## 📚 Enhanced Help Screen

The new help screen includes:
- **5 Tabs:** Overview, Roles, Features, Permissions, FAQ
- **12 Roles:** Complete details with abilities
- **9 Feature Categories:** All system features
- **Permission Matrix:** Role comparison table
- **Custom Roles:** Template-based creation guide

Access via: Profile Menu → Help & Support

## 🎯 Quick Test After Starting Backend

1. Backend running: http://192.168.1.4:8000/docs ✓
2. Flutter app: `flutter run` ✓
3. Login screen loads without overflow ✓
4. Try login with test credentials ✓
5. Check help screen: Profile → Help & Support ✓

## 📖 Documentation

- **Enhanced Help Screen:** `docs/enhanced-help-screen.md`
- **Network Troubleshooting:** `docs/troubleshooting-network-error.md`
- **Pending Users Fix:** `docs/fix-pending-users-display.md`
- **Company Search:** `docs/company-search-from-organizations-table.md`

## 🆘 Need More Help?

Check the troubleshooting guide:
```
E:\Projects\RR4\docs\troubleshooting-network-error.md
```

Or see the main README:
```
E:\Projects\RR4\README.md
```

---

**Summary:**
1. ✅ Fixed login screen overflow
2. ✅ Created comprehensive help screen
3. ⚠️ Start backend server: `cd backend && start_server.bat`
4. 📱 Run Flutter app: `cd frontend && flutter run`
5. 🎉 Enjoy the enhanced app!
