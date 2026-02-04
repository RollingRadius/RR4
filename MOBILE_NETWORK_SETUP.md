# Mobile Device Network Setup Guide

## Your Network Configuration
- **Computer IP**: 192.168.1.3
- **Network**: Wi-Fi (192.168.1.1 gateway)
- **Backend Port**: 8000
- **API URL**: http://192.168.1.3:8000

## Step-by-Step Setup

### 1. Configure Windows Firewall

Allow port 8000 through Windows Firewall:

```powershell
# Run PowerShell as Administrator and execute:
netsh advfirewall firewall add rule name="FastAPI Backend" dir=in action=allow protocol=TCP localport=8000
```

**OR manually:**
1. Open "Windows Defender Firewall with Advanced Security"
2. Click "Inbound Rules" → "New Rule"
3. Rule Type: Port
4. Protocol: TCP, Port: 8000
5. Action: Allow the connection
6. Profile: Check all (Domain, Private, Public)
7. Name: "FastAPI Backend"

### 2. Start Backend Server

**IMPORTANT**: Use `--host 0.0.0.0` to listen on all network interfaces:

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Verify backend is accessible:**
- From computer: http://localhost:8000/docs
- From computer: http://192.168.1.3:8000/docs
- From mobile: http://192.168.1.3:8000/docs

### 3. Connect Mobile Device

1. **Connect to same Wi-Fi network**: Make sure your mobile device is connected to the same Wi-Fi network as your computer (192.168.1.x network)

2. **Test connection**: Open browser on mobile and visit:
   - http://192.168.1.3:8000/docs
   - You should see the FastAPI Swagger documentation

3. **If connection fails**, check:
   - Mobile device is on same Wi-Fi (not mobile data)
   - Computer IP hasn't changed (run `ipconfig` to verify)
   - Windows Firewall rule is active
   - Backend is running with `--host 0.0.0.0`

### 4. Run Flutter App on Mobile

**Option A: USB Connected Device**
```bash
cd frontend
flutter run
```
- Select your physical device from the list
- App will use the configured IP (192.168.1.3)

**Option B: Wireless Debugging (Android 11+)**
```bash
# Enable wireless debugging on your phone first
# Then pair with adb
adb pair <IP>:<PORT>
adb connect <IP>:<PORT>
flutter run
```

### 5. Verify Connection

Once the app is running on your mobile:
1. Try to login or register
2. Check backend console for incoming requests:
   ```
   INFO: 192.168.1.x:xxxxx - "POST /api/auth/login HTTP/1.1" 200 OK
   ```
3. If you see requests from 192.168.1.x (your mobile IP), it's working!

## Troubleshooting

### Problem: "Connection refused" or "Network error"

**Solution 1: Check Computer IP**
Your computer's IP may have changed. Run:
```bash
ipconfig
```
Look for "IPv4 Address" under your Wi-Fi adapter. If it's different from 192.168.1.3, update `frontend/lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'http://YOUR_NEW_IP:8000';
```

**Solution 2: Check Backend is listening on 0.0.0.0**
```bash
netstat -an | findstr :8000
```
Should show:
```
TCP    0.0.0.0:8000    0.0.0.0:0    LISTENING
```
NOT:
```
TCP    127.0.0.1:8000  0.0.0.0:0    LISTENING  # ❌ Wrong - only localhost
```

**Solution 3: Temporarily disable Windows Firewall (testing only)**
```bash
# Test if firewall is blocking
# Turn off temporarily (not recommended for production)
```

### Problem: Backend works on computer but not on mobile

**Check:**
1. Mobile device is on **same Wi-Fi network** (check Wi-Fi name)
2. Mobile is not using **mobile data** (turn off cellular)
3. Test from mobile browser first: http://192.168.1.3:8000/docs
4. Router is not blocking device-to-device communication (some routers have "AP Isolation" enabled)

### Problem: Cannot run migration or backend fails to start

**Solution:**
```bash
cd backend
python -m alembic upgrade head
```

### Problem: App shows old API URL (localhost)

**Solution:**
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```
This forces a rebuild with the new configuration.

## Quick Start Checklist

- [ ] Backend running with `--host 0.0.0.0`
- [ ] Firewall rule added for port 8000
- [ ] Mobile connected to same Wi-Fi as computer
- [ ] Can access http://192.168.1.3:8000/docs from mobile browser
- [ ] Frontend config updated to http://192.168.1.3:8000
- [ ] Flutter app running on physical device via USB or wireless

## Production Note

**For production deployment**, you would:
- Use a proper domain name (e.g., https://api.yourdomain.com)
- Enable HTTPS with SSL certificates
- Use environment variables for API URLs
- Deploy backend to a cloud server (not localhost)

This setup is for **development/testing only** and should not be used in production.

---

**Updated**: 2026-02-02
**Computer IP**: 192.168.1.3
**Status**: Ready for mobile testing
