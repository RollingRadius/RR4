# Mobile Setup Checklist

## ✅ What I've Done

1. **Updated API Configuration**
   - Changed API URL from `localhost` to `192.168.1.3`
   - File: `frontend/lib/core/config/app_config.dart`

2. **Cleaned and Rebuilt Flutter App**
   - Removed old build cache
   - Fresh dependencies installed
   - Building release APK for your Samsung device

3. **Created Startup Script**
   - File: `start_backend_mobile.bat`
   - Double-click to start backend in mobile network mode

## 📋 Next Steps (After Build Completes)

### Step 1: Allow Firewall Access
Run this in **PowerShell as Administrator**:
```powershell
netsh advfirewall firewall add rule name="FastAPI Backend" dir=in action=allow protocol=TCP localport=8000
```

### Step 2: Start Backend
Double-click: **`start_backend_mobile.bat`**

Or manually:
```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Step 3: Connect Mobile to Same Wi-Fi
- Connect your Samsung device to the **same Wi-Fi network** as your computer
- Wi-Fi name should match on both devices
- Turn off mobile data on your phone

### Step 4: Test Backend Connection
Open browser on your mobile and visit:
**http://192.168.1.3:8000/docs**

✅ If you see FastAPI docs, backend is accessible!
❌ If connection fails, see troubleshooting below.

### Step 5: Launch App
The app should already be installed on your Samsung device.
Look for "Fleet Management System" app icon and launch it.

## 🧪 Testing

1. **Try Login/Register**
   - Use the app to login or create account
   - Watch backend console for incoming requests

2. **Backend Console Should Show**
   ```
   INFO: 192.168.1.x:xxxxx - "POST /api/auth/login HTTP/1.1" 200 OK
   ```
   The IP (192.168.1.x) should be your mobile's IP

3. **Test Add Driver**
   - Create a new driver with username and password
   - Verify no 422 errors

## 🔧 Troubleshooting

### Problem: Can't access http://192.168.1.3:8000 from mobile

**Check 1: Computer IP hasn't changed**
```bash
ipconfig
```
Look for IPv4 under Wi-Fi adapter. Should be 192.168.1.3

**Check 2: Backend is listening on network**
```bash
netstat -an | findstr :8000
```
Should show: `TCP    0.0.0.0:8000`
NOT: `TCP    127.0.0.1:8000` ❌

**Check 3: Windows Firewall**
- Open Windows Defender Firewall
- Check if "FastAPI Backend" rule exists in Inbound Rules
- If not, add it (see Step 1 above)

**Check 4: Mobile on same Wi-Fi**
- Go to Settings → Wi-Fi on your phone
- Verify Wi-Fi name matches your computer's Wi-Fi
- Turn off mobile data

### Problem: App shows "Network error" or "Connection refused"

**Solution 1: Verify API URL**
```bash
cd frontend
flutter run -d R5CRA1JVYWL --release
```
Rebuild app with correct configuration.

**Solution 2: Check backend is running**
- Backend console should show: "Application startup complete"
- Visit http://192.168.1.3:8000/docs on your computer first

### Problem: 422 Error creating driver

**Solution: Make sure you're using the NEW app**
- Uninstall old app from phone
- Install new app (currently building)
- New app has username/password fields

### Problem: Backend fails to start

**Solution: Run migration first**
```bash
cd backend
python -m alembic upgrade head
```

## 📱 Your Device Info

- **Device**: Samsung Galaxy SM G991B
- **Android**: 12 (API 31)
- **Computer IP**: 192.168.1.3
- **Backend Port**: 8000
- **API URL**: http://192.168.1.3:8000

## 🎯 Success Indicators

✅ Backend starts without errors
✅ Can access http://192.168.1.3:8000/docs from mobile browser
✅ App installs and launches on phone
✅ Can login/register in app
✅ Backend console shows requests from mobile IP
✅ Can create drivers without 422 errors

---

**Status**: Building app now...
**Estimated time**: 2-3 minutes
**Next**: Follow checklist after build completes
