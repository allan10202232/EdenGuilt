# Windows standalone distribution

The **Windows Desktop** export preset creates a Windows x64 release executable with its resource pack embedded. Recipients need no Godot installation. The game continues to use its normal illustrated prologue and full three-chapter campaign.

## Rebuild

Use Godot **4.7.2 stable** and its matching official export templates. The build script verifies the template archive checksum before extracting Windows runtimes and ICU data into ignored, workspace-local build tooling. It does not change the user's Godot installation or preferences.

```powershell
./scripts/build-windows.ps1 -OutputDirectory 'D:/EdenGuilt/builds/EdenGuilt-Windows-x64'
./scripts/test-windows-export.ps1 -Executable 'D:/EdenGuilt/builds/EdenGuilt-Windows-x64/EdenGuilt.exe'
Compress-Archive -Path 'D:/EdenGuilt/builds/EdenGuilt-Windows-x64' -DestinationPath 'D:/EdenGuilt/builds/EdenGuilt-Windows-x64.zip' -Force
```

On a different machine, provide `-Godot <console-executable>` and `-TemplateArchive <official-TPZ>` to the build script. Leaving `-OutputDirectory` unset builds under the project's ignored `builds/` directory. Build logs are in `test-output/export/`.

## Packaging and validation

- Runtime sprites, opening artwork, all chapter backgrounds, audio, shaders and bilingual resources are included. Dynamically loaded resources require the **all resources** export mode.
- Development tests, historical backups, the previous prototype, demo recording helpers, design reference maps and build tools are excluded.
- The standalone verifier copies only the exact EXE into an isolated directory, isolates its user data, then exercises the prologue, actual chapter transitions, extraction, double jump, chapter scenery, boss resource initialization and both menu languages. GL rendering produces screenshots alongside its log. `-Headless` is available for environments without a graphics display.
- The production opening only installs this verifier when explicitly launched with `-- --export-smoke-test`. Ordinary double-click launch uses the unchanged campaign flow. Godot's release templates disable external scene/script overrides, so validation must exercise the embedded application instead.
- The ZIP contains the EXE, a short bilingual play guide, engine license notices and a build manifest with the source commit and executable SHA256. The manifest identifies the source base; packaging files may be uncommitted when a local build is made.
- Current prototype progress is session-only; language settings persist. This packaging work does not add cross-session saves.

The initial Windows release passed **27 checks with 0 failures** using the actual copied release executable and GL rendering. Its normal startup without verification flags also passed. Screenshots cover the prologue, scrapyard, mine, Eden garden / processing / heart, and English / Chinese menus. This is packaging and startup validation, not a new full-game balance or end-to-end playthrough audit.

Export references: [Godot Windows export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html), [export resources and templates](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html).
