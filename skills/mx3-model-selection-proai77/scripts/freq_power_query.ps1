<#
.SYNOPSIS
    Queries ProAI77 MX3 frequency & power matrix (M.2 <= 9W).
#>
param(
    [string]$ModelRegex = ".*",
    [double]$TargetFps = 30.0,
    [double]$Safety = 1.5,
    [double]$MaxPowerMw = 9000.0,
    [int]$MaxFreq = 500,
    [switch]$FormatCsv
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CsvPath = Join-Path $ScriptDir "..\references\proai77-freq-power-matrix.csv"

if (-not (Test-Path $CsvPath)) {
    Write-Error "Matrix file not found: $CsvPath"
}

$RequiredFps = $TargetFps * $Safety
$RawLines = Get-Content -Path $CsvPath | Where-Object { $_ -and -not $_.StartsWith("#") }
$Records = $RawLines | ConvertFrom-Csv

$Groups = $Records | Where-Object { $_.model -match $ModelRegex } | Group-Object model

if (-not $Groups) {
    Write-Host "No models matched regex: $ModelRegex"
    exit 0
}

Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host "ProAI77 MX3 Model & Frequency Query (Target: $TargetFps fps | Need >= $RequiredFps fps | Max Power <= $MaxPowerMw mW)" -ForegroundColor Cyan
Write-Host "==========================================================================================" -ForegroundColor Cyan

foreach ($g in $Groups) {
    $rows = $g.Group | Sort-Object { [int]$_.freq_mhz }
    $chosen = $null

    foreach ($r in $rows) {
        $freq = [int]$r.freq_mhz
        if ($freq -gt $MaxFreq) { continue }
        if ($r.status -ne "PASS") { continue }

        $fps = [double]$r.fps
        $power = [double]$r.power_mw

        if ($power -gt $MaxPowerMw) { continue }
        if ($fps -ge $RequiredFps) {
            $chosen = @{
                Model = $g.Name
                Freq = "$($freq)MHz"
                Status = "PASS"
                Fps = $fps
                Power = $power
                Margin = [math]::Round(($fps / $TargetFps), 2)
            }
            break
        }
    }

    if ($chosen) {
        Write-Host ("{0,-45} | {1,-7} | {2,-10} | {3,-7:N1} | {4,-10:N1} | {5}x" -f $chosen.Model.Substring(0, [math]::Min(45, $chosen.Model.Length)), $chosen.Freq, $chosen.Status, $chosen.Fps, $chosen.Power, $chosen.Margin) -ForegroundColor Green
    } else {
        Write-Host ("{0,-45} | {1,-7} | {2,-10} | {3,-7} | {4,-10} | Exceeds 9W or FPS not met" -f $g.Name.Substring(0, [math]::Min(45, $g.Name.Length)), "--", "NOT RECOMMENDED", "--", "--") -ForegroundColor Yellow
    }
}
Write-Host "==========================================================================================" -ForegroundColor Cyan
