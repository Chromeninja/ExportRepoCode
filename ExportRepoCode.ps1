<#
.SYNOPSIS
    Exports all code files (including .txt) from a selected project folder to a single TXT file, respecting .gitignore patterns.
.DESCRIPTION
    - Script sits in a host directory containing multiple project subfolders.
    - Prompts user to select which project folder to export.
    - Attempts to use Git (if available and safe) to list tracked files and untracked .txt files.
    - Falls back to manual .gitignore parsing if Git is not available or fails.
    - Skips the .git directory entirely.
    - Includes .txt files by default (unless in .gitignore).
    - Always force-includes specific explicit files (e.g., config/config.yaml).
    - Hard-excludes common noise and sensitive file patterns (e.g., __pycache__, .env, node_modules).
#>

# Determine host directory (where the script resides)
$HostDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# List available project folders
$projects = Get-ChildItem -Path $HostDirectory -Directory | Select-Object -ExpandProperty Name
if (-not $projects) {
    Write-Error "No subdirectories found in $HostDirectory"
    exit 1
}

Write-Host "Available project folders:`n"
for ($i = 0; $i -lt $projects.Count; $i++) {
    Write-Host "[$i] $($projects[$i])"
}

# Prompt user for selection
$selection = Read-Host "Enter the number of the project folder to export"
if ($selection -notmatch '^[0-9]+$') {
    Write-Error "Invalid selection: not a number. Exiting."
    exit 1
}
[int]$index = $selection
if ($index -lt 0 -or $index -ge $projects.Count) {
    Write-Error "Invalid selection: out of range. Exiting."
    exit 1
}

$projectName = $projects[$index]
$ScriptDirectory = Join-Path $HostDirectory $projectName

# Determine output file based on project name
$OutputFile = Join-Path $HostDirectory "$projectName-ALLCODE.txt"

# Initialize or clear the output file
if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }
New-Item -Path $OutputFile -ItemType File -Force | Out-Null

# Explicit includes
$ExplicitIncludes = @('config/config.yaml')

# Hard exclusions regardless of .gitignore
$HardExclusions = @(
    'node_modules', '__pycache__', '.venv', '.DS_Store', '*.log', '*.tmp', '*.bak', '*.env',
    '.coverage', '.pytest_cache', '.vscode', '.pnp.*', '*.sqlite', '.cache', '.local', '.npm', '.yarn'
)

# Prepare file list variable
$Files = @()

# Attempt to use Git if available
$GitCmd = (Get-Command git -ErrorAction SilentlyContinue)
if ($GitCmd) {
    try {
        Write-Host "Configuring safe.directory for Git (if needed)..."
        & git -C $ScriptDirectory config --global --add safe.directory "$ScriptDirectory" 2>$null
        Write-Host "Using Git to list tracked files in '$projectName'..."
        $Tracked = & git -C $ScriptDirectory ls-files
        Write-Host "Using Git to list untracked .txt files in '$projectName'..."
        $UntrackedTxt = & git -C $ScriptDirectory ls-files --others --exclude-standard -- '*.txt'
        $Files = $Tracked + $UntrackedTxt
    }
    catch {
        Write-Warning "Git error: $($_.Exception.Message) -- falling back to manual .gitignore parsing"
    }
}

# If Git not used or failed, parse .gitignore manually
if (-not $Files) {
    Write-Host "Parsing .gitignore manually in '$projectName'..."
    $GitIgnore = Join-Path $ScriptDirectory '.gitignore'
    $Patterns = @()
    if (Test-Path $GitIgnore) {
        Get-Content $GitIgnore | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith('#')) {
                $raw = $line.TrimEnd('/')
                $esc = [regex]::Escape($raw) -replace '\\*','.*' -replace '\\?','.'
                $pattern = "^.*$($esc -replace '/','[\\/]').*$"
                $Patterns += $pattern
            }
        }
    }
    $Files = Get-ChildItem -Path $ScriptDirectory -Recurse -File |
        Where-Object {
            $rel = $_.FullName.Substring($ScriptDirectory.Length + 1).TrimStart('\', '/')
            -not ($rel -match '^\.git[\\/]') -and
            (-not ($Patterns | ForEach-Object { $rel -match $_ }))
        } | ForEach-Object { $_.FullName.Substring($ScriptDirectory.Length + 1) }
}

# Include explicit files and remove duplicates
$Files += $ExplicitIncludes
$Files = $Files | Select-Object -Unique

# Apply hard exclusions
$Files = $Files | Where-Object {
    $rel = $_
    $exclude = $false
    foreach ($pattern in $HardExclusions) {
        if ($rel -like $pattern) { $exclude = $true; break }
    }
    -not $exclude
}

# Export each file’s contents with headers
foreach ($rel in $Files) {
    $full = Join-Path $ScriptDirectory $rel
    if (Test-Path $full) {
        Add-Content -Path $OutputFile -Value "`r`n`r`n=== $rel ===`r`n`r`n"
        Get-Content -Path $full | Add-Content -Path $OutputFile
        Write-Host "Processed: $rel"
    }
}

Write-Host "Export complete. Output file: $OutputFile"
