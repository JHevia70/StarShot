@echo off
setlocal EnableExtensions
set "PROJ=project.godot"
if not exist "%PROJ%" (
  > "%PROJ%" echo ; Godot 4 project config
  >>"%PROJ%" echo config_version=5
  >>"%PROJ%" echo.
  >>"%PROJ%" echo [application]
  >>"%PROJ%" echo config/name="StarShot"
  >>"%PROJ%" echo run/main_scene="res://scenes/MainMenu.tscn"
  >>"%PROJ%" echo.
  >>"%PROJ%" echo [autoload]
  >>"%PROJ%" echo GameState="*res://autoload/GameState.gd"
  >>"%PROJ%" echo.
  >>"%PROJ%" echo [display]
  >>"%PROJ%" echo window/handheld/orientation="portrait"
  >>"%PROJ%" echo window/size/viewport_width=720
  >>"%PROJ%" echo window/size/viewport_height=1280
  >>"%PROJ%" echo window/stretch/mode="canvas_items"
  >>"%PROJ%" echo window/stretch/aspect="expand"
  >>"%PROJ%" echo.
  >>"%PROJ%" echo [rendering]
  >>"%PROJ%" echo renderer/rendering_method="mobile"
)
echo [ok] project.godot presente. Si Godot sigue sin verlo, usa "Importar".
