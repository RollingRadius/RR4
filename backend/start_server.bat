@echo off
echo ========================================
echo Fleet Management System - Backend Server
echo ========================================
echo.

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate

echo.
echo Starting FastAPI server...
echo Server will be available at: http://192.168.1.4:8000
echo API Documentation: http://192.168.1.4:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
