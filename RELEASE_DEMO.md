# ExportRepoCode Release System Demo

This document demonstrates how to use the new release system for ExportRepoCode.

## 🚀 Quick Start for Maintainers

### 1. Test Build Locally
```powershell
# Test the build system first
.\build.ps1 -Version "v1.0.0" -SkipExe

# Check the build artifacts
ls build/
```

### 2. Create a Release
```powershell
# Create and push a release tag (triggers GitHub Actions)
.\release.ps1 -Version "v1.0.0"
```

### 3. Monitor Release
- Check GitHub Actions: https://github.com/Chromeninja/ExportRepoCode/actions
- View the release: https://github.com/Chromeninja/ExportRepoCode/releases

## 📦 What Users Get

Each release automatically provides:

### For Windows Users (Easiest)
1. Download `ExportRepoCode.bat`
2. Double-click to run - no technical knowledge needed

### For Power Users
1. Download `ExportRepoCode.ps1` 
2. Run from PowerShell on any platform

### For Enterprise/Automated Installation
1. Download and run `install.ps1`:
```powershell
Invoke-WebRequest -Uri "https://github.com/Chromeninja/ExportRepoCode/releases/latest/download/install.ps1" -OutFile "install.ps1"
.\install.ps1 -AddToPath -CreateDesktopShortcut
```

### For Users Who Prefer Executables
1. Download `ExportRepoCode.exe`
2. Run directly - self-contained Windows application

## 🔧 Technical Details

### Release Workflow
1. **Tag Push**: `git tag v1.0.0 && git push origin v1.0.0`
2. **GitHub Actions**: Automatically builds all formats
3. **Release Creation**: Creates GitHub release with all artifacts
4. **Version Management**: Updates version info in all files

### Build Process
- **PowerShell Script**: Original with version header
- **Batch Wrapper**: Checks for PowerShell, runs script with proper error handling
- **Executable**: Uses ps2exe to create standalone Windows executable
- **Installer**: Downloads and configures all formats with optional PATH/shortcut setup

### File Structure After Release
```
ExportRepoCode-v1.0.0/
├── ExportRepoCode.ps1     # Cross-platform script
├── ExportRepoCode.bat     # Windows wrapper
├── ExportRepoCode.exe     # Standalone executable  
└── install.ps1            # Automated installer
```

## 🎯 Recommendation Answer

**For the original question: "should i do an EXE or bat file or something else"**

**Answer: Do ALL of them!** 

The release system now provides:
1. **BAT file** - Easiest for Windows users (double-click and go)
2. **EXE file** - For users who prefer traditional applications  
3. **PowerShell script** - Most flexible, works everywhere PowerShell runs
4. **Installer** - Professional deployment option

This covers all user preferences and technical requirements, from complete beginners to enterprise deployments.