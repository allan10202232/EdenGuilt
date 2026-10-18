"""Standard-library-only native Godot build, verification and packaging."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "builds/godot"
LOGS = ROOT / "builds/logs"
DIST = ROOT / "builds/dist"
VERSION = os.environ.get("GODOT_VERSION", "4.7.2")
BASE_URL = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
ASSETS = {
    "windows": f"Godot_v{VERSION}-stable_win64.exe.zip",
    "macos": f"Godot_v{VERSION}-stable_macos.universal.zip",
}
NAMES = {
    "windows": "EdenGuilt-Windows-x86_64.zip",
    "macos": "EdenGuilt-macOS-universal.zip",
}


def digest(path, algorithm="sha512"):
    result = hashlib.new(algorithm)
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def download(name):
    """Verify each official archive before extraction, including cached downloads."""
    sums = urllib.request.urlopen(f"{BASE_URL}/SHA512-SUMS.txt", timeout=60).read().decode()
    checksums = {line.split()[-1].lstrip("*"): line.split()[0] for line in sums.splitlines() if line.strip()}
    expected = checksums[name]
    target = CACHE / name
    if not target.exists() or digest(target) != expected:
        print(f"Downloading {name}", flush=True)
        temporary = target.with_suffix(target.suffix + ".partial")
        with urllib.request.urlopen(f"{BASE_URL}/{name}", timeout=120) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output, 1024 * 1024)
        if digest(temporary) != expected:
            temporary.unlink()
            raise RuntimeError(f"SHA512 mismatch: {name}")
        temporary.replace(target)
    return target


def engine_path(target):
    if target == "windows":
        return CACHE / "editor" / f"Godot_v{VERSION}-stable_win64_console.exe"
    return CACHE / "editor/Godot.app/Contents/MacOS/Godot"


def build_environment():
    env = os.environ.copy()
    # Keep local Windows validation data in the ignored build directory.
    if sys.platform == "win32":
        env["APPDATA"] = str(CACHE / "user")
        env["LOCALAPPDATA"] = str(ROOT / "builds/local-user")
        env["TEMP"] = str(ROOT / "builds/temp")
        env["TMP"] = env["TEMP"]
        for key in ["APPDATA", "LOCALAPPDATA", "TEMP"]:
            Path(env[key]).mkdir(parents=True, exist_ok=True)
    return env


def template_directory():
    if sys.platform == "win32":
        base = Path(build_environment()["APPDATA"]) / "Godot"
    elif sys.platform == "darwin":
        base = Path.home() / "Library/Application Support/Godot"
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "godot"
    return base / "export_templates" / f"{VERSION}.stable"


def install(target, supplied_engine=None):
    CACHE.mkdir(parents=True, exist_ok=True)
    if supplied_engine is None and not engine_path(target).is_file():
        archive = download(ASSETS[target])
        with zipfile.ZipFile(archive) as source:
            source.extractall(CACHE / "editor")
            if target == "macos":
                for entry in source.infolist():
                    mode = (entry.external_attr >> 16) & 0o777
                    if mode and not entry.is_dir():
                        (CACHE / "editor" / entry.filename).chmod(mode)
        archive.unlink()
        if target == "macos":
            engine_path(target).chmod(0o755)
    templates = CACHE / "templates"
    required = ["windows_release_x86_64.exe", "macos.zip"]
    if not all((templates / name).is_file() for name in required):
        archive = download(f"Godot_v{VERSION}-stable_export_templates.tpz")
        templates.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as source:
            for name in required:
                with source.open(f"templates/{name}") as incoming, (templates / name).open("wb") as output:
                    shutil.copyfileobj(incoming, output)
        archive.unlink()  # Cache only the two required templates, not the 1.3 GB archive.
    destination = template_directory()
    destination.mkdir(parents=True, exist_ok=True)
    for name in required:
        shutil.copy2(templates / name, destination / name)
    print(f"Godot {VERSION}; export templates: {destination}")


def checked_run(command, name, summary=None, timeout=180, cwd=ROOT):
    """Godot can return zero on a parser error; check its output as well."""
    LOGS.mkdir(parents=True, exist_ok=True)
    print(f"Running {name}", flush=True)
    engine_log = LOGS / f"{name}-engine.log"
    command = list(command)
    insertion = command.index("--") if "--" in command else len(command)
    command[insertion:insertion] = ["--log-file", engine_log]
    result = subprocess.run([str(arg) for arg in command], cwd=cwd, env=build_environment(),
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, encoding="utf-8", errors="replace", timeout=timeout)
    (LOGS / f"{name}.log").write_text(result.stdout, encoding="utf-8")
    combined = result.stdout + (engine_log.read_text(encoding="utf-8", errors="replace") if engine_log.exists() else "")
    errors = re.findall(r"^.*(?:SCRIPT ERROR:|SHADER ERROR:|ERROR:).*$", combined, re.MULTILINE)
    if result.returncode or errors or (summary and not re.search(rf"{summary}: \d+ checks, 0 failures", combined)):
        print(result.stdout)
        raise RuntimeError(f"{name} failed (exit {result.returncode}); see builds/logs/{name}.log")
    print(f"Passed {name}")


def build(target, supplied_engine=None):
    editor = Path(supplied_engine).resolve() if supplied_engine else engine_path(target)
    version = subprocess.check_output([str(editor), "--version"], text=True).strip()
    if not version.startswith(f"{VERSION}.stable"):
        raise RuntimeError(f"Expected Godot {VERSION}.stable, got {version}")
    checked_run([editor, "--headless", "--path", ROOT, "--editor", "--import", "--quit"], "import", timeout=360)
    for scene, summary in [("startup", "STARTUP"), ("navigation_system", "NAVIGATION"), ("demo_shortcuts", "DEMO")]:
        checked_run([editor, "--headless", "--path", ROOT, "--audio-driver", "Dummy", "--fixed-fps", "60",
                     f"res://tests/{scene}_test.tscn"], scene, summary)
    output = ROOT / "builds" / target
    output.mkdir(parents=True, exist_ok=True)
    executable = output / ("EdenGuilt.exe" if target == "windows" else "EdenGuilt.app")
    preset = "Windows Desktop" if target == "windows" else "macOS"
    checked_run([editor, "--headless", "--path", ROOT, "--export-release", preset, executable], "export", timeout=360)
    if target == "macos":
        with (executable / "Contents/Info.plist").open("rb") as source:
            import plistlib
            binary_name = plistlib.load(source)["CFBundleExecutable"]
        game_binary = executable / "Contents/MacOS" / binary_name
        subprocess.run(["lipo", str(game_binary), "-verify_arch", "x86_64", "arm64"], check=True)
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(executable)], check=True)
    else:
        game_binary = executable
    checked_run([game_binary, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60", "--quit-after", "180"],
                "packaged-opening", cwd=output)
    checked_run([game_binary, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60",
                 "--", "--export-smoke-test"], "packaged-three-chapters", "STANDALONE EXPORT", cwd=output)
    checked_run([game_binary, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60",
                 "--", "--demo", "--export-smoke-test"], "packaged-demo", "STANDALONE EXPORT", cwd=output)
    metadata = {"commit": os.environ.get("GITHUB_SHA", subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()),
                "godot": version, "platform": target, "architecture": "x86_64" if target == "windows" else "universal (x86_64 + arm64)"}
    (output / "BUILDINFO.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    shutil.copy2(ROOT / "ci/PLAYER_README.txt", output / "README.txt")
    for license_name in ["GODOT-LICENSE.txt", "GODOT-THIRD-PARTY.txt"]:
        shutil.copy2(ROOT / "docs/distribution" / license_name, output / license_name)
    if target == "windows":
        (output / "Demo Mode.cmd").write_bytes(b'@echo off\r\ncd /d "%~dp0"\r\nstart "" "EdenGuilt.exe" -- --demo\r\n')
    else:
        launcher = output / "Demo Mode.command"
        launcher.write_text('#!/bin/sh\ncd "$(dirname "$0")" || exit 1\nexec ./EdenGuilt.app/Contents/MacOS/' + binary_name + ' -- --demo\n', encoding="utf-8")
        launcher.chmod(0o755)
    DIST.mkdir(parents=True, exist_ok=True)
    archive = DIST / NAMES[target]
    if target == "macos":
        # ditto preserves the signed app bundle and executable permission bits.
        subprocess.run(["ditto", "-c", "-k", "--sequesterRsrc", str(output), str(archive)], check=True)
    else:
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as destination:
            for file in sorted(output.rglob("*")):
                if file.is_file():
                    destination.write(file, file.relative_to(output))
    print(f"Ready: {archive} ({archive.stat().st_size:,} bytes)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["install", "build"])
    parser.add_argument("--target", required=True, choices=ASSETS)
    parser.add_argument("--engine", help="Use an existing matching local editor executable")
    arguments = parser.parse_args()
    if arguments.command == "install":
        install(arguments.target, arguments.engine)
    else:
        build(arguments.target, arguments.engine)
