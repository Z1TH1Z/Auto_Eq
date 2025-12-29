@echo off
title Auto EQ - Building Desktop App
color 0B

echo.
echo  ╔═══════════════════════════════════════════════════════╗
echo  ║        AUTO EQ - Building Windows Desktop App         ║
echo  ╚═══════════════════════════════════════════════════════╝
echo.

cd /d %~dp0

echo [1/3] Checking Flutter Windows support...
flutter config --enable-windows-desktop

echo.
echo [2/3] Getting dependencies...
flutter pub get

echo.
echo [3/3] Building Windows release...
flutter build windows --release

echo.
if exist "build\windows\x64\runner\Release\auto_eq_flutter.exe" (
    echo  ╔═══════════════════════════════════════════════════════╗
    echo  ║                   BUILD SUCCESSFUL!                   ║
    echo  ║                                                       ║
    echo  ║  Output: build\windows\x64\runner\Release\            ║
    echo  ╚═══════════════════════════════════════════════════════╝
    
    :: Create distribution folder
    if not exist "dist" mkdir dist
    xcopy /E /Y "build\windows\x64\runner\Release\*" "dist\AutoEQ\" >nul
    xcopy /Y "backend\audio_server.py" "dist\AutoEQ\backend\" >nul
    xcopy /Y "backend\requirements.txt" "dist\AutoEQ\backend\" >nul
    
    echo.
    echo  Distribution folder created: dist\AutoEQ\
) else (
    echo  ╔═══════════════════════════════════════════════════════╗
    echo  ║                    BUILD FAILED!                      ║
    echo  ║                                                       ║
    echo  ║  Make sure Visual Studio C++ tools are installed.     ║
    echo  ║  Run: flutter doctor                                  ║
    echo  ╚═══════════════════════════════════════════════════════╝
)

echo.
pause
