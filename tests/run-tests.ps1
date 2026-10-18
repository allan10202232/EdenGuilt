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
    param([string[]]$EngineArguments, [string]$LogPath, [string]$Summary = '')
    & $godotExecutable @EngineArguments
    $engineExitCode = $LASTEXITCODE
    if ($engineExitCode -ne 0) {
        throw "Godot returned exit code $engineExitCode. See $LogPath"
    }
    $log = Get-Content -Raw -LiteralPath $LogPath
    # main contains a separate historical Godot project; the root editor skips it.
    $log = $log -replace '(?m)^WARNING: Detected another project.godot at res://prototype\. The folder will be ignored\.\r?$', ''
    if ($log -match '(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)') {
        throw "Godot reported an error or warning. See $LogPath"
    }
    if ($Summary -and $log -notmatch ($Summary + ': \d+ checks, 0 failures')) {
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
    Invoke-GodotCheck -EngineArguments $engineArguments -LogPath $testLog -Summary 'PHASE_ONE'
    Write-Host "Acceptance passed. Log: $testLog"

    $meleeLog = Join-Path $outputDirectory $(if ($Screenshots) { 'melee-visual.log' } else { 'melee-headless.log' })
    $meleeArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $meleeLog)
    if ($Screenshots) {
        $meleeArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $meleeArguments += '--headless'
    }
    $meleeArguments += 'res://tests/melee_test.tscn'
    if ($Screenshots) { $meleeArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $meleeArguments -LogPath $meleeLog -Summary 'MELEE'
    Write-Host "Melee templates passed. Log: $meleeLog"
    $campaignLog = Join-Path $outputDirectory $(if ($Screenshots) { 'campaign-visual.log' } else { 'campaign-headless.log' })
    $campaignArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $campaignLog)
    if ($Screenshots) {
        $campaignArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $campaignArguments += '--headless'
    }
    $campaignArguments += 'res://tests/campaign/campaign_test.tscn'
    if ($Screenshots) { $campaignArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $campaignArguments -LogPath $campaignLog -Summary 'CAMPAIGN'
    Write-Host "Three-level campaign passed. Log: $campaignLog"
} catch {
    Write-Error -Message $_ -ErrorAction Continue
    $testExitCode = 1
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
exit $testExitCode
