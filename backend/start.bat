@echo off
REM Fleet Management System - Windows Docker Startup Script
REM This script starts the entire Docker environment on Windows

echo.
echo ========================================
echo Fleet Management System - Docker Setup
echo ========================================
echo.

REM Check if Docker is installed
where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker is not installed or not in PATH
    echo.
    echo Please install Docker Desktop from:
    echo https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

REM Check if Docker Desktop is running
docker info >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Docker Desktop is not running. Starting Docker Desktop...
    echo Please wait while Docker Desktop starts (this may take 30-60 seconds)...
    echo.

    REM Try to start Docker Desktop
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    REM Wait for Docker to be ready
    set RETRY=0
    :DOCKER_WAIT
    timeout /t 5 /nobreak >nul
    docker info >nul 2>nul
    if %ERRORLEVEL% NEQ 0 (
        set /a RETRY+=1
        if %RETRY% LSS 24 (
            echo Waiting for Docker Desktop to start... (%RETRY%/24^)
            goto DOCKER_WAIT
        ) else (
            echo [ERROR] Docker Desktop failed to start after 2 minutes
            echo Please start Docker Desktop manually and run this script again
            pause
            exit /b 1
        )
    )
    echo [SUCCESS] Docker Desktop is now running!
    echo.
)

echo [INFO] Docker is running
docker --version
docker-compose --version
echo.

REM Check if docker-compose.yml exists
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found
    echo Please run this script from the backend directory
    pause
    exit /b 1
)

echo [INFO] Stopping any running containers...
docker-compose down >nul 2>nul

echo.
echo ========================================
echo Building Docker Images (Development)
echo ========================================
echo.
echo This may take a few minutes on first run...
echo.

docker-compose build
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Docker build failed
    echo Check the errors above
    pause
    exit /b 1
)

echo.
echo ========================================
echo Starting Services
echo ========================================
echo.

docker-compose up -d
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to start services
    echo Check the errors above
    pause
    exit /b 1
)

echo.
echo [INFO] Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo [INFO] Running database migrations...
docker-compose exec backend alembic upgrade head
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Database migrations failed or database not ready yet
    echo Services are running, but you may need to run migrations manually:
    echo docker-compose exec backend alembic upgrade head
    echo.
)

echo.
echo ========================================
echo Services Status
echo ========================================
echo.

docker-compose ps

echo.
echo ========================================
echo Application Started Successfully!
echo ========================================
echo.
echo Backend API:  http://localhost:8000
echo API Docs:     http://localhost:8000/docs
echo Health Check: http://localhost:8000/health
echo.
echo PostgreSQL:   localhost:5432
echo Redis:        localhost:6379
echo OSRM:         localhost:5000
echo.
echo ========================================
echo Useful Commands:
echo ========================================
echo.
echo View logs:        docker-compose logs -f
echo Stop services:    docker-compose down
echo Restart:          docker-compose restart
echo Database shell:   docker-compose exec postgres psql -U fleet_user -d fleet_db
echo Backend shell:    docker-compose exec backend bash
echo Reset database:   docker-compose exec -it backend python reset-db.py
echo.
echo ========================================
echo Quick Access:
echo ========================================
echo.
echo View logs now:    logs.bat
echo Stop all:         stop.bat
echo.

REM Wait a bit more for backend to be fully ready
echo [INFO] Waiting for backend to be fully ready...
timeout /t 5 /nobreak >nul

REM Test health endpoint
echo [INFO] Testing backend health...
curl -f http://localhost:8000/health >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Backend is healthy and responding!
) else (
    echo [WARNING] Backend health check failed
    echo Backend may still be starting up. Wait a moment and check:
    echo http://localhost:8000/health
)

echo.
echo Opening API documentation in browser...
start http://localhost:8000/docs

echo.
echo Services are running in the background.
echo Press any key to exit (services will continue running)
echo.
pause
