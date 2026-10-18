# Automatic Windows and macOS releases

Every push to `main` runs [Build and release desktop game](https://github.com/allan10202232/EdenGuilt/actions/workflows/release.yml). Both platform jobs must pass before a public [GitHub Release](https://github.com/allan10202232/EdenGuilt/releases) is published. No manual tag or additional repository secret is needed; the release job uses GitHub's built-in token with `contents: write`.

Downloads:

- **EdenGuilt-Windows-x86_64.zip**: extract and open `EdenGuilt.exe`.
- **EdenGuilt-macOS-universal.zip**: extract and open `EdenGuilt.app`; includes Intel and Apple Silicon architectures.
- **SHA256SUMS.txt**: checksums for both ZIP files. Each ZIP also contains `BUILDINFO.json` with its source commit.

Players do not need Godot. Both packages include a Demo Mode launcher with Ctrl+1/2/3 chapter shortcuts. Normal launches retain the illustrated opening and disable presentation shortcuts.

The Windows executable is unsigned. The macOS app uses Godot's built-in ad-hoc signature and is not Apple-notarized. macOS may require **System Settings → Privacy & Security → Open Anyway** on first launch. This follows [Godot's export instructions for projects without an Apple Developer ID](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html#if-you-do-not-have-an-apple-developer-id-certificate).

## Pipeline

1. Native `windows-latest` and `macos-latest` runners install Godot **4.7.2** and matching official export templates. Downloads are checked against the official SHA512 manifest; extracted tools/templates are cached.
2. Import assets and check parser errors. Run existing startup, room/elevator navigation and demo shortcut acceptance tests.
3. Export release builds with `export_presets.cfg`. All game resources are included so dynamically loaded art is retained; development backups, tests and tools are excluded.
4. Launch the **exported** executable headlessly with the real opening and campaign, checking for script/resource errors. macOS also verifies both CPU architectures and the ad-hoc signature.
5. Upload CI artifacts, then publish both ZIP files together under `main-<run number>-<short commit>`. A failed build produces no new public release; inspect the job logs under Actions. Old slower runs do not replace newer main builds as Latest. Rerunning a workflow reuses its release tag and replaces its assets.

You can also choose **Actions → Build and release desktop game → Run workflow → main**. Dispatches from other branches are deliberately skipped. Nothing merges a feature branch into main automatically.

## Local export

Open the **repository-root `project.godot`** in Godot 4.7.2, install matching export templates via **Editor → Manage Export Templates**, then choose **Project → Export → Windows Desktop / macOS → Export Project**.

To run the same validation and packaging on a native Windows or macOS machine with Python 3:

```text
python ci/desktop_release.py install --target windows
python ci/desktop_release.py build --target windows
```

Replace `windows` with `macos` on a Mac. Optional `--engine <absolute path>` uses an existing Godot 4.7.2 editor instead of downloading one. The installer downloads official templates (approximately 1.3 GB initially), retains only the required desktop files, and outputs packages under `builds/dist/`. Logs are under `builds/logs/`.

The automated startup checks use the headless renderer; they do not replace visual playtesting on Windows, Intel Macs and Apple Silicon Macs.
