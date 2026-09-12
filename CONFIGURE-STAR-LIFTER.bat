@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CONFIGURE-STAR-LIFTER.ps1" -ProjectRoot "%~dp0"
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" (
  echo.
  echo [STAR LIFTER] Configuration failed with code %ERR%.
  pause
)
exit /b %ERR%
