#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local build script for ExportRepoCode - creates all release artifacts locally

.DESCRIPTION
    This script creates the same artifacts that the GitHub Actions release workflow creates:
    - Windows batch wrapper (.bat)
    - Standalone executable (.exe) 
    - Installation script (install.ps1)
    
    Useful for testing releases locally before pushing tags.

.PARAMETER Version
    Version string to embed in the artifacts (e.g., "v1.0.0")

.PARAMETER OutputDir
    Directory to place build artifacts (default: ./build)

.PARAMETER SkipExe
    Skip creating the executable (requires ps2exe module)

.EXAMPLE
    .\build.ps1 -Version "v1.0.0"
    
.EXAMPLE
    .\build.ps1 -Version "v1.0.1" -OutputDir "./dist" -SkipExe
#>

param(
    [Parameter(Mandatory)]
    [string]$Version,
    
    [string]$OutputDir = "./build",
    
    [switch]$SkipExe
)

# Ensure we're in the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "ExportRepoCode Build Script" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Green
Write-Host "Output Directory: $OutputDir" -ForegroundColor Green
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Yellow
}

# Copy main PowerShell script with version
Write-Host "Creating versioned PowerShell script..." -ForegroundColor Cyan
$content = Get-Content "ExportRepoCode.ps1" -Raw
$newContent = $content -replace '# Version: .*\r?\n', ''
$newContent = "# Version: $Version`r`n$newContent"
$outputScript = Join-Path $OutputDir "ExportRepoCode.ps1"
Set-Content $outputScript -Value $newContent -NoNewline
Write-Host "Created: $outputScript" -ForegroundColor Green

# Create batch wrapper
Write-Host "Creating Windows batch wrapper..." -ForegroundColor Cyan
$batContent = @"
@echo off
REM ExportRepoCode Windows Batch Wrapper
REM Version: $Version

echo Starting ExportRepoCode...
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available on this system.
    echo Please install PowerShell or run ExportRepoCode.ps1 directly.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0ExportRepoCode.ps1"

REM Pause to show results
echo.
echo Press any key to close...
pause >nul
"@
$outputBat = Join-Path $OutputDir "ExportRepoCode.bat"
Set-Content $outputBat -Value $batContent
Write-Host "Created: $outputBat" -ForegroundColor Green

# Create executable (optional)
if (-not $SkipExe) {
    Write-Host "Creating standalone executable..." -ForegroundColor Cyan
    
    # Check if ps2exe is available
    $ps2exeModule = Get-Module -ListAvailable -Name ps2exe
    if (-not $ps2exeModule) {
        Write-Host "Installing ps2exe module..." -ForegroundColor Yellow
        try {
            Install-Module ps2exe -Force -Scope CurrentUser
        } catch {
            Write-Warning "Failed to install ps2exe: $($_.Exception.Message)"
            Write-Warning "Skipping executable creation. Install ps2exe manually or use -SkipExe parameter."
            $SkipExe = $true
        }
    }
    
    if (-not $SkipExe) {
        try {
            Import-Module ps2exe
            
            # Create a version with embedded error handling for standalone execution
            $exeScript = @"
# ExportRepoCode Executable Version
# Version: $Version
# This is a standalone executable version of ExportRepoCode

# Add console window title
`$Host.UI.RawUI.WindowTitle = "ExportRepoCode $Version"

# Error handling wrapper
try {
$(Get-Content "ExportRepoCode.ps1" -Raw)
} catch {
    Write-Host "An error occurred: `$(`$_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Pause at the end for executable version
Write-Host "`nPress any key to exit..." -ForegroundColor Green
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@
            
            $tempScript = Join-Path $OutputDir "ExportRepoCode-Standalone.ps1"
            Set-Content $tempScript -Value $exeScript
            
            # Convert to executable
            $outputExe = Join-Path $OutputDir "ExportRepoCode.exe"
            Invoke-ps2exe -inputFile $tempScript -outputFile $outputExe -noConsole:$false -title "ExportRepoCode" -description "Export repository code to text file" -company "ExportRepoCode" -version "$Version.0" -noError -noOutput
            
            # Clean up temp file
            Remove-Item $tempScript -Force
            
            Write-Host "Created: $outputExe" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to create executable: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "Skipping executable creation" -ForegroundColor Yellow
}

# Create installation script
Write-Host "Creating installation script..." -ForegroundColor Cyan
$installScript = @"
# ExportRepoCode Installation Script
# Version: $Version

param(
    [string]`$InstallPath = "`$env:USERPROFILE\ExportRepoCode",
    [switch]`$AddToPath,
    [switch]`$CreateDesktopShortcut
)

Write-Host "ExportRepoCode Installation Script" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Green
Write-Host ""

# Create installation directory
if (-not (Test-Path `$InstallPath)) {
    New-Item -Path `$InstallPath -ItemType Directory -Force | Out-Null
    Write-Host "Created installation directory: `$InstallPath" -ForegroundColor Yellow
}

# Download files (when run from GitHub release)
`$baseUrl = "https://github.com/Chromeninja/ExportRepoCode/releases/download/$Version"
`$files = @("ExportRepoCode.ps1", "ExportRepoCode.bat", "ExportRepoCode.exe")

foreach (`$file in `$files) {
    try {
        `$destinationPath = Join-Path `$InstallPath `$file
        Write-Host "Downloading `$file..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "`$baseUrl/`$file" -OutFile `$destinationPath
        Write-Host "Downloaded: `$destinationPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to download `$file: `$(`$_.Exception.Message)"
    }
}

# Add to PATH if requested
if (`$AddToPath) {
    `$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (`$currentPath -notlike "*`$InstallPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "`$currentPath;`$InstallPath", "User")
        Write-Host "Added `$InstallPath to user PATH" -ForegroundColor Green
        Write-Host "Restart your terminal to use 'ExportRepoCode' command" -ForegroundColor Yellow
    }
}

# Create desktop shortcut if requested
if (`$CreateDesktopShortcut) {
    `$desktopPath = [Environment]::GetFolderPath("Desktop")
    `$shortcutPath = Join-Path `$desktopPath "ExportRepoCode.lnk"
    `$targetPath = Join-Path `$InstallPath "ExportRepoCode.bat"
    
    if (Test-Path `$targetPath) {
        `$shell = New-Object -ComObject WScript.Shell
        `$shortcut = `$shell.CreateShortcut(`$shortcutPath)
        `$shortcut.TargetPath = `$targetPath
        `$shortcut.WorkingDirectory = `$InstallPath
        `$shortcut.Description = "Export repository code to text file"
        `$shortcut.Save()
        Write-Host "Created desktop shortcut: `$shortcutPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Installation directory: `$InstallPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage options:" -ForegroundColor Yellow
Write-Host "  1. Run from installation directory: `$InstallPath\ExportRepoCode.bat" -ForegroundColor White
Write-Host "  2. PowerShell: `$InstallPath\ExportRepoCode.ps1" -ForegroundColor White
Write-Host "  3. Executable: `$InstallPath\ExportRepoCode.exe" -ForegroundColor White
if (`$AddToPath) {
    Write-Host "  4. From anywhere (after terminal restart): ExportRepoCode.bat" -ForegroundColor White
}
"@

$outputInstall = Join-Path $OutputDir "install.ps1"
Set-Content $outputInstall -Value $installScript
Write-Host "Created: $outputInstall" -ForegroundColor Green

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "Build artifacts created in: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Get-ChildItem $OutputDir | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor White
}