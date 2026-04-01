#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$SkillsSourceDir = './skills'
$AgentsSourceDir = './agents'
$DefaultTarget = 'oc'
$TargetProgram = $DefaultTarget
$TargetSpecified = $false
$SyncAll = $false
$DryRun = $false
$TempRoot = $null

function Write-Usage {
  Write-Host "Usage: ./sync.ps1 [oc|ghc|cc] [--dry-run|-DryRun] [--sync-all|-SyncAll]"
}

function Test-IsPowerShell7OrNewer {
  return $PSVersionTable.PSVersion.Major -ge 7
}

function Test-IsAdministrator {
  if (-not $IsWindows) {
    return $false
  }

  $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SkillsTargetDir {
  param([string]$Target)

  switch ($Target) {
    'oc' { return "$HOME/.config/opencode/skills" }
    'ghc' { return "$HOME/.copilot/skills" }
    'cc' { return "$HOME/.claude/skills" }
    default { throw "Unsupported target: $Target" }
  }
}

function Get-AgentsTargetDir {
  param([string]$Target)

  switch ($Target) {
    'oc' { return "$HOME/.config/opencode/agents" }
    default { return $null }
  }
}

function Ensure-TempRoot {
  if ($null -eq $script:TempRoot) {
    $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $script:TempRoot | Out-Null
  }
}

function Remove-TempRoot {
  if ($null -ne $script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
    Remove-Item -LiteralPath $script:TempRoot -Recurse -Force
  }
}

function Get-TextFiles {
  param([string]$Root)

  if (-not (Test-Path -LiteralPath $Root)) {
    return @()
  }

  return Get-ChildItem -LiteralPath $Root -Recurse -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in @('.md', '.yaml', '.yml') }
}

function Strip-TargetFrontmatter {
  param([string]$Content)

  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.AddRange(([string[]][System.Text.RegularExpressions.Regex]::Split($Content, "`n")))

  if ($lines.Count -lt 3) {
    return $Content
  }

  if ($lines[0].TrimEnd("`r") -ne '---') {
    return $Content
  }

  $endIndex = -1
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') {
      $endIndex = $i
      break
    }
  }

  if ($endIndex -lt 0) {
    return $Content
  }

  $rewritten = [System.Collections.Generic.List[string]]::new()
  $rewritten.Add($lines[0])

  $skipMetadata = $false
  for ($i = 1; $i -lt $endIndex; $i++) {
    $line = $lines[$i]
    $trimmedLine = $line.TrimEnd("`r")
    $stripped = $trimmedLine.TrimStart()
    $indent = $trimmedLine.Length - $stripped.Length

    if ($skipMetadata) {
      if ($stripped.Length -gt 0 -and $indent -gt 0) {
        continue
      }

      $skipMetadata = $false
    }

    if ($stripped.StartsWith('license:') -or $stripped.StartsWith('compatibility:')) {
      continue
    }

    if ($stripped.StartsWith('metadata:')) {
      $skipMetadata = $true
      continue
    }

    $rewritten.Add($line)
  }

  for ($i = $endIndex; $i -lt $lines.Count; $i++) {
    $rewritten.Add($lines[$i])
  }

  return ($rewritten -join "`n")
}

function Prepare-SkillSourceDir {
  param(
    [string]$SkillName,
    [string]$Target
  )

  $sourcePath = Join-Path $SkillsSourceDir $SkillName
  if ($Target -eq 'oc') {
    return $sourcePath
  }

  Ensure-TempRoot

  $preparedRoot = Join-Path $script:TempRoot $Target
  $preparedPath = Join-Path $preparedRoot $SkillName

  if (Test-Path -LiteralPath $preparedPath) {
    Remove-Item -LiteralPath $preparedPath -Recurse -Force
  }

  New-Item -ItemType Directory -Path $preparedRoot -Force | Out-Null
  Copy-Item -LiteralPath $sourcePath -Destination $preparedRoot -Recurse -Force

  $replacementMap = @{
    'ghc' = @{ From = '.opencode/'; To = '.copilot/' }
    'cc' = @{ From = '.opencode/'; To = '.claude/' }
  }

  foreach ($file in Get-TextFiles -Root $preparedPath) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $updated = $content

    if ($file.Name -eq 'SKILL.md') {
      $updated = Strip-TargetFrontmatter -Content $updated
    }

    $replacement = $replacementMap[$Target]
    if ($null -ne $replacement) {
      $updated = $updated.Replace($replacement.From, $replacement.To)
    }

    if ($updated -ne $content) {
      [System.IO.File]::WriteAllText($file.FullName, $updated, [System.Text.Encoding]::UTF8)
    }
  }

  return $preparedPath
}

