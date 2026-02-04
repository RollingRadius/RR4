@echo off
REM Fleet Management System - Access PostgreSQL Shell

echo.
echo ========================================
echo Opening PostgreSQL Shell
echo ========================================
echo.
echo Common commands:
echo   \dt           - List all tables
echo   \d users      - Describe users table
echo   \q            - Quit
echo.

docker-compose exec postgres psql -U fleet_user -d fleet_db
