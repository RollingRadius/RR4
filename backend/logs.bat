@echo off
REM Fleet Management System - View Logs

echo.
echo ========================================
echo Fleet Management System - Live Logs
echo ========================================
echo.
echo Press Ctrl+C to stop viewing logs
echo.

docker-compose logs -f
