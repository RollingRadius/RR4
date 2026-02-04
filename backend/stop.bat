@echo off
REM Fleet Management System - Stop All Services

echo.
echo ========================================
echo Stopping Fleet Management System
echo ========================================
echo.

docker-compose down

echo.
echo [SUCCESS] All services stopped
echo.
echo To remove volumes (DELETE ALL DATA), run:
echo docker-compose down -v
echo.
pause
