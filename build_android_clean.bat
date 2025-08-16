@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "PRESET_DEBUG=Android Debug (APK)"
set "PRESET_RELEASE=Android Release (AAB)"
set "APK_PATH=export\android\debug\game-debug.apk"
set "AAB_PATH=export\android\release\game-release.aab"

if not defined GODOT_EXE (
  if exist "tools\godot\godot.exe" set "GODOT_EXE=%cd%\tools\godot\godot.exe"
)
if not defined GODOT_EXE (
  for /f "delims=" %%G in ('where godot 2^>nul') do ( set "GODOT_EXE=%%G" & goto gd_found )
)
:gd_found
if not defined GODOT_EXE (
  echo [x] No encuentro godot.exe.
  exit /b 1
)

if not defined ANDROID_SDK_ROOT (
  if exist "%LOCALAPPDATA%\Android\Sdk" set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
)
if not defined ANDROID_HOME set "ANDROID_HOME=%ANDROID_SDK_ROOT%"
set "ADB_EXE=%ANDROID_SDK_ROOT%\platform-tools\adb.exe"
if not exist "%ADB_EXE%" (
  for /f "delims=" %%A in ('where adb 2^>nul') do set "ADB_EXE=%%A"
)
if not exist "%ADB_EXE%" (
  echo [x] adb no encontrado.
  exit /b 1
)

if "%~1"=="" goto help
if /I "%~1"=="debug"   goto build_debug
if /I "%~1"=="install" goto install_apk
if /I "%~1"=="release" goto build_release
if /I "%~1"=="devices" goto devices
if /I "%~1"=="clean"   goto clean

:help
echo Uso:
echo   %~nx0 debug    ^| exporta APK e instala
echo   %~nx0 release  ^| exporta AAB
echo   %~nx0 install  ^| instala %APK_PATH%
exit /b 0

:ensure_dirs
if not exist "export\android\debug"  mkdir "export\android\debug"
if not exist "export\android\release" mkdir "export\android\release"
goto :eof

:build_debug
if not exist "export_presets.cfg" (
  echo [x] Falta export_presets.cfg
  exit /b 1
)
call :ensure_dirs
"%GODOT_EXE%" --headless --path "%cd%" --export-debug "%PRESET_DEBUG%" "%APK_PATH%"
if errorlevel 1 exit /b 1
call :install_apk
exit /b %ERRORLEVEL%

:install_apk
if not exist "%APK_PATH%" exit /b 1
"%ADB_EXE%" kill-server >nul 2>&1
"%ADB_EXE%" start-server >nul 2>&1
"%ADB_EXE%" devices
set "DEVICE_OK="
for /f "skip=1 tokens=2" %%S in ('"%ADB_EXE%" devices') do if "%%S"=="device" set "DEVICE_OK=1"
if not defined DEVICE_OK exit /b 1
"%ADB_EXE%" install -r "%APK_PATH%"
exit /b %ERRORLEVEL%

:build_release
if not exist "export_presets.cfg" exit /b 1
call :ensure_dirs
"%GODOT_EXE%" --headless --path "%cd%" --export-release "%PRESET_RELEASE%" "%AAB_PATH%"
exit /b %ERRORLEVEL%

:devices
"%ADB_EXE%" devices
exit /b 0

:clean
if exist "export" rmdir /S /Q "export"
exit /b 0
