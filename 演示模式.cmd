@echo off
setlocal
set "EDEN_DEMO_ENGINE=%~dp0..\tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_DEMO_ENGINE%" set "EDEN_DEMO_ENGINE=%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_DEMO_ENGINE%" set "EDEN_DEMO_ENGINE=E:\Software\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_DEMO_ENGINE%" (
    echo Open scenes/demo/presentation.tscn in Godot and press F6.
    pause
    exit /b 1
)
start "" "%EDEN_DEMO_ENGINE%" --path "%~dp0." res://scenes/demo/presentation.tscn
exit /b 0
