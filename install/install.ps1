<#
.SYNOPSIS
    Installs ProAI77 Embedded Skills into Antigravity, Claude Code, or Codex.
.DESCRIPTION
    Installs proai77-embedded-skills into user or project directory.
    Target: antigravity, claude, codex, or all.
    Scope: project (default) or user.
#>
[CmdletBinding()]
param(
    [ValidateSet("antigravity", "claude", "codex", "all")]
    [string]$Target = "all",

    [ValidateSet("project", "user")]
    [string]$Scope = "project",

    [string]$ProjectPath = "",

    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceRepo = Split-Path -Parent $ScriptDir

if (-not $ProjectPath) {
    $ProjectPath = Get-Location
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "ProAI77 Embedded Skills Installer" -ForegroundColor Cyan
Write-Host "Source:  $SourceRepo" -ForegroundColor Gray
Write-Host "Target:  $Target | Scope: $Scope" -ForegroundColor Gray
Write-Host "Project: $ProjectPath" -ForegroundColor Gray
if ($DryRun) { Write-Host "[DRY RUN MODE - No files will be modified]" -ForegroundColor Yellow }
Write-Host "==========================================================" -ForegroundColor Cyan

$SkillsDir = Join-Path $SourceRepo "skills"
$RulesSource = Join-Path $SourceRepo "shared\AGENTS.proai77.md"

if (-not (Test-Path $SkillsDir)) {
    Write-Error "Source skills directory not found: $SkillsDir"
}

$Destinations = @()

if ($Scope -eq "project") {
    if ($Target -in @("antigravity", "codex", "all")) {
        $Destinations += [PSCustomObject]@{
            Name = "Antigravity/Codex Project Skills"
            Path = (Join-Path $ProjectPath ".agents\skills")
            Type = "skills"
        }
    }
    if ($Target -in @("claude", "all")) {
        $Destinations += [PSCustomObject]@{
            Name = "Claude Code Project Skills"
            Path = (Join-Path $ProjectPath ".claude\skills")
            Type = "skills"
        }
    }
} else {
    $UserHome = [Environment]::GetFolderPath("UserProfile")
    if ($Target -in @("antigravity", "all")) {
        $Destinations += [PSCustomObject]@{
            Name = "Antigravity Global Plugin"
            Path = (Join-Path $UserHome ".gemini\config\plugins\proai77-embedded-skills")
            Type = "plugin"
        }
    }
    if ($Target -in @("codex", "all")) {
        $Destinations += [PSCustomObject]@{
            Name = "Codex User Skills"
            Path = (Join-Path $UserHome ".agents\skills")
            Type = "skills"
        }
    }
    if ($Target -in @("claude", "all")) {
        $Destinations += [PSCustomObject]@{
            Name = "Claude Code User Skills"
            Path = (Join-Path $UserHome ".claude\skills")
            Type = "skills"
        }
    }
}

foreach ($dest in $Destinations) {
    Write-Host "`nDeploying to $($dest.Name) -> $($dest.Path)" -ForegroundColor Green
    if ($dest.Type -eq "plugin") {
        if (-not $DryRun) {
            if (-not (Test-Path $dest.Path)) { New-Item -ItemType Directory -Path $dest.Path -Force | Out-Null }
            Copy-Item -Path (Join-Path $SourceRepo "plugin.json") -Destination $dest.Path -Force
            Copy-Item -Path (Join-Path $SourceRepo "README.md") -Destination $dest.Path -Force
            Copy-Item -Path (Join-Path $SourceRepo "rules") -Destination $dest.Path -Recurse -Force
            Copy-Item -Path (Join-Path $SourceRepo "skills") -Destination $dest.Path -Recurse -Force
        }
        Write-Host "  [OK] Installed full plugin package" -ForegroundColor Gray
    } else {
        $skillDirs = Get-ChildItem -Path $SkillsDir -Directory
        foreach ($sd in $skillDirs) {
            $targetSkillDir = Join-Path $dest.Path $sd.Name
            Write-Host "  -> Installing skill: $($sd.Name)" -ForegroundColor Gray
            if (-not $DryRun) {
                if (-not (Test-Path $targetSkillDir)) { New-Item -ItemType Directory -Path $targetSkillDir -Force | Out-Null }
                Copy-Item -Path (Join-Path $sd.FullName "*") -Destination $targetSkillDir -Recurse -Force
            }
        }
    }
}

# Merge AGENTS.md for project scope
if ($Scope -eq "project" -and (Test-Path $RulesSource)) {
    $TargetAgents = Join-Path $ProjectPath "AGENTS.md"
    Write-Host "`nUpdating Project Rules: $TargetAgents" -ForegroundColor Green
    $RuleContent = Get-Content -Path $RulesSource -Raw
    if (-not $DryRun) {
        if (Test-Path $TargetAgents) {
            $Existing = Get-Content -Path $TargetAgents -Raw
            if ($Existing -match "<!-- proai77-skills:begin -->([\s\S]*?)<!-- proai77-skills:end -->") {
                $Updated = $Existing -replace "<!-- proai77-skills:begin -->([\s\S]*?)<!-- proai77-skills:end -->", $RuleContent.Trim()
                Set-Content -Path $TargetAgents -Value $Updated -Encoding utf8
                Write-Host "  [OK] Replaced existing proai77-skills rule block in AGENTS.md" -ForegroundColor Gray
            } else {
                Add-Content -Path $TargetAgents -Value "`n`n$RuleContent" -Encoding utf8
                Write-Host "  [OK] Appended proai77-skills rule block to AGENTS.md" -ForegroundColor Gray
            }
        } else {
            Set-Content -Path $TargetAgents -Value $RuleContent -Encoding utf8
            Write-Host "  [OK] Created new AGENTS.md with proai77-skills rule block" -ForegroundColor Gray
        }
    }
}

Write-Host "`nInstallation Completed Successfully!" -ForegroundColor Green
