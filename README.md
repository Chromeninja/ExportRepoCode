# ExportRepoCode

**ExportRepoCode** is a PowerShell script for developers who want to bundle all the important code from a repository into one text file. Ideal for sharing, reviewing, or archiving. The script automatically respects `.gitignore`, skips common noise folders like `node_modules`, and avoids secrets and system files.

## Features

- **Cross-platform:** Works on Windows, macOS (with PowerShell), and WSL.
- **.gitignore-aware:** Uses your repo’s ignore rules or falls back to manual parsing.
- **Automatic noise filtering:** Always skips folders like `node_modules`, `__pycache__`, `.venv`, `.env`, etc.
- **Easy to use:** Just place it in your root folder, run, and pick a project folder.
- **Multiple formats:** Available as PowerShell script, Windows batch file, or standalone executable.

## 📦 Installation & Download

### Quick Install (Recommended)
```powershell
# Download and run the installer
Invoke-WebRequest -Uri "https://github.com/Chromeninja/ExportRepoCode/releases/latest/download/install.ps1" -OutFile "install.ps1"
.\install.ps1 -AddToPath -CreateDesktopShortcut
```

### Manual Download
Download from the [latest release](https://github.com/Chromeninja/ExportRepoCode/releases/latest):

- **🔧 ExportRepoCode.ps1** - Original PowerShell script (cross-platform)
- **🪟 ExportRepoCode.bat** - Windows batch wrapper (double-click to run)
- **📱 ExportRepoCode.exe** - Standalone Windows executable
- **⚡ install.ps1** - Automated installer

## 🚀 Usage

### Windows Users (Easiest)
1. Download **ExportRepoCode.bat** from releases
2. Place it in a folder containing your project subdirectories
3. Double-click to run

### Cross-Platform Users
1. Download **ExportRepoCode.ps1** from releases
2. Place it in a folder containing your project subdirectories  
3. Run: `pwsh ExportRepoCode.ps1` or `powershell ExportRepoCode.ps1`

### Step-by-step Process
1. Place the script in a directory containing project folders
2. Run the script
3. Select which project to export when prompted
4. Get a combined `<projectName>-ALLCODE.txt` file with all your code

## Example Output

The resulting `.txt` file will contain all code, separated by headers like:

=== src/main.py ===

print("Hello, World!")

=== README.md ===


## What gets skipped?

- Dependency folders (`node_modules`, `.venv`, `.yarn`, etc.)
- Build artifacts and cache (`__pycache__`, `.pytest_cache`, `.cache`, etc.)
- Editor config (`.vscode/`, `.idea/`, etc.)
- Log, database, and environment files (`*.log`, `*.env`, `*.sqlite`, etc.)
- System files (`.DS_Store`)
- Secrets (if named like `.env`, `secrets.*`)

You can customize these in the script!

## 🔄 Release Channels & Building

### For Users
- **Stable releases:** Download from [GitHub Releases](https://github.com/Chromeninja/ExportRepoCode/releases)
- **Latest features:** Download the main branch PowerShell script directly

### For Developers
This repository includes automated release management:

#### Creating a Release
```powershell
# Test build locally first
.\release.ps1 -Version "v1.0.0" -TestOnly

# Create and push release tag (triggers GitHub Actions)
.\release.ps1 -Version "v1.0.0"
```

#### Manual Local Build
```powershell
# Build all artifacts locally
.\build.ps1 -Version "v1.0.0"
```

#### Release Formats
Each release automatically creates:
- **ExportRepoCode.ps1** - Cross-platform PowerShell script
- **ExportRepoCode.bat** - Windows batch wrapper  
- **ExportRepoCode.exe** - Standalone Windows executable
- **install.ps1** - Automated installer script

## Contributing

Pull requests and issues are welcome!

