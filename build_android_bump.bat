@echo off
setlocal EnableExtensions EnableDelayedExecution
set "EXPORT_FILE=export_presets.cfg"
if /I "%~1" NEQ "bump" (
  echo Uso: %~nx0 bump [patch^|minor^|major ^| set X.Y.Z]
  exit /b 0
)
set "BUMP_MODE=patch"
set "SET_VERSION="
if /I "%~2"=="minor" set "BUMP_MODE=minor"
if /I "%~2"=="major" set "BUMP_MODE=major"
if /I "%~2"=="set"   set "BUMP_MODE=set" & set "SET_VERSION=%~3"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$f='%EXPORT_FILE%'; $mode='%BUMP_MODE%'; $set='%SET_VERSION%';" ^
  "if(-not (Test-Path $f)){ Write-Error 'No export_presets.cfg'; exit 1 }" ^
  "$ls=Get-Content -LiteralPath $f;" ^
  "for($i=0;$i -lt $ls.Count;$i++){" ^
  "  $L=$ls[$i];" ^
  "  if($L -match '^\s*version/code\s*=\s*(\d+)\s*$'){ $ls[$i]='version/code='+([int]$Matches[1]+1); continue }" ^
  "  if($L -match '^\s*version/name\s*=\s*""([^""]+)""\s*$'){" ^
  "    $v=$Matches[1]; if($mode -eq 'set' -and $set){ $nv=$set } else {" ^
  "      $p=$v.Split('.'); while($p.Count -lt 3){ $p+='' }" ^
  "      $maj=[int]$p[0]; $min=[int]$p[1]; $pat=[int]$p[2];" ^
  "      switch($mode){ 'major'{$maj++;$min=0;$pat=0}; 'minor'{$min++;$pat=0}; default{$pat++} }" ^
  "      $nv=""{0}.{1}.{2}"" -f $maj,$min,$pat }" ^
  "    $ls[$i]='version/name=""'+$nv+'""'; continue }" ^
  "}" ^
  "Set-Content -LiteralPath $f -Value $ls -Encoding UTF8;" ^
  "Write-Host '[ok] Bump aplicado'"
