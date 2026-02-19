@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title TimeSetor Web - Deploy

echo ========================================
echo   TimeSetor Web - 一键部署
echo ========================================
echo.

cd /d "%~dp0"

where node >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found
    echo Please install Node.js from https://nodejs.org/
    goto :error
)

where npm >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm not found
    echo Please install Node.js from https://nodejs.org/
    goto :error
)

echo Checking Node.js version...
node --version
npm --version
echo.

if not exist "node_modules" (
    echo Installing dependencies...
    npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        goto :error
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

npm run dev
if errorlevel 1 (
    echo ERROR: Failed to start development server
    goto :error
)

echo.
echo Development server stopped.
goto :end

:error
echo.
echo ========================================
echo   An error occurred!
echo ========================================
echo.

:end
pause