function Get-RelativePath {
  param(
    [string]$Root,
    [string]$FullPath
  )

  $rootPath = [System.IO.Path]::GetFullPath($Root)
  $full = [System.IO.Path]::GetFullPath($FullPath)
  $relative = [System.IO.Path]::GetRelativePath($rootPath, $full)
  return ($relative -replace '\\', '/')
}

function Get-ManagedFiles {
  param([string]$Root)

  if (-not (Test-Path -LiteralPath $Root)) {
    return @()
  }

  return Get-ChildItem -LiteralPath $Root -Recurse -File |
    Sort-Object { Get-RelativePath -Root $Root -FullPath $_.FullName }
}

function Get-FileContentHash {
  param([string]$Path)

  return (Get-FileHash -LiteralPath $Path -Algorithm MD5).Hash.ToLowerInvariant()
}

function Test-ManagedDirectoryInSync {
  param(
    [string]$SourceDir,
    [string]$TargetDir
  )

  if (-not (Test-Path -LiteralPath $TargetDir)) {
    return $false
  }

  foreach ($sourceFile in Get-ManagedFiles -Root $SourceDir) {
    $relativePath = Get-RelativePath -Root $SourceDir -FullPath $sourceFile.FullName
    $targetPath = Join-Path $TargetDir $relativePath

    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
      return $false
    }

    if ((Get-FileContentHash -Path $sourceFile.FullName) -ne (Get-FileContentHash -Path $targetPath)) {
      return $false
    }
  }

  return $true
}

function Copy-ManagedDirectoryContents {
  param(
    [string]$SourceDir,
    [string]$TargetDir
  )

  New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

  foreach ($sourceFile in Get-ManagedFiles -Root $SourceDir) {
    $relativePath = Get-RelativePath -Root $SourceDir -FullPath $sourceFile.FullName
    $destinationPath = Join-Path $TargetDir $relativePath
    $destinationDir = Split-Path -Parent $destinationPath

    if (-not (Test-Path -LiteralPath $destinationDir)) {
      New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationPath -Force
  }
}

function Sync-Skill {
  param(
    [string]$SkillName,
    [string]$SkillsTargetDir,
    [string]$Target
  )

  $sourcePath = Prepare-SkillSourceDir -SkillName $SkillName -Target $Target
  $targetPath = Join-Path $SkillsTargetDir $SkillName

  if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
    Write-Host "-> Installing: $SkillName"
    if ($DryRun) {
      Write-Host "✓ Would install: $SkillName"
    }
    else {
      Copy-Item -LiteralPath $sourcePath -Destination $SkillsTargetDir -Recurse -Force
      Write-Host "✓ Installed: $SkillName"
    }

    return 'installed'
  }

  if (-not (Test-ManagedDirectoryInSync -SourceDir $sourcePath -TargetDir $targetPath)) {
    Write-Host "-> Updating: $SkillName"
    if ($DryRun) {
      Write-Host "↻ Would update: $SkillName"
    }
    else {
      Copy-ManagedDirectoryContents -SourceDir $sourcePath -TargetDir $targetPath
      Write-Host "↻ Updated: $SkillName"
    }

    return 'updated'
  }

  Write-Host "✓ Up-to-date: $SkillName"
  return 'unchanged'
}

