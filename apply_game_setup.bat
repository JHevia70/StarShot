@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Parches para project.godot: Autoload GameState y Main Scene
set "PROJ=project.godot"
if not exist "%PROJ%" (
  echo [x] No encuentro project.godot en la carpeta actual.
  echo     Ejecuta este .bat en la RAIZ del proyecto Godot.
  exit /b 1
)

copy /Y "%PROJ%" "%PROJ%.bak" >nul
echo [>] Backup: project.godot.bak

rem Asegura [autoload] y entrada GameState
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%PROJ%';" ^
  "$txt=Get-Content -LiteralPath $p;" ^
  "$hasSection=$false; $hasLine=$false;" ^
  "for($i=0;$i -lt $txt.Count;$i++){" ^
  "  if($txt[$i] -match '^\[autoload\]\s*$'){ $hasSection=$true }" ^
  "  if($txt[$i] -match '^\s*GameState\s*='){ $hasLine=$true }" ^
  "}" ^
  "if(-not $hasSection){ $txt += ''; $txt += '[autoload]' }" ^
  "if(-not $hasLine){ $txt += 'GameState=""*res://autoload/GameState.gd""' }" ^
  "Set-Content -LiteralPath $p -Value $txt -Encoding UTF8"

rem Asegura [application] run/main_scene
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%PROJ%';" ^
  "$txt=Get-Content -LiteralPath $p;" ^
  "$hasApp=$false; $hasMain=$false;" ^
  "for($i=0;$i -lt $txt.Count;$i++){" ^
  "  if($txt[$i] -match '^\[application\]\s*$'){ $hasApp=$true }" ^
  "  if($txt[$i] -match '^\s*run/main_scene\s*='){ $txt[$i]='run/main_scene=""res://scenes/MainMenu.tscn""'; $hasMain=$true }" ^
  "}" ^
  "if(-not $hasApp){ $txt += ''; $txt += '[application]' }" ^
  "if(-not $hasMain){ $txt += 'run/main_scene=""res://scenes/MainMenu.tscn""' }" ^
  "Set-Content -LiteralPath $p -Value $txt -Encoding UTF8"

echo [ok] project.godot parcheado con Autoload y MainScene.
echo Listo. Abre el proyecto y pulsa F5 para probar.
