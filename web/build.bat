@echo off
chcp 65001 >nul 2>&1
title TimeSetor Web - Build

echo ========================================
echo   TimeSetor Web - 构建生产版本
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

echo Building production version...
call npm run build

if errorlevel 1 (
    echo.
    echo ========================================
    echo   Build failed!
    echo ========================================
    goto :end
)

echo.
echo ========================================
echo   Build completed successfully!
echo ========================================
echo.
echo Output directory: dist/
echo.
echo To serve the built files, you can:
    echo   1. Use any static file server
    echo   2. Run: npx serve dist
    echo   3. Deploy to any static hosting service
echo.

:end
echo.
echo Press any key to exit...
pause >nul