function Sync-Agent {
  param(
    [string]$AgentFile,
    [string]$AgentsTargetDir
  )

  $sourcePath = Join-Path $AgentsSourceDir $AgentFile
  $targetPath = Join-Path $AgentsTargetDir $AgentFile

  if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    Write-Host "-> Installing: $AgentFile"
    if ($DryRun) {
      Write-Host "✓ Would install: $AgentFile"
    }
    else {
      Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
      Write-Host "✓ Installed: $AgentFile"
    }

    return 'installed'
  }

  if ((Get-FileContentHash -Path $sourcePath) -ne (Get-FileContentHash -Path $targetPath)) {
    Write-Host "-> Updating: $AgentFile"
    if ($DryRun) {
      Write-Host "↻ Would update: $AgentFile"
    }
    else {
      Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
      Write-Host "↻ Updated: $AgentFile"
    }

    return 'updated'
  }

  Write-Host "✓ Up-to-date: $AgentFile"
  return 'unchanged'
}

function Confirm-SyncOperation {
  param([string[]]$Targets)

  Write-Host "Sync plan:"
  Write-Host "  Dry-run: $DryRun"
  Write-Host "  Skills source: $SkillsSourceDir"

  if (Test-Path -LiteralPath $AgentsSourceDir) {
    Write-Host "  Agents source: $AgentsSourceDir"
  }

  foreach ($target in $Targets) {
    $skillsTargetDir = Get-SkillsTargetDir -Target $target
    $agentsTargetDir = Get-AgentsTargetDir -Target $target
    $agentMode = if ($null -ne $agentsTargetDir) { 'yes' } else { 'no' }

    Write-Host "  Target: $target"
    Write-Host "    Skills destination: $skillsTargetDir"
    Write-Host "    Sync agents: $agentMode"
    if ($null -ne $agentsTargetDir) {
      Write-Host "    Agents destination: $agentsTargetDir"
    }
  }

  $response = Read-Host 'Proceed with sync? [y/N]'
  if ($response -notmatch '^(?i:y|yes)$') {
    Write-Host 'Sync cancelled.'
    exit 0
  }
}

function Sync-Target {
  param([string]$Target)

  $skillsTargetDir = Get-SkillsTargetDir -Target $Target
  $agentsTargetDir = Get-AgentsTargetDir -Target $Target

  Write-Host "Sync target: $Target"
  Write-Host "Syncing skills from $SkillsSourceDir to $skillsTargetDir"
  Write-Host ''

  New-Item -ItemType Directory -Path $skillsTargetDir -Force | Out-Null

  $skillsInstalled = 0
  $skillsUpdated = 0
  $skillsUnchanged = 0

  foreach ($skillDir in Get-ChildItem -LiteralPath $SkillsSourceDir -Directory | Sort-Object Name) {
    $result = Sync-Skill -SkillName $skillDir.Name -SkillsTargetDir $skillsTargetDir -Target $Target
    switch ($result) {
      'installed' { $skillsInstalled++ }
      'updated' { $skillsUpdated++ }
      'unchanged' { $skillsUnchanged++ }
      default { throw "Failed to sync skill '$($skillDir.Name)'" }
    }
  }

  Write-Host ''
  if ($DryRun) {
    Write-Host "Skills: $skillsInstalled would be installed, $skillsUpdated would be updated, $skillsUnchanged up-to-date"
  }
  else {
    Write-Host "Skills: $skillsInstalled installed, $skillsUpdated updated, $skillsUnchanged up-to-date"
  }

  if ((Test-Path -LiteralPath $AgentsSourceDir) -and $null -ne $agentsTargetDir) {
    Write-Host ''
    Write-Host "Syncing agents from $AgentsSourceDir to $agentsTargetDir"
    Write-Host ''

    New-Item -ItemType Directory -Path $agentsTargetDir -Force | Out-Null

    $agentsInstalled = 0
    $agentsUpdated = 0
    $agentsUnchanged = 0

    foreach ($agent in Get-ChildItem -LiteralPath $AgentsSourceDir -Filter '*.md' -File | Sort-Object Name) {
      $result = Sync-Agent -AgentFile $agent.Name -AgentsTargetDir $agentsTargetDir
      switch ($result) {
        'installed' { $agentsInstalled++ }
        'updated' { $agentsUpdated++ }
        'unchanged' { $agentsUnchanged++ }
        default { throw "Failed to sync agent '$($agent.Name)'" }
      }
    }

    Write-Host ''
    if ($DryRun) {
      Write-Host "Agents: $agentsInstalled would be installed, $agentsUpdated would be updated, $agentsUnchanged up-to-date"
    }
    else {
      Write-Host "Agents: $agentsInstalled installed, $agentsUpdated updated, $agentsUnchanged up-to-date"
    }
  }
  elseif ($Target -ne 'oc') {
    Write-Host ''
    Write-Host "Note: Agent sync is only supported for oc; skipping agents for $Target"
  }
}

