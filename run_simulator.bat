@echo off
set SDK_BIN=C:\Users\naufa\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin
echo ========================================================
echo   Launching Garmin Forerunner 165 Simulator - SebatSense
echo ========================================================

echo [1/3] Building SebatSense.prg...
call "%SDK_BIN%\monkeyc.bat" -f monkey.jungle -d fr165 -o "%~dp0bin\SebatSense.prg" -y "c:\Kuliah\mySignature\developer_key"
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Checking Garmin Simulator window...
tasklist /fi "imagename eq simulator.exe" | find /i "simulator.exe" >nul
if %ERRORLEVEL% NEQ 0 (
    echo Starting Simulator...
    start "" "%SDK_BIN%\simulator.exe"
    timeout /t 4 /nobreak >nul
)

echo [3/3] Loading SebatSense.prg onto Forerunner 165...
start "" "%SDK_BIN%\monkeydo.bat" "%~dp0bin\SebatSense.prg" fr165
echo.
echo SebatSense is now running in simulator!
