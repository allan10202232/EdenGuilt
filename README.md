# EdenGuilt
### The Cost of Paradise
*English README &ensp;|&ensp; Playable three-chapter prototype*

---

## Overview

EdenGuilt is a 2D narrative action platformer built with Godot and GDScript. In a world where ninety percent of the land is believed to be dead, Eden promises a place in its last green sanctuary. Searching for missing companions, the protagonist takes a Soul Extractor and discovers that every new power can leave the surrounding land less alive.

The game connects exploration and combat to resource extraction, carbon tracking, energy efficiency, and collective restoration. Its central question is simple: *What does progress cost, and who pays for it?*

---

## Start the game

**Requirements.** Use Godot **4.7.2**, matching the engine supplied with this workspace. The project uses GDScript and the GL Compatibility renderer; the .NET edition is not required. The included engine and launch scripts are for Windows.

**Important project location.** In the supplied workspace, the active three-chapter game is `.remote_review/project.godot`. The top-level `prototype/` directory contains an older prototype.

### Option 1: Open in the Godot editor
1. Start Godot 4.7.2 and choose **Import** in the Project Manager.
2. Select `D:/EdenGuilt/.remote_review/project.godot`, then import and edit the project. Adjust the drive or folder if moved.
3. Allow the first asset import to finish, then press **F5** to run the complete game.
4. Press **Enter** to advance each passage of the illustrated prologue. After its last passage, press **Enter** to enter the first chapter. Release the key between presses.

The main scene is `res://scenes/opening.tscn`. Use **F5** for the full game; **F6** runs only the scene currently open in the editor.

### Option 2: Launch with the bundled Windows engine
Open PowerShell and run the following commands. They use the engine and project already present in this workspace.

```powershell
Set-Location 'D:\EdenGuilt'
$engineFolder = '.\tools\Godot\Godot_v4.7.2-stable_win64.exe'
$edenEngine = Join-Path $engineFolder 'Godot_v4.7.2-stable_win64.exe'
& $edenEngine --path '.\.remote_review'
