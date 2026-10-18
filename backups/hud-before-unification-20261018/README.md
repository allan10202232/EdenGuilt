# HUD backup · before chapter unification

These are exact copies of the eight original files at commit `70aa8f0`, before
unifying the campaign status panel and changing mine acquisition / fall recovery.
Files keep their original repository-relative paths. `.gdignore` keeps archived
scripts out of Godot's class scan; the production game does not load this folder.

To inspect the former layouts, compare `scripts/ui/hud.gd`,
`scripts/parkour/parkour_hud.gd` and `scripts/mine_challenge/level.gd` here.
To restore a file, copy it to the same relative location in the project, keeping
the new implementation separately if it is still needed.
