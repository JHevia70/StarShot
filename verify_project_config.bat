@echo off
setlocal EnableExtensions
set "P=project.godot"
if not exist "%P%" (echo [x] No existe project.godot & exit /b 1)
echo ---- BEGIN project.godot ----
for /f "usebackq delims=" %%L in ("%P%") do echo(%%L
echo ----  END  project.godot ----
