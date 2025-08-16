@echo off
setlocal EnableExtensions
set "DEST=StarShot"
if not exist "%DEST%" mkdir "%DEST%"
for %%D in (autoload scenes shaders addons export docs tools) do (
  if exist "%%D" (
    if not exist "%DEST%\%%D" mkdir "%DEST%\%%D"
    robocopy "%%D" "%DEST%\%%D" /E /MOVE >nul
  )
)
for %%F in (project.godot export_presets.cfg build_android_clean.bat build_android_bump.bat apply_game_setup.bat apply_portrait_fullscreen.bat README*.txt) do (
  if exist "%%F" move /Y "%%F" "%DEST%\%%F" >nul
)
echo [ok] Reubicado. Abre StarShot\project.godot desde Godot.
