@echo off
echo ========================================
echo Fleet Management - Cleanup and Build
echo ========================================
echo.
echo This script will:
echo 1. Clean up temporary files
echo 2. Free up disk space
echo 3. Build release APK
echo.

pause

echo.
echo [Step 1/6] Checking disk space...
echo.
wmic logicaldisk get size,freespace,caption | findstr "C:"
echo.

echo [Step 2/6] Cleaning Flutter build cache...
call flutter clean
echo Done!
echo.

echo [Step 3/6] Cleaning Windows temp files...
echo (This may take a minute...)
del /f /s /q %TEMP%\* 2>nul
echo Done!
echo.

echo [Step 4/6] Cleaning Gradle cache...
rd /s /q "%USERPROFILE%\.gradle\caches" 2>nul
echo Done!
echo.

echo [Step 5/6] Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)
echo Done!
echo.

echo [Step 6/6] Building Release APK...
echo.
echo This will take 5-10 minutes. Please wait...
echo.

REM Build universal APK (works on all devices)
call flutter build apk --release

if errorlevel 1 (
    echo.
    echo ========================================
    echo BUILD FAILED!
    echo ========================================
    echo.
    echo Possible reasons:
    echo 1. Not enough disk space (need 5GB free)
    echo 2. Android SDK not configured
    echo 3. Network issues downloading dependencies
    echo.
    echo Run: flutter doctor
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo BUILD SUCCESSFUL!
echo ========================================
echo.
echo APK Location:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
echo.

REM Show file size
for %%I in (build\app\outputs\flutter-apk\app-release.apk) do echo Size: %%~zI bytes
echo.

echo ========================================
echo How to Install on Your Phone:
echo ========================================
echo.
echo METHOD 1 - USB:
echo   1. Connect phone via USB
echo   2. Run: adb install build\app\outputs\flutter-apk\app-release.apk
echo.
echo METHOD 2 - Manual:
echo   1. Copy APK to phone
echo   2. Enable "Install from Unknown Sources"
echo   3. Open APK and tap Install
echo.
echo ========================================
echo API Server: http://34.127.125.215:8000
echo ========================================
echo.

pause
