@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJ=project.godot"
if not exist "%PROJ%" (
  echo [x] No encuentro project.godot en esta carpeta.
  exit /b 1
)

copy /Y "%PROJ%" "%PROJ%.bak" >nul
echo [>] Backup: project.godot.bak

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%PROJ%';" ^
  "$t=Get-Content -LiteralPath $p;" ^
  "$hasDisp=$false;" ^
  "for($i=0;$i -lt $t.Count;$i++){" ^
  "  if($t[$i] -match '^\[display\]\s*$'){ $hasDisp=$true }" ^
  "}" ^
  "if(-not $hasDisp){ $t += ''; $t += '[display]' }" ^
  "$kv=@{" ^
  "  'window/handheld/orientation'='1';" ^
  "  'window/size/viewport_width'='720';" ^
  "  'window/size/viewport_height'='1280';" ^
  "  'window/stretch/mode'='canvas_items';" ^
  "  'window/stretch/aspect'='expand'" ^
  "};" ^
  "foreach($k in $kv.Keys){" ^
  "  $set=$false;" ^
  "  for($i=0;$i -lt $t.Count;$i++){" ^
  "    if($t[$i] -match ('^\s*'+[regex]::Escape($k)+'\s*=')){" ^
  "      $t[$i]=($k+'='+('""{0}""' -f $kv[$k])); $set=$true; break" ^
  "    }" ^
  "  }" ^
  "  if(-not $set){ $t += ($k+'='+('""{0}""' -f $kv[$k])) }" ^
  "}" ^
  "Set-Content -LiteralPath $p -Value $t -Encoding UTF8"

echo [ok] Orientacion a portrait y stretch a pantalla completa aplicados.
