@echo off
REM Fleet Management System - Database Reset Script for Windows

echo ========================================
echo DATABASE RESET - WARNING
echo ========================================
echo.
echo This will DELETE ALL DATA in the database!
echo.
set /p confirm="Type 'yes' to confirm: "

if /i "%confirm%" NEQ "yes" (
    echo.
    echo Reset cancelled.
    pause
    exit /b 0
)

echo.
echo Resetting database...
docker-compose exec -it backend python reset-db.py

echo.
pause
