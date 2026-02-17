@echo off
chcp 65001 >nul
title TimeSetor Server

echo ========================================
echo   TimeSetor Server - Starting...
echo ========================================
echo.

cd /d "%~dp0"

if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        echo Please make sure Python 3.8+ is installed and added to PATH
        pause
        exit /b 1
    )
    echo Virtual environment created successfully.
    echo.
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Checking dependencies...
pip install -r requirements.txt --quiet

if errorlevel 1 (
    echo WARNING: Some dependencies may not have installed correctly
    echo Trying to continue anyway...
)

echo.
echo ========================================
echo   Starting TimeSetor Server...
echo ========================================
echo.
echo Server will be available at:
echo   - Local: http://localhost:5000
echo   - Network: http://YOUR_IP:5000
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python main.py

pause