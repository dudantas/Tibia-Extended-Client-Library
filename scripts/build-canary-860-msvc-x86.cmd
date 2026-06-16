@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-canary-860-msvc-x86.ps1" %*
exit /b %ERRORLEVEL%
