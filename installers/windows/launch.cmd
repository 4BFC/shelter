@echo off
setlocal
set "SHELTER_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "SHELTER_PS=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%SHELTER_PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0shelter-lite-windows.ps1" %*
set "SHELTER_EXIT=%ERRORLEVEL%"
if "%~1"=="" pause
exit /b %SHELTER_EXIT%
