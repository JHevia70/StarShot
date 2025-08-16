@echo off
setlocal EnableExtensions
REM Nuke and replace project.godot with a clean, known-good config.
set "P=project.godot"
if exist "%P%" ren "%P%" "project.godot.BROKEN-%RANDOM%-%DATE:/=-%-%TIME::=-%.bak" >nul
(
echo ; Godot 4 project config
echo config_version=5
echo.
echo [application]
echo config/name="StarShot"
echo run/main_scene="res://scenes/MainMenu.tscn"
echo.
echo [autoload]
echo GameState="*res://autoload/GameState.gd"
echo.
echo [display]
echo window/handheld/orientation="portrait"
echo window/size/viewport_width=720
echo window/size/viewport_height=1280
echo window/size/window_width_override=720
echo window/size/window_height_override=1280
echo window/stretch/mode="canvas_items"
echo window/stretch/aspect="expand"
echo.
echo [rendering]
echo renderer/rendering_method="mobile"
) > "%P%"
echo [ok] project.godot regenerado.
