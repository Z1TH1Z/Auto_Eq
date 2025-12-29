@echo off
title Auto EQ - Desktop App
color 0B

echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║           AUTO EQ - Desktop Application               ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

cd /d %~dp0

:: Check if built
if not exist "build\windows\x64\runner\Release\auto_eq_flutter.exe" (
    echo [!] Desktop app not built yet. Building now...
    echo.
    call build_desktop.bat
)

:: Install Python dependencies if needed
echo [1/3] Checking Python dependencies...
pip show flask >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Installing Python dependencies...
    pip install flask flask-cors numpy scipy librosa sounddevice -q
)

:: Start Backend Server
echo [2/3] Starting Audio Backend Server...
start "Auto EQ Backend" /min cmd /c "cd /d %~dp0backend && python audio_server.py"

:: Wait for backend
echo [3/3] Waiting for backend...
timeout /t 2 /nobreak >nul

:: Run Desktop App
echo.
echo  Starting Auto EQ Desktop...
echo.
start "" "build\windows\x64\runner\Release\auto_eq_flutter.exe"

echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║              AUTO EQ DESKTOP IS RUNNING!              ║
echo  ║                                                       ║
echo  ║  The app window should open shortly.                  ║
echo  ║  Backend running at: http://localhost:5000            ║
echo  ║                                                       ║
echo  ║  Press any key to stop the backend server...          ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

pause >nul

:: Cleanup - kill backend
taskkill /F /FI "WINDOWTITLE eq Auto EQ Backend*" >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>nul
)

echo.
echo  Auto EQ stopped.
