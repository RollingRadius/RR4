@echo off
REM Fleet Management System - Docker Start Script (Windows)

echo ========================================
echo Fleet Management System - Docker Startup
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo [OK] Docker is installed and running
echo.

REM Create necessary directories
echo Creating required directories...
if not exist uploads\logos mkdir uploads\logos
if not exist logs mkdir logs
echo [OK] Directories created
echo.

REM Stop existing containers
echo Stopping existing containers...
docker compose down >nul 2>&1
echo.

REM Start services
echo Building and starting services...
docker compose up -d --build

echo.
timeout /t 5 /nobreak >nul

echo.
echo Service Status:
docker compose ps

echo.
echo ========================================
echo Fleet Management System Started!
echo ========================================
echo.
echo   Backend API:  http://localhost:8000
echo   API Docs:     http://localhost:8000/docs
echo   Logs:         logs.bat
echo   Stop:         stop.bat
echo.
echo [SUCCESS] Ready!
echo.
pause
