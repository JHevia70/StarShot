@echo off
setlocal enabledelayedexpansion

REM === Configuración ===
set "REMOTE=https://github.com/JHevia70/StarShot.git"
set "BRANCH=main"
set "MSG=%*"
if "%MSG%"=="" set "MSG=update: %DATE% %TIME%"

where git >nul 2>&1
if errorlevel 1 (
  echo [ERR] Git no esta instalado o no esta en PATH.
  echo Instala Git: https://git-scm.com/download/win
  exit /b 1
)

REM Inicializar repo si hace falta
if not exist .git (
  echo [i] Inicializando repositorio...
  git init
)

REM Asegurar rama principal
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURR=%%b"
if not defined CURR set "CURR="
if not "%CURR%"=="%BRANCH%" (
  git checkout -B %BRANCH%
)

REM Configurar remoto origin si falta
git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [i] Configurando origin a %REMOTE%
  git remote add origin %REMOTE%
)

REM Crear .gitignore basico si no existe
if not exist .gitignore (
  echo .godot/>>.gitignore
  echo .import/>>.gitignore
  echo .export/>>.gitignore
  echo mono/>>.gitignore
  echo .DS_Store>>.gitignore
  echo Thumbs.db>>.gitignore
  echo bin/>>.gitignore
  echo *.tmp>>.gitignore
  echo *.bak>>.gitignore
  echo *.old>>.gitignore
)

REM (Opcional) Configurar identidad local si no esta
git config user.name >nul 2>&1 || git config user.name "starshot-local"
git config user.email >nul 2>&1 || git config user.email "starshot-local@example.com"

REM Subir TODO siempre
git add -A
git commit -m "%MSG%" --allow-empty
git push -u origin %BRANCH%

echo [OK] Push completado.
exit /b 0
