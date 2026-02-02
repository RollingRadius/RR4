# Fix and setup virtual environment using Python 3.11
Write-Host "Removing old venv..." -ForegroundColor Yellow
Remove-Item -Recurse -Force venv -ErrorAction SilentlyContinue

Write-Host "Creating new venv with Python 3.14..." -ForegroundColor Yellow
python -m venv venv

if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Host "ERROR: Failed to create venv!" -ForegroundColor Red
    exit 1
}

Write-Host "Upgrading pip..." -ForegroundColor Yellow
.\venv\Scripts\python.exe -m pip install --upgrade pip

Write-Host "Installing requirements..." -ForegroundColor Yellow
.\venv\Scripts\python.exe -m pip install -r requirements.txt

Write-Host "`nVenv setup complete!" -ForegroundColor Green
Write-Host "`nTo start the backend, run:" -ForegroundColor Cyan
Write-Host ".\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000" -ForegroundColor Yellow
