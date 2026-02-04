@echo off
REM Fleet Management System - Access Backend Shell

echo.
echo ========================================
echo Opening Backend Container Shell
echo ========================================
echo.
echo Type 'exit' to leave the shell
echo.

docker-compose exec backend bash
