param(
    [string]$Godot,
    [string]$OutputDirectory,
    [string]$TemplateArchive
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectDirectory 'builds/EdenGuilt-Windows-x64' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $Godot) {
    $Godot = Join-Path (Split-Path -Parent $projectDirectory) 'tools/Godot/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Supply -Godot with the Godot 4.7.2 console executable.' }
if ((& $Godot --version) -notmatch '^4\.7\.2\.stable') { throw 'This preset is verified with Godot 4.7.2 stable.' }

$cache = Join-Path $projectDirectory 'tools/export-appdata'
$templateDirectory = Join-Path $cache 'Godot/export_templates/4.7.2.stable'
if (-not (Test-Path (Join-Path $templateDirectory 'windows_release_x86_64.exe'))) {
    if (-not $TemplateArchive) {
        $TemplateArchive = Join-Path (Split-Path -Parent $projectDirectory) 'tools/export-templates/Godot_v4.7.2-stable_export_templates.tpz'
    }
    if (-not (Test-Path -LiteralPath $TemplateArchive)) { throw 'Supply -TemplateArchive with the official Godot 4.7.2 export templates TPZ.' }
    if ((Get-FileHash -LiteralPath $TemplateArchive -Algorithm SHA256).Hash -ne 'F298490B8D44D934BE425A5A65A51BF15F422428B229A06A6E11D9FFEA248011') {
        throw 'The archive does not match the official Godot 4.7.2 template checksum.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Force -Path $templateDirectory | Out-Null
    $archive = [IO.Compression.ZipFile]::OpenRead($TemplateArchive)
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.Name -in @('windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'windows_release_x86_64_console.exe', 'windows_debug_x86_64_console.exe', 'icudt_godot.dat', 'version.txt')) {
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $templateDirectory $entry.Name), $true)
            }
        }
    } finally { $archive.Dispose() }
}

$logDirectory = Join-Path $projectDirectory 'test-output/export'
$temporaryDirectory = Join-Path $projectDirectory 'tools/export-temp'
New-Item -ItemType Directory -Force -Path $OutputDirectory, $logDirectory, $temporaryDirectory | Out-Null
$savedEnvironment = @{}
foreach ($key in @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')) { $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
$executable = Join-Path $OutputDirectory 'EdenGuilt.exe'
try {
    $env:APPDATA = $cache
    $env:LOCALAPPDATA = Join-Path $projectDirectory 'tools/export-localappdata'
    # Keep Godot's safe-save temporary project settings in a writable build folder.
    $env:TEMP = $temporaryDirectory
    $env:TMP = $temporaryDirectory
    $log = Join-Path $logDirectory 'export.log'
    $console = Join-Path $logDirectory 'export-console.log'
    & $Godot --headless --path $projectDirectory --export-release 'Windows Desktop' $executable --log-file $log *> $console
    if ($LASTEXITCODE -ne 0 -or (Get-Content -LiteralPath $console -Raw) -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
        throw "Export failed. See $console"
    }
} finally {
    foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], 'Process') }
}

Copy-Item -LiteralPath (Join-Path $projectDirectory 'docs/distribution/PLAY.txt') -Destination (Join-Path $OutputDirectory '开始试玩.txt')
foreach ($name in @('GODOT-LICENSE.txt', 'GODOT-THIRD-PARTY.txt')) {
    Copy-Item -LiteralPath (Join-Path $projectDirectory ('docs/distribution/' + $name)) -Destination (Join-Path $OutputDirectory $name)
}
$commit = (& git -C $projectDirectory rev-parse HEAD).Trim()
$sourceDirty = [bool](& git -C $projectDirectory status --porcelain)
$buildInfo = @{
    game = 'EdenGuilt'; platform = 'Windows x64'; engine = '4.7.2.stable'; source_commit = $commit; source_dirty = $sourceDirty
    built_at = [DateTimeOffset]::Now.ToString('o'); executable_sha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash
    embedded_resources = $true
}
$buildInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'build-info.json') -Encoding UTF8
Write-Output "Built: $executable"
Write-Output 'Run scripts/test-windows-export.ps1 against this EXE before sharing.'
