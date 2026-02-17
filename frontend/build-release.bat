@echo off
echo ========================================
echo Fleet Management - Build Release APK
echo ========================================
echo.

REM Check if we're in the correct directory
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Please run this script from the frontend directory.
    pause
    exit /b 1
)

echo [1/5] Cleaning previous build...
call flutter clean
if errorlevel 1 goto error

echo.
echo [2/5] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error

echo.
echo [3/5] Building Release APK...
echo This may take 5-10 minutes...
echo.

REM Ask user which build type
echo Choose build type:
echo 1. Universal APK (larger, works on all devices)
echo 2. Split APKs (smaller, specific to device architecture)
echo 3. App Bundle (for Google Play Store)
echo.
set /p choice="Enter your choice (1/2/3): "

if "%choice%"=="1" (
    echo Building Universal APK...
    call flutter build apk --release
) else if "%choice%"=="2" (
    echo Building Split APKs...
    call flutter build apk --release --split-per-abi
) else if "%choice%"=="3" (
    echo Building App Bundle...
    call flutter build appbundle --release
) else (
    echo Invalid choice! Building Universal APK by default...
    call flutter build apk --release
)

if errorlevel 1 goto error

echo.
echo [4/5] Build completed successfully!
echo.

REM Show where the APK is located
echo ========================================
echo BUILD OUTPUT:
echo ========================================
echo.

if "%choice%"=="1" (
    echo Universal APK:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo Size:
    dir build\app\outputs\flutter-apk\app-release.apk | find "app-release.apk"
) else if "%choice%"=="2" (
    echo Split APKs:
    dir build\app\outputs\flutter-apk\*.apk
) else if "%choice%"=="3" (
    echo App Bundle:
    echo %CD%\build\app\outputs\bundle\release\app-release.aab
    echo.
    echo Size:
    dir build\app\outputs\bundle\release\app-release.aab | find "app-release.aab"
) else (
    echo Universal APK:
    echo %CD%\build\app\outputs\flutter-apk\app-release.apk
)

echo.
echo ========================================
echo [5/5] Next Steps:
echo ========================================
echo.
echo 1. Connect your Android phone via USB
echo 2. Enable USB Debugging on your phone
echo 3. Run: adb install build\app\outputs\flutter-apk\app-release.apk
echo.
echo OR
echo.
echo Copy the APK to your phone and install manually:
echo - Enable "Install from Unknown Sources" in phone settings
echo - Open the APK file on your phone
echo - Tap Install
echo.
echo ========================================
echo API Configuration:
echo ========================================
echo Base URL: http://34.127.125.215:8000
echo.

echo.
echo Would you like to install the APK now? (Y/N)
set /p install="Enter choice: "

if /i "%install%"=="Y" (
    echo.
    echo Installing APK to connected device...
    adb devices
    echo.
    if "%choice%"=="1" (
        adb install build\app\outputs\flutter-apk\app-release.apk
    ) else if "%choice%"=="2" (
        echo Which APK to install?
        echo 1. arm64-v8a (most modern phones)
        echo 2. armeabi-v7a (older phones)
        echo 3. x86_64 (emulators)
        set /p apk_choice="Enter choice (1/2/3): "

        if "!apk_choice!"=="1" (
            adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
        ) else if "!apk_choice!"=="2" (
            adb install build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
        ) else if "!apk_choice!"=="3" (
            adb install build\app\outputs\flutter-apk\app-x86_64-release.apk
        )
    ) else (
        adb install build\app\outputs\flutter-apk\app-release.apk
    )

    if errorlevel 1 (
        echo.
        echo Installation failed! Make sure:
        echo 1. Phone is connected via USB
        echo 2. USB Debugging is enabled
        echo 3. You authorized the computer on your phone
    ) else (
        echo.
        echo ========================================
        echo Installation successful!
        echo ========================================
        echo.
        echo Open the "Fleet Management System" app on your phone.
    )
)

echo.
echo Build process complete!
pause
exit /b 0

:error
echo.
echo ========================================
echo BUILD FAILED!
echo ========================================
echo.
echo Common solutions:
echo 1. Free up disk space (need ~5GB free on C: drive)
echo 2. Run: flutter doctor
echo 3. Run: flutter clean
echo 4. Check internet connection
echo 5. Update Flutter: flutter upgrade
echo.
echo For detailed error, check the output above.
echo.
pause
exit /b 1
