@echo off
set "EDEN_ENGINE=%~dp0..\tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_ENGINE%" set "EDEN_ENGINE=%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_ENGINE%" (
    echo Open scenes/eden/play_eden.tscn in Godot and add --boss-check to run arguments.
    pause
    exit /b 1
)
start "" "%EDEN_ENGINE%" --path "%~dp0." res://scenes/eden/play_eden.tscn -- --boss-check
exit /b 0
d