@echo off
echo ========================================
echo Fixing Flutter Dependencies
echo ========================================
echo.

cd /d E:\Projects\RR4\frontend

echo Step 1: Cleaning Flutter build cache...
flutter clean

echo.
echo Step 2: Removing old packages...
if exist "pubspec.lock" del pubspec.lock
if exist ".dart_tool" rmdir /s /q .dart_tool
if exist "build" rmdir /s /q build

echo.
echo Step 3: Getting fresh dependencies...
flutter pub get

echo.
echo ========================================
echo Dependencies Fixed!
echo ========================================
echo.
echo You can now run:
echo   flutter run -d chrome
echo.
pause
