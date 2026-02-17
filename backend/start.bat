@echo off
REM Fleet Management System - Docker Start Script (Windows)

echo ========================================
echo Fleet Management System - Docker Startup
echo ========================================
echo.

REM Check if Docker is running with retry logic
echo Checking Docker status...
set MAX_RETRIES=30
set RETRY_COUNT=0

:check_docker
docker info >nul 2>&1
if errorlevel 1 (
    set /a RETRY_COUNT+=1
    if %RETRY_COUNT% GEQ %MAX_RETRIES% (
        echo.
        echo [ERROR] Docker is not responding after 60 seconds!
        echo.
        echo Please ensure:
        echo   1. Docker Desktop is installed
        echo   2. Docker Desktop is running ^(check system tray^)
        echo   3. Docker engine has fully started ^(may take 1-2 minutes^)
        echo.
        echo Then try again: start.bat
        pause
        exit /b 1
    )
    
    if %RETRY_COUNT% EQU 1 (
        echo Docker is starting up... ^(this may take 1-2 minutes^)
    )
    
    echo Waiting for Docker... ^(%RETRY_COUNT%/%MAX_RETRIES%^)
    timeout /t 2 /nobreak >nul
    goto check_docker
)

echo [OK] Docker is ready!
echo.

REM Create necessary directories
echo Creating required directories...
if not exist uploads\logos mkdir uploads\logos
if not exist logs mkdir logs
echo [OK] Directories created
echo.

REM Stop existing containers
echo Stopping existing containers (if any)...
docker compose down >nul 2>&1
echo.

REM Start services
echo Building and starting services...
echo This may take a few minutes on first run...
echo.
docker compose up -d --build

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to start services!
    echo.
    echo Please check:
    echo   1. Docker Desktop has enough resources
    echo   2. No port conflicts (8000, 5432, 6379, 5000)
    echo   3. Run: docker compose logs
    echo.
    pause
    exit /b 1
)

echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo Service Status:
echo ==================
docker compose ps

echo.
echo ========================================
echo Fleet Management System Started!
echo ========================================
echo.
echo Service Endpoints:
echo   Backend API:  http://localhost:8000
echo   API Docs:     http://localhost:8000/docs
echo   Health:       http://localhost:8000/health
echo.
echo Branding Features:
echo   Endpoints:    /api/v1/branding
echo   Logos:        .\uploads\logos\
echo.
echo Useful Commands:
echo   View logs:    logs.bat
echo   Stop:         stop.bat
echo   Restart:      restart.bat
echo.
echo Migration Status:
docker compose exec backend alembic current 2>nul || echo   ^(Backend starting up...^)
echo.
echo [SUCCESS] Ready! Open http://localhost:8000/docs
echo.
pause
