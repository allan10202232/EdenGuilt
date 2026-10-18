# EdenGuilt
### The Cost of Paradise
*English README &ensp;|&ensp; Playable three-chapter prototype*

**[Download Windows / macOS builds](https://github.com/allan10202232/EdenGuilt/releases/latest)** · [Build status](https://github.com/allan10202232/EdenGuilt/actions/workflows/release.yml)

Every push to `main` automatically builds and tests both desktop versions, then publishes a release. Extract the ZIP and open the game; Godot is not required. See [release and demo instructions](docs/releases.md).

---

## Overview

EdenGuilt is a 2D narrative action platformer built with Godot and GDScript. In a world where ninety percent of the land is believed to be dead, Eden promises a place in its last green sanctuary. Searching for missing companions, the protagonist takes a Soul Extractor and discovers that every new power can leave the surrounding land less alive.

The game connects exploration and combat to resource extraction, carbon tracking, energy efficiency, and collective restoration. Its central question is simple: *What does progress cost, and who pays for it?*

---

## Start the game

### Standalone Windows build (no Godot installation)

Extract the `EdenGuilt-Windows-x64.zip` package, then double-click **EdenGuilt.exe**. The game assets are embedded in the executable; the build runs offline on Windows 10 / 11 x64 with OpenGL 3.3 support. The illustrated prologue, all three chapters and current endings are included. Press **Enter** through the prologue. English / Chinese can be selected in Settings.

The workspace build is at `D:/EdenGuilt/builds/EdenGuilt-Windows-x64/`. Build instructions and verification are in [Windows distribution](docs/windows-distribution.md). The following options are for running or editing the source project.

**Requirements.** Use Godot **4.7.2**, matching the engine supplied with this workspace. The project uses GDScript and the GL Compatibility renderer; the .NET edition is not required. The included engine and launch scripts are for Windows.

**Important project location.** The active three-chapter game is the repository-root `project.godot`. The `prototype/` directory contains an older prototype.

### Option 1: Open in the Godot editor
1. Start Godot 4.7.2 and choose **Import** in the Project Manager.
2. Select `project.godot` in your EdenGuilt checkout, then import and edit the project.
3. Allow the first asset import to finish, then press **F5** to run the complete game.
4. Press **Enter** to advance each passage of the illustrated prologue. After its last passage, press **Enter** to enter the first chapter. Release the key between presses.

The main scene is `res://scenes/opening.tscn`. Use **F5** for the full game; **F6** runs only the scene currently open in the editor.

### Option 2: Launch with the bundled Windows engine
Open PowerShell and run the following commands. They use the engine and project already present in this workspace.

```powershell
Set-Location 'D:\EdenGuilt'
$engineFolder = '.\tools\Godot\Godot_v4.7.2-stable_win64.exe'
$edenEngine = Join-Path $engineFolder 'Godot_v4.7.2-stable_win64.exe'
& $edenEngine --path '.'
```
