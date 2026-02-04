@echo off
REM Fleet Management System - Windows Quick Start Script

echo ========================================
echo Fleet Management System - Docker Setup
echo ========================================
echo.

echo Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not running!
    echo Please install Docker Desktop for Windows
    echo https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo Docker is installed!
echo.

echo Starting services...
docker-compose up -d

echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

echo.
echo Running database migrations...
docker-compose exec backend alembic upgrade head

echo.
echo ========================================
echo Application Started Successfully!
echo ========================================
echo.
echo  API Documentation: http://localhost:8000/docs
echo  Backend API: http://localhost:8000
echo  PostgreSQL: localhost:5432
echo  Redis: localhost:6379
echo.
echo To view logs: docker-compose logs -f
echo To stop: docker-compose down
echo.
pause
