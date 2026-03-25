# Troubleshooting: Network Error on Login

## Issues Fixed

### 1. UI Overflow Error ✅
**Problem:** Row widget overflowing by 277 pixels on login screen
**Solution:** Changed `Row` to `Wrap` widget in `_buildForgotLinks()` method to handle small screens

**File Modified:** `frontend/lib/presentation/screens/auth/login_screen.dart:426`

### 2. Network Connection Error ⚠️
**Problem:** "Network error. Please check your connection."

## Root Cause

The backend server is not running or not reachable at: `http://192.168.1.4:8000`

## Solutions

### Solution 1: Start the Backend Server

#### Step 1: Navigate to Backend Directory
```bash
cd E:\Projects\RR4\backend
```

#### Step 2: Activate Virtual Environment
```bash
# On Windows
venv\Scripts\activate

# On Linux/Mac
source venv/bin/activate
```

#### Step 3: Start FastAPI Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Or if using a different entry point:
```bash
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### Step 4: Verify Server is Running
Open browser and visit:
- API Docs: http://192.168.1.4:8000/docs
- Health Check: http://192.168.1.4:8000/api/health

### Solution 2: Update API URL (If Backend is on Different IP)

If your backend is running on a different IP address or localhost:

#### Option A: Use localhost (if running on same machine)
**File:** `frontend/lib/core/config/app_config.dart`

```dart
static const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
```

#### Option B: Use current IP address
Find your computer's IP address:

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
```

**Linux/Mac:**
```bash
ifconfig
# or
ip addr show
```

Then update `app_config.dart`:
```dart
static const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://YOUR_IP:8000');
```

### Solution 3: Check Firewall Settings

**Windows Firewall:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules"
4. Add new rule for port 8000
5. Allow connection

**Or temporarily disable firewall for testing:**
```bash
# Windows (Run as Administrator)
netsh advfirewall set allprofiles state off

# Re-enable after testing
netsh advfirewall set allprofiles state on
```

### Solution 4: Verify Database Connection

Make sure PostgreSQL is running:

```bash
# Check PostgreSQL service status
# Windows
sc query postgresql-x64-14

# Linux
sudo systemctl status postgresql
```

### Solution 5: Check Backend Environment Variables

**File:** `backend/.env`

Ensure these are set correctly:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/fleet_db
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fleet_db
DB_USER=your_username
DB_PASSWORD=your_password

HOST=0.0.0.0
PORT=8000
```

## Quick Test Checklist

Run these commands to diagnose the issue:

### 1. Check if backend port is listening
```bash
# Windows
netstat -ano | findstr :8000

# Linux/Mac
lsof -i :8000
```

### 2. Test backend directly with curl
```bash
curl http://192.168.1.4:8000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-29T..."
}
```

### 3. Test login endpoint
```bash
curl -X POST http://192.168.1.4:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"test\",\"password\":\"test123\"}"
```

### 4. Check Flutter API configuration
```bash
cd E:\Projects\RR4\frontend
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Common Errors and Fixes

### Error: "Connection refused"
- **Cause:** Backend is not running
- **Fix:** Start the backend server (see Solution 1)

### Error: "Connection timed out"
- **Cause:** Firewall blocking or wrong IP
- **Fix:** Check firewall (Solution 3) or update IP (Solution 2)

### Error: "404 Not Found"
- **Cause:** Incorrect API endpoint
- **Fix:** Verify API routes match between frontend and backend

### Error: "500 Internal Server Error"
- **Cause:** Backend error (database, configuration)
- **Fix:** Check backend logs, verify database connection

## Step-by-Step Startup Guide

### Complete Startup Sequence

1. **Start PostgreSQL Database**
   ```bash
   # Windows (if not auto-started)
   net start postgresql-x64-14

   # Linux
   sudo systemctl start postgresql
   ```

2. **Start Backend Server**
   ```bash
   cd E:\Projects\RR4\backend
   venv\Scripts\activate  # Windows
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Verify Backend is Running**
   - Open browser: http://192.168.1.4:8000/docs
   - Should see Swagger UI with API documentation

4. **Start Flutter App**
   ```bash
   cd E:\Projects\RR4\frontend
   flutter run
   ```

5. **Test Login**
   - Use test credentials or create account
   - Should connect successfully

## Backend Logs

If backend is running but still getting errors, check the backend console for error messages:

**Common backend errors:**
- Database connection failed
- Missing environment variables
- Port already in use
- CORS issues

**Enable debug logging:**
```python
# In backend/app/main.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Network Configuration for Mobile Testing

If testing on physical device or emulator:

### Android Emulator
Use `10.0.2.2` instead of `localhost`:
```dart
static const String apiBaseUrl = 'http://10.0.2.2:8000';
```

### Physical Device (Same WiFi)
1. Find computer's IP on local network
2. Update `app_config.dart` with that IP
3. Ensure firewall allows connections
4. Both device and computer must be on same WiFi network

### iOS Simulator
Use `localhost`:
```dart
static const String apiBaseUrl = 'http://localhost:8000';
```

## Summary

✅ **Fixed UI overflow** - Changed Row to Wrap in login screen
⚠️ **Network error** - Backend not running at http://192.168.1.4:8000

**Next Steps:**
1. Start backend server: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
2. Verify at: http://192.168.1.4:8000/docs
3. Restart Flutter app
4. Try login again

If backend is on different IP, update `frontend/lib/core/config/app_config.dart` line 6.
