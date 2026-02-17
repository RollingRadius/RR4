@echo off
REM Fleet Management Backend - Direct Start (No Docker)

echo ========================================
echo Fleet Management System - Starting
echo ========================================
echo.

REM Activate virtual environment
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    echo [OK] Virtual environment activated
) else (
    echo [WARNING] Virtual environment not found
    echo Run: python -m venv venv
    echo Then: venv\Scripts\activate.bat
    echo Then: pip install -r requirements.txt
    pause
    exit /b 1
)

echo.
echo Starting FastAPI server...
echo Backend API will be available at: http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo.

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
