@echo off
echo ========================================
echo Fleet Management System - Backend
echo ========================================
echo.

cd /d E:\Projects\RR4\backend

echo Checking virtual environment...
if not exist "venv" (
    echo Virtual environment not found!
    echo Please run setup first:
    echo   python -m venv venv
    echo   venv\Scripts\activate
    echo   pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate

echo.
echo ========================================
echo Backend Server Starting...
echo ========================================
echo.
echo Backend API: http://localhost:8000
echo API Docs:    http://localhost:8000/docs
echo ReDoc:       http://localhost:8000/redoc
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

echo.
echo Backend server stopped.
pause
