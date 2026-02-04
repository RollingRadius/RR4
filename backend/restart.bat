@echo off
REM Fleet Management System - Restart Services

echo.
echo ========================================
echo Restarting Fleet Management System
echo ========================================
echo.

docker-compose restart

echo.
echo [SUCCESS] Services restarted
echo.
echo Backend API: http://localhost:8000/docs
echo.
pause
