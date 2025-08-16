@echo off
setlocal ENABLEDELAYEDEXPANSION

REM === Config ===
set "REMOTE=https://github.com/JHevia70/StarShot.git"
set "BRANCH=main"

where git >nul 2>&1
if errorlevel 1 (
  echo [ERR] Git no esta instalado o no esta en PATH.
  echo Instala Git: https://git-scm.com/download/win
  exit /b 1
)

REM Obtener timestamp ISO con minutos y segundos (requiere PowerShell)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "TS=%%i"
set "MSG=[auto] update %TS%"

REM Inicializar repo si hace falta
if not exist .git (
  echo [i] Inicializando repositorio...
  git init
)

REM Asegurar rama principal
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURR=%%b"
if not defined CURR set "CURR="
if /I not "%CURR%"=="%BRANCH%" (
  git checkout -B %BRANCH%
)

REM Configurar remoto origin si falta
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [i] Configurando origin a %REMOTE%
  git remote add origin "%REMOTE%"
)

REM .gitignore basico si no existe
if not exist .gitignore (
  (
    echo .godot/
    echo .import/
    echo .export/
    echo mono/
    echo .DS_Store
    echo Thumbs.db
    echo bin/
    echo *.tmp
    echo *.bak
    echo *.old
  )>>.gitignore
)

REM Identidad local por si falta
git config user.name >nul 2>&1 || git config user.name "starshot-local"
git config user.email >nul 2>&1 || git config user.email "starshot-local@example.com"

REM Subir TODO siempre
git add -A
git commit -m "%MSG%" --allow-empty

REM Push (primer push establece upstream)
git rev-parse --abbrev-ref --symbolic-full-name @{u} >nul 2>&1
if errorlevel 1 (
  git push -u origin %BRANCH%
) else (
  git push
)

echo [OK] Push completado: %MSG%
exit /b 0
