@echo off
title Revert Windows Optimizations
setlocal EnableDelayedExpansion

:: -------------------------------------------------------------
:: Check for Administrator Privileges & Auto-Elevate if needed
:: -------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ============================================================
    echo Requesting Administrator privileges to restore settings...
    echo Please click "Yes" on the UAC prompt to continue.
    echo ============================================================
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: -------------------------------------------------------------
:: Set Working Directory to Script Folder
:: -------------------------------------------------------------
cd /d "%~dp0"

:: -------------------------------------------------------------
:: Launch Undo PowerShell Script
:: -------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0undo_optimizations.ps1"

echo.
echo ============================================================
echo Reversion complete. Press any key to close this window...
echo ============================================================
pause >nul
