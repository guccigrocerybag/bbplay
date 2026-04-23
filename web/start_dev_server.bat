@echo off
echo ========================================
echo BBplay Development Server with CORS Proxy
echo ========================================
echo.
echo This server will:
echo 1. Serve the Flutter web app at http://localhost:3000
echo 2. Proxy API requests to https://vibe.blackbearsplay.ru
echo 3. Solve CORS issues for local development
echo.
echo Press Ctrl+C to stop the server
echo.

cd /d "%~dp0"
node dev_server.js