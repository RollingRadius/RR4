@echo off
echo ========================================
echo Fleet Management System
echo First-Time Setup
echo ========================================
echo.
echo This will set up:
echo   1. Python virtual environment
echo   2. Backend dependencies
echo   3. Database migrations
echo   4. Flutter dependencies
echo.
pause

echo.
echo ========================================
echo Step 1: Backend Setup
echo ========================================
echo.

cd /d E:\Projects\RR4\backend

echo Creating Python virtual environment...
if exist "venv" (
    echo Virtual environment already exists, skipping...
) else (
    py -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        echo Make sure Python 3.11+ is installed
        echo Try: py --version
        pause
        exit /b 1
    )
    echo Virtual environment created successfully!
)

echo.
echo Activating virtual environment...
call venv\Scripts\activate

echo.
echo Installing Python dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo Dependencies installed successfully!

echo.
echo Checking .env file...
if not exist ".env" (
    echo Creating .env from .env.example...
    copy .env.example .env
    echo.
    echo ========================================
    echo IMPORTANT: Edit .env file!
    echo ========================================
    echo Please update these values in .env:
    echo   - DATABASE_URL (PostgreSQL connection)
    echo   - SECRET_KEY (generate a random key)
    echo   - ENCRYPTION_MASTER_KEY (generate a random key)
    echo.
    echo Generate keys with:
    echo   python -c "import secrets; print(secrets.token_urlsafe(32))"
    echo.
    pause
    notepad .env
) else (
    echo .env file already exists
)

echo.
echo ========================================
echo Step 2: Database Setup
echo ========================================
echo.
echo Make sure PostgreSQL is running and fleet_db database exists!
echo.
echo To create database, run:
echo   psql -U postgres
echo   CREATE DATABASE fleet_db;
echo   \q
echo.
pause

echo Running database migrations...
alembic upgrade head
if errorlevel 1 (
    echo ERROR: Migration failed
    echo Make sure:
    echo   1. PostgreSQL is running
    echo   2. Database fleet_db exists
    echo   3. DATABASE_URL in .env is correct
    pause
    exit /b 1
)
echo Migrations completed successfully!

echo.
echo ========================================
echo Step 3: Frontend Setup
echo ========================================
echo.

cd /d E:\Projects\RR4\frontend

echo Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo.
echo Getting Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get Flutter dependencies
    pause
    exit /b 1
)
echo Flutter dependencies installed successfully!

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo   1. Make sure PostgreSQL is running
echo   2. Update .env file if needed
echo   3. Run: start_all.bat
echo.
echo Or start services separately:
echo   - Backend:  start_backend.bat
echo   - Frontend: start_frontend.bat
echo.
echo ========================================

pause
