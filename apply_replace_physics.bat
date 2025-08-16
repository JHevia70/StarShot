@echo off
setlocal enabledelayedexpansion
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply_replace_physics.ps1" -FilePath "scenes/Shooter.gd"
if errorlevel 1 (
  echo.
  echo *** Hubo un error aplicando el parche. Revisa los mensajes de PowerShell. ***
  pause
  exit /b 1
)
echo.
echo Listo. Ejecuta el juego desde Godot.
pause
