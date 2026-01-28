@echo off
echo ========================================
echo Checking Users in Database
echo ========================================
echo.

cd /d "%~dp0"
call venv\Scripts\activate.bat
python check_users.py

echo.
pause
