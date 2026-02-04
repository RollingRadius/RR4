@echo off
echo ========================================
echo   Fleet Management Backend Server
echo   Mobile Network Mode
echo ========================================
echo.
echo Computer IP: 192.168.1.3
echo Backend Port: 8000
echo.
echo Mobile devices can connect to:
echo http://192.168.1.3:8000
echo.
echo ========================================
echo.

cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
