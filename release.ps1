#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Release script for ExportRepoCode - creates and pushes a new release

.DESCRIPTION
    This script helps create new releases by:
    1. Building artifacts locally for testing
    2. Creating and pushing a git tag
    3. The GitHub Actions workflow will automatically create the release

.PARAMETER Version
    Version to release (e.g., "v1.0.0"). Must start with 'v'.

.PARAMETER TestOnly
    Only build locally for testing, don't create git tag

.PARAMETER Force
    Force create the tag even if it already exists

.EXAMPLE
    .\release.ps1 -Version "v1.0.0"
    
.EXAMPLE
    .\release.ps1 -Version "v1.0.1" -TestOnly
#>

param(
    [Parameter(Mandatory)]
    [ValidatePattern('^v\d+\.\d+\.\d+.*')]
    [string]$Version,
    
    [switch]$TestOnly,
    
    [switch]$Force
)

# Ensure we're in the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "ExportRepoCode Release Script" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Green
if ($TestOnly) {
    Write-Host "Mode: Test build only" -ForegroundColor Yellow
} else {
    Write-Host "Mode: Full release" -ForegroundColor Green
}
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Error "Not in a git repository. Please run this script from the repository root."
    exit 1
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus -and -not $TestOnly) {
    Write-Warning "You have uncommitted changes:"
    git status --short
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# Check if tag already exists
$existingTag = git tag -l $Version
if ($existingTag -and -not $Force -and -not $TestOnly) {
    Write-Error "Tag $Version already exists. Use -Force to override or choose a different version."
    exit 1
}

# Build artifacts locally
Write-Host "Building release artifacts locally..." -ForegroundColor Cyan
try {
    & ".\build.ps1" -Version $Version -OutputDir "./build"
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
} catch {
    Write-Error "Local build failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "Local build successful!" -ForegroundColor Green

# Test the built artifacts
Write-Host ""
Write-Host "Testing built artifacts..." -ForegroundColor Cyan

# Test PowerShell script
if (Test-Path "./build/ExportRepoCode.ps1") {
    try {
        $testResult = pwsh -Command "& './build/ExportRepoCode.ps1' -WhatIf" -ErrorAction SilentlyContinue
        Write-Host "✓ PowerShell script syntax OK" -ForegroundColor Green
    } catch {
        Write-Warning "PowerShell script test failed: $($_.Exception.Message)"
    }
}

# Test batch file
if (Test-Path "./build/ExportRepoCode.bat") {
    Write-Host "✓ Batch file created" -ForegroundColor Green
}

# Test executable
if (Test-Path "./build/ExportRepoCode.exe") {
    Write-Host "✓ Executable created" -ForegroundColor Green
} else {
    Write-Warning "Executable not created (ps2exe might not be available)"
}

# Test installation script
if (Test-Path "./build/install.ps1") {
    try {
        $testResult = pwsh -Command "& './build/install.ps1' -WhatIf" -ErrorAction SilentlyContinue
        Write-Host "✓ Installation script syntax OK" -ForegroundColor Green
    } catch {
        Write-Warning "Installation script test failed: $($_.Exception.Message)"
    }
}

if ($TestOnly) {
    Write-Host ""
    Write-Host "Test build complete! Check the ./build directory for artifacts." -ForegroundColor Green
    Write-Host ""
    Write-Host "To create a full release, run:" -ForegroundColor Yellow
    Write-Host "  .\release.ps1 -Version '$Version'" -ForegroundColor White
    exit 0
}

# Create and push git tag
Write-Host ""
Write-Host "Creating git tag..." -ForegroundColor Cyan

try {
    if ($Force -and $existingTag) {
        git tag -d $Version
        git push origin --delete $Version 2>$null
    }
    
    git tag -a $Version -m "Release $Version"
    
    Write-Host "Pushing tag to GitHub..." -ForegroundColor Cyan
    git push origin $Version
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push tag"
    }
    
} catch {
    Write-Error "Failed to create/push tag: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "Release $Version initiated!" -ForegroundColor Green
Write-Host ""
Write-Host "The GitHub Actions workflow will now:" -ForegroundColor Yellow
Write-Host "  1. Build release artifacts" -ForegroundColor White
Write-Host "  2. Create a GitHub release" -ForegroundColor White
Write-Host "  3. Upload all distribution files" -ForegroundColor White
Write-Host ""
Write-Host "Monitor the release at:" -ForegroundColor Cyan
Write-Host "  https://github.com/Chromeninja/ExportRepoCode/actions" -ForegroundColor Blue
Write-Host ""
Write-Host "Once complete, the release will be available at:" -ForegroundColor Cyan
Write-Host "  https://github.com/Chromeninja/ExportRepoCode/releases/tag/$Version" -ForegroundColor Blue