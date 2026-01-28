@echo off
echo ========================================
echo Fleet Management System
echo Full Stack Application Launcher
echo ========================================
echo.
echo This will start:
echo   1. Backend Server (FastAPI) - Port 8000
echo   2. Frontend App (Flutter) - Chrome
echo.
echo Two windows will open...
echo.
pause

echo Starting Backend Server...
start "Fleet Management - Backend" cmd /k "cd /d E:\Projects\RR4\backend && call venv\Scripts\activate && echo. && echo Backend Server Running on http://localhost:8000 && echo API Docs: http://localhost:8000/docs && echo. && uvicorn app.main:app --reload"

echo Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo Starting Frontend App...
start "Fleet Management - Frontend" cmd /k "cd /d E:\Projects\RR4\frontend && echo. && echo Flutter App Starting... && echo. && flutter run -d chrome"

echo.
echo ========================================
echo Services Started!
echo ========================================
echo.
echo Backend:  http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo Frontend: Opening in Chrome...
echo.
echo Check the opened windows for logs.
echo Close the windows to stop the services.
echo.
echo ========================================

pause
