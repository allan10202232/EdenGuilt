"""Publish only a complete pair of tested builds. Credentials stay in GH_TOKEN."""
import hashlib
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "builds/dist"
ASSETS = [DIST / "EdenGuilt-Windows-x86_64.zip", DIST / "EdenGuilt-macOS-universal.zip"]


def gh(*args, check=True):
    return subprocess.run(["gh", *args], check=check, text=True, stdout=subprocess.PIPE).stdout.strip()


def main():
    commit = os.environ["GITHUB_SHA"]
    tag = f"main-{os.environ['GITHUB_RUN_NUMBER']}-{commit[:7]}"
    for asset in ASSETS:
        if not asset.is_file() or asset.stat().st_size < 1024 * 1024:
            raise RuntimeError(f"Missing or empty desktop build: {asset.name}")
    checksums = DIST / "SHA256SUMS.txt"
    lines = []
    for asset in ASSETS:
        digest = hashlib.sha256()
        with asset.open("rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(block)
        lines.append(f"{digest.hexdigest()}  {asset.name}\n")
    checksums.write_text("".join(lines), encoding="utf-8")
    notes = DIST / "release-notes.md"
    notes.write_text(f"""Automated playable build from `main` commit `{commit}` using Godot {os.environ['GODOT_VERSION']}.

| Platform | Download |
|---|---|
| Windows x86_64 | `EdenGuilt-Windows-x86_64.zip` |
| macOS Intel + Apple Silicon | `EdenGuilt-macOS-universal.zip` |

Extract the ZIP first, then open `EdenGuilt.exe` or `EdenGuilt.app`. No Godot installation is required.
For a presentation, use the included **Demo Mode** launcher; Ctrl+1/2/3 jumps between chapters.

Both native builds passed asset import, startup/navigation/demo tests, and packaged opening/campaign smoke checks.
Windows is unsigned; macOS is ad-hoc signed, without Apple notarization. macOS may require approval in System Settings > Privacy & Security > Open Anyway.
`SHA256SUMS.txt` contains download checksums. `BUILDINFO.json` inside each ZIP records its exact source commit.
""", encoding="utf-8")
    exists = subprocess.run(["gh", "release", "view", tag], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if not exists:
        gh("release", "create", tag, "--target", commit, "--title", f"EdenGuilt · main build {os.environ['GITHUB_RUN_NUMBER']} ({commit[:7]})",
           "--notes-file", str(notes), "--draft", "--latest=false")
    gh("release", "upload", tag, *(str(file) for file in [*ASSETS, checksums]), "--clobber")
    # An older, slower run must not replace the newest main build as Latest.
    newest = gh("api", f"repos/{os.environ['GH_REPO']}/commits/main", "--jq", ".sha") == commit
    gh("release", "edit", tag, "--draft=false", f"--latest={'true' if newest else 'false'}", "--notes-file", str(notes))
    url = gh("release", "view", tag, "--json", "url", "--jq", ".url")
    print(f"Published: {url}")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as output:
            output.write(f"### Desktop release\n\n[Download Windows and macOS builds]({url})\n\nCommit: `{commit}`\n")


if __name__ == "__main__":
    main()
