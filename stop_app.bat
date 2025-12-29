@echo off
title Auto EQ - Stopping
color 0C

echo.
echo  Stopping Auto EQ...
echo.

:: Kill Python backend
taskkill /F /IM python.exe /FI "WINDOWTITLE eq Auto EQ Backend*" >nul 2>nul

:: Kill any Flask processes on port 5000
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>nul
)

echo  Auto EQ stopped.
echo.
pause
