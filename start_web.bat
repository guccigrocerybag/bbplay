@echo off
echo ========================================
echo BBplay Web Development Server
echo ========================================
echo.
echo Starting development server with CORS proxy...
echo.
echo Server will be available at: http://localhost:3000
echo Press Ctrl+C to stop the server
echo.

REM Check if web folder exists
if not exist "web\dev_server.js" (
    echo ERROR: web\dev_server.js not found!
    echo Please make sure you're in the correct directory.
    pause
    exit /b 1
)

REM Check if node_modules exist
if not exist "web\node_modules" (
    echo Installing dependencies...
    cd web
    call npm install
    cd ..
)

REM Start the server
echo Starting server...
cd web
node dev_server.js