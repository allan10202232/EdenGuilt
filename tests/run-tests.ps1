param(
    [Parameter(Mandatory = $true)]
    [string]$Godot,
    [switch]$Screenshots
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectDirectory 'test-output'
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
Set-Content -LiteralPath (Join-Path $outputDirectory '.gdignore') -Value ''
$godotExecutable = (Get-Command $Godot -ErrorAction Stop).Source
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$testExitCode = 0

function Invoke-GodotCheck {
    param([string[]]$EngineArguments, [string]$LogPath, [bool]$RequireSummary = $false)
    & $godotExecutable @EngineArguments
    $engineExitCode = $LASTEXITCODE
    if ($engineExitCode -ne 0) {
        throw "Godot returned exit code $engineExitCode. See $LogPath"
    }
    $log = Get-Content -Raw -LiteralPath $LogPath
    if ($log -match '(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)') {
        throw "Godot reported an error or warning. See $LogPath"
    }
    if ($RequireSummary -and $log -notmatch 'PHASE_ONE: \d+ checks, 0 failures') {
        throw "Acceptance summary missing or failed. See $LogPath"
    }
}

try {
    # Redirect only this test process's writable Godot data into the workspace.
    $env:APPDATA = Join-Path $outputDirectory 'appdata'
    $env:LOCALAPPDATA = Join-Path $outputDirectory 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $importLog = Join-Path $outputDirectory 'import.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--editor', '--import', '--quit', '--log-file', $importLog
    ) -LogPath $importLog

    $testLog = Join-Path $outputDirectory $(if ($Screenshots) { 'phase-one-visual.log' } else { 'phase-one-headless.log' })
    $engineArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $testLog)
    if ($Screenshots) {
        $engineArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $engineArguments += '--headless'
    }
    $engineArguments += 'res://tests/phase_one_test.tscn'
    if ($Screenshots) {
        $engineArguments += @('--', '--screenshots')
    }
    Invoke-GodotCheck -EngineArguments $engineArguments -LogPath $testLog -RequireSummary $true
    Write-Host "Acceptance passed. Log: $testLog"
} catch {
    Write-Error -Message $_ -ErrorAction Continue
    $testExitCode = 1
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
exit $testExitCode
