@echo off
setlocal
cd /d "%~dp0"

if not exist "SunriseNRB\SunriseNRB-Launcher.exe" (
  echo [Sunrise NRB] Missing SunriseNRB\SunriseNRB-Launcher.exe
  pause
  exit /b 1
)

"SunriseNRB\SunriseNRB-Launcher.exe"
set ERR=%ERRORLEVEL%

if not "%ERR%"=="0" (
  echo.
  echo [Sunrise NRB] Launcher exited with code %ERR%.
  echo See SunriseNRB-launcher-v7.log in this folder.
  pause
)

exit /b %ERR%
