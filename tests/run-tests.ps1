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
    # Catch a lost autoload before Godot emits cascading parser errors (which can
    # still return exit code 0 during editor import).
    $projectConfig = Get-Content -Raw -LiteralPath (Join-Path $projectDirectory 'project.godot')
    foreach ($singleton in @('GameText', 'GameSession', 'WorldProgress', 'CarbonLedger', 'SoundManager')) {
        $registration = '(?m)^' + [regex]::Escape($singleton) + '="\*res://([^"\r\n]+)"\s*$'
        $configMatch = [regex]::Match($projectConfig, $registration)
        if (-not $configMatch.Success) {
            throw "Missing autoload $singleton in project.godot. Reopen the project after restoring its [autoload] registration."
        }
        $scriptPath = Join-Path $projectDirectory $configMatch.Groups[1].Value
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            throw "Autoload $singleton points to a missing script: $scriptPath"
        }
    }
    # Redirect only this test process's writable Godot data into the workspace.
    $env:APPDATA = Join-Path $outputDirectory 'appdata'
    $env:LOCALAPPDATA = Join-Path $outputDirectory 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $importLog = Join-Path $outputDirectory 'import.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--editor', '--import', '--quit', '--log-file', $importLog
    ) -LogPath $importLog

    $startupLog = Join-Path $outputDirectory 'startup.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--audio-driver', 'Dummy',
        '--log-file', $startupLog, 'res://tests/startup_test.tscn'
    ) -LogPath $startupLog -Summary 'STARTUP'
    Write-Host "Startup configuration passed. Log: $startupLog"

    $storyLog = Join-Path $outputDirectory 'story.log'
    $storyArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--fixed-fps', '60', '--log-file', $storyLog)
    if ($Screenshots) { $storyArguments += @('--rendering-method', 'gl_compatibility') }
    else { $storyArguments += '--headless' }
    $storyArguments += 'res://tests/campaign/story_test.tscn'
    if ($Screenshots) { $storyArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $storyArguments -LogPath $storyLog -Summary 'STORY'
    Write-Host "Bilingual NPCs, learning and toxin puzzle passed. Log: $storyLog"
    $openingLog = Join-Path $outputDirectory $(if ($Screenshots) { 'opening-visual.log' } else { 'opening-headless.log' })
    $openingArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $openingLog)
    if ($Screenshots) {
        $openingArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $openingArguments += '--headless'
    }
    $openingArguments += 'res://tests/opening_test.tscn'
    if ($Screenshots) { $openingArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $openingArguments -LogPath $openingLog -Summary 'OPENING'
    Write-Host "Opening cinematic passed. Log: $openingLog"

    $healthLog = Join-Path $outputDirectory $(if ($Screenshots) { 'health-visual.log' } else { 'health-headless.log' })
    $healthArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $healthLog)
    if ($Screenshots) {
        $healthArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $healthArguments += '--headless'
    }
    $healthArguments += 'res://tests/health_test.tscn'
    if ($Screenshots) { $healthArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $healthArguments -LogPath $healthLog -Summary 'HEALTH'
    Write-Host "Life orbs and damage passed. Log: $healthLog"

    $extractionLog = Join-Path $outputDirectory $(if ($Screenshots) { 'extraction-visual.log' } else { 'extraction-headless.log' })
    $extractionArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $extractionLog)
    if ($Screenshots) {
        $extractionArguments += @('--rendering-method', 'gl_compatibility')
    } else {
        $extractionArguments += '--headless'
    }
    $extractionArguments += 'res://tests/extraction_test.tscn'
    if ($Screenshots) { $extractionArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $extractionArguments -LogPath $extractionLog -Summary 'EXTRACTION'
    Write-Host "Living oases and extraction passed. Log: $extractionLog"

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
    $carbonLog = Join-Path $outputDirectory 'carbon-headless.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--audio-driver', 'Dummy', '--log-file', $carbonLog,
        'res://tests/carbon/carbon_test.tscn'
    ) -LogPath $carbonLog -Summary 'CARBON'
    Write-Host "Carbon ledger and audit passed. Log: $carbonLog"
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

    $actionLog = Join-Path $outputDirectory $(if ($Screenshots) { 'actions-visual.log' } else { 'actions-headless.log' })
    $actionArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--fixed-fps', '60', '--log-file', $actionLog)
    if ($Screenshots) { $actionArguments += @('--rendering-method', 'gl_compatibility') }
    else { $actionArguments += '--headless' }
    $actionArguments += 'res://tests/campaign/action_test.tscn'
    if ($Screenshots) { $actionArguments += @('--', '--screenshots') }
    Invoke-GodotCheck -EngineArguments $actionArguments -LogPath $actionLog -Summary 'ACTIONS'
    Write-Host "Character actions passed. Log: $actionLog"

    $enemyLog = Join-Path $outputDirectory 'enemy-actions.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--audio-driver', 'Dummy', '--fixed-fps', '60',
        '--log-file', $enemyLog, 'res://tests/campaign/enemy_animation_test.tscn'
    ) -LogPath $enemyLog -Summary 'ENEMY_ACTIONS'
    Write-Host "Enemy animation and attack synchronization passed. Log: $enemyLog"

    $routeLog = Join-Path $outputDirectory 'route.log'
    Invoke-GodotCheck -EngineArguments @(
        '--headless', '--path', $projectDirectory, '--audio-driver', 'Dummy', '--fixed-fps', '60',
        '--log-file', $routeLog, 'res://tests/campaign/route_test.tscn'
    ) -LogPath $routeLog -Summary 'ROUTE'
    Write-Host "Physical round trip passed. Log: $routeLog"

    $walkthroughLog = Join-Path $outputDirectory $(if ($Screenshots) { 'walkthrough-visual.log' } else { 'walkthrough-headless.log' })
    $walkthroughArguments = @('--path', $projectDirectory, '--audio-driver', 'Dummy', '--fixed-fps', '60', '--log-file', $walkthroughLog)
    if ($Screenshots) { $walkthroughArguments += @('--rendering-method', 'gl_compatibility') }
    else { $walkthroughArguments += '--headless' }
    $walkthroughArguments += 'res://tests/campaign/walkthrough_test.tscn'
    Invoke-GodotCheck -EngineArguments $walkthroughArguments -LogPath $walkthroughLog -Summary 'WALKTHROUGH'
    Write-Host "Normal-input A/B walkthrough passed. Log: $walkthroughLog"
} catch {
    Write-Error -Message $_ -ErrorAction Continue
    $testExitCode = 1
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
exit $testExitCode