try {
  if (-not (Test-IsPowerShell7OrNewer)) {
    Write-Error 'This script requires PowerShell 7 or newer. Run it with pwsh.'
    exit 1
  }

  if (Test-IsAdministrator) {
    Write-Error 'This script must be run as a normal user, not Administrator.'
    exit 1
  }

  $remainingArgs = @($args)
  while ($remainingArgs.Count -gt 0) {
    $arg = $remainingArgs[0]

    switch ($arg) {
      'oc' {
        if ($SyncAll) {
          Write-Host "Cannot combine target '$arg' with --sync-all"
          Write-Usage
          exit 1
        }
        if ($TargetSpecified) {
          Write-Host "Cannot specify multiple targets: '$TargetProgram' and '$arg'"
          Write-Usage
          exit 1
        }
        $TargetProgram = $arg
        $TargetSpecified = $true
      }
      'ghc' {
        if ($SyncAll) {
          Write-Host "Cannot combine target '$arg' with --sync-all"
          Write-Usage
          exit 1
        }
        if ($TargetSpecified) {
          Write-Host "Cannot specify multiple targets: '$TargetProgram' and '$arg'"
          Write-Usage
          exit 1
        }
        $TargetProgram = $arg
        $TargetSpecified = $true
      }
      'cc' {
        if ($SyncAll) {
          Write-Host "Cannot combine target '$arg' with --sync-all"
          Write-Usage
          exit 1
        }
        if ($TargetSpecified) {
          Write-Host "Cannot specify multiple targets: '$TargetProgram' and '$arg'"
          Write-Usage
          exit 1
        }
        $TargetProgram = $arg
        $TargetSpecified = $true
      }
      '--sync-all' {
        if ($TargetProgram -ne $DefaultTarget -or $TargetSpecified) {
          Write-Host "Cannot combine explicit target '$TargetProgram' with --sync-all"
          Write-Usage
          exit 1
        }
        $SyncAll = $true
      }
      '-SyncAll' {
        if ($TargetProgram -ne $DefaultTarget -or $TargetSpecified) {
          Write-Host "Cannot combine explicit target '$TargetProgram' with --sync-all"
          Write-Usage
          exit 1
        }
        $SyncAll = $true
      }
      '--dry-run' { $DryRun = $true }
      '-DryRun' { $DryRun = $true }
      default {
        Write-Host "Unknown option: $arg"
        Write-Usage
        exit 1
      }
    }

    if ($remainingArgs.Count -gt 1) {
      $remainingArgs = $remainingArgs[1..($remainingArgs.Count - 1)]
    }
    else {
      $remainingArgs = @()
    }
  }

  if (-not (Test-Path -LiteralPath $SkillsSourceDir -PathType Container)) {
    Write-Error "Source directory '$SkillsSourceDir' does not exist"
    exit 1
  }

  if ($DryRun) {
    Write-Host 'DRY RUN MODE - No changes will be made'
  }

  $targets = if ($SyncAll) { @('oc', 'ghc', 'cc') } else { @($TargetProgram) }
  Confirm-SyncOperation -Targets $targets

  for ($i = 0; $i -lt $targets.Count; $i++) {
    Sync-Target -Target $targets[$i]
    if ($i -lt ($targets.Count - 1)) {
      Write-Host ''
    }
  }
}
finally {
  Remove-TempRoot
}
