@echo off
title Auto EQ - Launcher
color 0B

echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║           AUTO EQ - Intelligent Audio Equalizer       ║
echo  ║                     Starting...                       ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

:: Check Python
where python >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python not found! Please install Python 3.9+
    pause
    exit /b 1
)

:: Check Flutter
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter not found! Please install Flutter SDK
    pause
    exit /b 1
)

:: Install Python dependencies if needed
echo [1/4] Checking Python dependencies...
pip show flask >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Installing Python dependencies...
    pip install flask flask-cors numpy scipy librosa sounddevice -q
)

:: Start Backend Server
echo [2/4] Starting Audio Backend Server...
start "Auto EQ Backend" cmd /c "cd /d %~dp0backend && python audio_server.py"

:: Wait for backend to start
echo [3/4] Waiting for backend to initialize...
timeout /t 3 /nobreak >nul

:: Start Flutter App
echo [4/4] Launching Flutter UI...
cd /d %~dp0
start "Auto EQ Flutter" cmd /c "flutter run -d edge"

echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║                  AUTO EQ IS RUNNING!                  ║
echo  ║                                                       ║
echo  ║  Backend: http://localhost:5000                       ║
echo  ║  Frontend: Opening in Edge browser...                 ║
echo  ║                                                       ║
echo  ║  Close this window to stop the application.           ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

pause
