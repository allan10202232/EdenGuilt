@echo off
set "EDEN_ENGINE=%~dp0..\tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_ENGINE%" set "EDEN_ENGINE=%~dp0tools\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%EDEN_ENGINE%" (
    echo Open scenes/parkour/play_crusher_section.tscn in Godot and press F6.
    pause
    exit /b 1
)
start "" "%EDEN_ENGINE%" --path "%~dp0." res://scenes/parkour/play_crusher_section.tscn
exit /b 0
