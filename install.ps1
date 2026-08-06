# Managed-fork installer. This script only installs the binary bundled beside
# it in a reviewed release archive. It intentionally performs no network I/O.

$ErrorActionPreference = "Stop"

$InstallDir = "$env:LOCALAPPDATA\Programs\codebase-memory-mcp"
$SkipConfig = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    if ($arg -like "--dir=*") {
        $InstallDir = $arg.Substring(6)
    } elseif ($arg -eq "--dir") {
        if ($i + 1 -ge $args.Count) { throw "--dir requires a path" }
        $i++
        $InstallDir = $args[$i]
    } elseif ($arg -eq "--skip-config") {
        $SkipConfig = $true
    } elseif ($arg -eq "--standard" -or $arg -eq "--ui") {
        # The archive already determines the bundled variant.
    } elseif ($arg -eq "--help" -or $arg -eq "-h") {
        Write-Host "Usage: install.ps1 [--dir PATH] [--skip-config]"
        Write-Host "Installs only the codebase-memory-mcp.exe binary bundled beside this script."
        exit 0
    } else {
        throw "unknown installer option: $arg"
    }
}

$BundledBinary = Join-Path $PSScriptRoot "codebase-memory-mcp.exe"
if (-not (Test-Path -LiteralPath $BundledBinary -PathType Leaf)) {
    throw "reviewed release bundle is incomplete: $BundledBinary is missing"
}
$Candidate = Get-Item -LiteralPath $BundledBinary
if ($Candidate.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw "refusing reparse-point bundled executable"
}

$CandidateVersion = & $BundledBinary --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "bundled binary failed to run" }
Write-Host "Verified bundled candidate: $CandidateVersion"

$InstallArgs = @("install", "-y", "--force", "--dir=$InstallDir")
if ($SkipConfig) { $InstallArgs += "--skip-config" }
& $BundledBinary @InstallArgs
if ($LASTEXITCODE -ne 0) { throw "bundled binary installation failed" }

$InstalledBinary = Join-Path $InstallDir "codebase-memory-mcp.exe"
$InstalledVersion = & $InstalledBinary --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "installed binary failed to run" }
Write-Host "Installed: $InstalledVersion"
Write-Host "Updates are managed centrally; this build cannot self-update or fetch upstream releases."
