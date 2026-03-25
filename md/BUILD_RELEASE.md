# Build Release APK - Fleet Management App

## 🎯 Quick Build Instructions

### Prerequisites
- **Minimum 5GB free disk space** on C: drive
- Flutter SDK installed
- Android SDK installed

### Step 1: Free Up Disk Space

Run these commands in PowerShell (as Administrator):

```powershell
# Clean Windows temp files
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean Flutter build cache
cd E:\Projects\RR4\frontend
flutter clean

# Clean Gradle cache
Remove-Item -Path "$env:USERPROFILE\.gradle\caches" -Recurse -Force -ErrorAction SilentlyContinue
```

### Step 2: Build Release APK

```bash
# Navigate to frontend directory
cd E:\Projects\RR4\frontend

# Get dependencies
flutter pub get

# Build release APK (choose one option)

# Option A: Universal APK (works on all devices, ~60MB)
flutter build apk --release

# Option B: Split APKs (smaller, device-specific, ~30MB each)
flutter build apk --release --split-per-abi

# Option C: App Bundle (for Google Play Store)
flutter build appbundle --release
```

### Step 3: Find Your APK

**Universal APK:**
```
E:\Projects\RR4\frontend\build\app\outputs\flutter-apk\app-release.apk
```

**Split APKs:**
```
E:\Projects\RR4\frontend\build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
E:\Projects\RR4\frontend\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
E:\Projects\RR4\frontend\build\app\outputs\flutter-apk\app-x86_64-release.apk
```

**App Bundle:**
```
E:\Projects\RR4\frontend\build\app\outputs\bundle\release\app-release.aab
```

### Step 4: Install on Physical Device

#### Method 1: Via USB
1. Connect your Android phone to computer via USB
2. Enable **Developer Options** on phone (Settings → About → Tap Build Number 7 times)
3. Enable **USB Debugging** (Settings → Developer Options → USB Debugging)
4. Run: `adb install app-release.apk`

#### Method 2: Manual Transfer
1. Copy `app-release.apk` to your phone (via USB, email, or cloud)
2. On phone: Settings → Security → Enable "Install Unknown Apps"
3. Open the APK file on your phone
4. Tap "Install"

#### Method 3: Over WiFi
```bash
# Connect to phone over WiFi
adb connect YOUR_PHONE_IP:5555

# Install APK
adb install app-release.apk
```

## 🔧 Troubleshooting

### Error: "No space left on device"
- Free up at least 5GB on C: drive
- Delete files from: `C:\Users\ACSS\AppData\Local\Temp`
- Empty Recycle Bin
- Uninstall unused programs

### Error: "SDK License not accepted"
```bash
flutter doctor --android-licenses
```
Accept all licenses by typing 'y'

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

## 📊 Build Sizes

- **Universal APK**: ~50-80 MB (works on all devices)
- **arm64-v8a APK**: ~30-40 MB (most modern phones)
- **armeabi-v7a APK**: ~25-35 MB (older phones)
- **x86_64 APK**: ~35-45 MB (emulators/rare devices)

## 🚀 Which APK to Install?

**For most modern phones (2018+):** Use `app-arm64-v8a-release.apk`

**For older phones:** Use `app-armeabi-v7a-release.apk`

**Not sure?** Use `app-release.apk` (universal, works on all)

## ✅ Verification

After installation:
1. Open the app
2. Check if it connects to: `http://34.127.125.215:8000`
3. Test login/signup functionality
4. Verify all features work

## 📝 API Configuration

The app is configured to use:
- **Base URL**: `http://34.127.125.215:8000`
- **API Version**: `/api`
- **Full URL**: `http://34.127.125.215:8000/api`

All API calls will go to your production server.

## 🔒 Before Release

### Update version in pubspec.yaml
```yaml
version: 1.0.0+1
```

### Sign the APK (for production)
1. Create keystore
2. Update `android/app/build.gradle`
3. Build signed APK

See: https://docs.flutter.dev/deployment/android#signing-the-app

## 📱 Test Checklist

- [ ] App installs successfully
- [ ] Connects to API server
- [ ] Login works
- [ ] Signup works
- [ ] GPS tracking works
- [ ] All features functional
- [ ] No crashes
- [ ] Good performance

## 🆘 Need Help?

If build fails:
1. Check disk space: `dir C:\ `
2. Check Flutter: `flutter doctor -v`
3. Check Android SDK: `flutter doctor --android-licenses`
4. Clean and retry: `flutter clean && flutter pub get && flutter build apk`
