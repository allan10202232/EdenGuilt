param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [switch]$Headless
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$output = Join-Path $projectDirectory 'test-output/export'
$isolated = Join-Path $output 'standalone'
New-Item -ItemType Directory -Force -Path $isolated | Out-Null
# Only the executable is copied: there is no editor, project.godot or sidecar PCK.
$copy = Join-Path $isolated 'EdenGuilt.exe'
Copy-Item -LiteralPath $Executable -Destination $copy -Force
if ((Get-FileHash -LiteralPath $Executable).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) { throw 'EXE copy checksum mismatch.' }
$savedEnvironment = @{}
foreach ($key in @('APPDATA', 'LOCALAPPDATA')) { $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }
try {
    $env:APPDATA = Join-Path $output 'runtime-appdata'
    $env:LOCALAPPDATA = Join-Path $output 'runtime-localappdata'
    $log = Join-Path $output 'standalone-smoke.log'
    $arguments = @('--audio-driver', 'Dummy', '--fixed-fps', '60', '--log-file', ('"' + $log + '"'))
    if ($Headless) { $arguments += '--headless' }
    $arguments += @('--', '--export-smoke-test')
    $process = Start-Process -FilePath $copy -WorkingDirectory $isolated -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(120000)) {
        # This process was created by this verifier; existing game/editor sessions are untouched.
        Stop-Process -Id $process.Id
        throw "Standalone verification timed out. See $log"
    }
    $text = Get-Content -LiteralPath $log -Raw
    if ($process.ExitCode -ne 0 -or $text -match '(?m)^(ERROR:|SCRIPT ERROR:|WARNING:|FAIL:)' -or $text -notmatch 'STANDALONE EXPORT: \d+ checks, 0 failures') {
        throw "Standalone verification failed. See $log"
    }
    Write-Output ($text -split "`n" | Where-Object { $_ -match '^STANDALONE EXPORT:' })
    Write-Output "Log: $log"
    Write-Output "Screenshots: $env:APPDATA/Godot/app_userdata/EdenGuilt/export-smoke"
} finally {
    foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], 'Process') }
}
