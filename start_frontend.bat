@echo off
echo ========================================
echo Fleet Management System - Frontend
echo ========================================
echo.

cd /d E:\Projects\RR4\frontend

echo Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Flutter not found!
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    echo.
    pause
    exit /b 1
)

echo.
echo Running Flutter pub get...
call flutter pub get

echo.
echo ========================================
echo Frontend App Starting...
echo ========================================
echo.
echo The app will open in Chrome automatically
echo.
echo Hot Reload: Press 'r' in this terminal
echo Hot Restart: Press 'R' in this terminal
echo Quit: Press 'q' in this terminal
echo.
echo ========================================
echo.

flutter run -d chrome


echo.
echo Frontend app stopped.
pause
