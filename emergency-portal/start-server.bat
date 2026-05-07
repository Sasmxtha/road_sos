@echo off
:: ============================================================
::  RoadSOS Emergency Portal — Local Dev Server
::  Starts a simple HTTP server so ES modules work correctly
::  (file:// URLs block module imports in modern browsers)
:: ============================================================
echo.
echo  ==========================================
echo   RoadSOS Emergency Portal — Local Server
echo  ==========================================
echo.

:: Try Python 3 first
where python >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  Starting Python HTTP server on http://localhost:8080
    echo  Open your browser at: http://localhost:8080
    echo  Press Ctrl+C to stop.
    echo.
    python -m http.server 8080
    GOTO :EOF
)

:: Fallback: Python 2
where python2 >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  Starting Python 2 HTTP server on http://localhost:8080
    python2 -m SimpleHTTPServer 8080
    GOTO :EOF
)

:: Fallback: Node http-server
where npx >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  Starting Node http-server on http://localhost:8080
    npx -y http-server . -p 8080 -o
    GOTO :EOF
)

echo  ERROR: No suitable server found.
echo  Please install Python 3 or Node.js, then re-run this script.
echo  Or open http://localhost:8080 after manually starting a server.
pause
