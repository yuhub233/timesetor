@echo off
chcp 65001 >nul 2>&1
title TimeSetor Web - Deploy

echo ========================================
echo   TimeSetor Web - 一键部署
echo ========================================
echo.

cd /d "%~dp0"

node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found
    echo Please install Node.js from https://nodejs.org/
    goto :end
)

npm --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm not found
    echo Please install Node.js from https://nodejs.org/
    goto :end
)

echo Checking Node.js version...
node --version
npm --version
echo.

if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        goto :end
    )
    echo Dependencies installed successfully.
    echo.
)

echo ========================================
echo   Starting development server...
echo ========================================
echo.
echo Web client will be available at:
echo   http://localhost:3000
echo.
echo The server proxies API requests to:
echo   http://localhost:5000
echo.
echo Make sure the backend server is running!
echo ========================================
echo.

call npm run dev

echo.
echo Development server stopped.

:end
echo.
echo Press any key to exit...
pause >nul