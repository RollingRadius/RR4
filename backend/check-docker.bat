@echo off
REM Docker Readiness Check Script (Windows)

echo ========================
echo Docker Readiness Check
echo ========================
echo.

REM Check if Docker command exists
where docker >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker command not found!
    echo Please install Docker Desktop
    pause
    exit /b 1
)

echo [OK] Docker command found
echo.

REM Check Docker daemon
echo Checking Docker daemon...
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker daemon is not running
    echo.
    echo Please:
    echo   1. Start Docker Desktop
    echo   2. Look for Docker icon in system tray
    echo   3. Wait for Docker to fully start ^(1-2 minutes^)
    echo   4. Run this script again to verify
    echo.
    pause
    exit /b 1
)

echo [OK] Docker daemon is running
echo.

REM Show Docker version
echo Docker version:
docker --version
echo.

REM Show Docker info
echo Docker info:
docker info | findstr /C:"Server Version" /C:"Operating System" /C:"Total Memory" /C:"CPUs"
echo.

REM Check Compose
docker compose version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Docker Compose not found
) else (
    echo [OK] Docker Compose available
    docker compose version
)
echo.

REM Check running containers
echo Running containers:
docker ps --filter "name=fleet" --format "table {{.Names}}\t{{.Status}}" 2>nul || echo    ^(none^)
echo.

echo ========================
echo [SUCCESS] Docker is ready!
echo ========================
echo.
echo You can now run: start.bat
echo.
pause
