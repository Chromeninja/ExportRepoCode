# ExportRepoCode

**ExportRepoCode** is a PowerShell script for developers who want to bundle all the important code from a repository into one text file. Ideal for sharing, reviewing, or archiving. The script automatically respects `.gitignore`, skips common noise folders like `node_modules`, and avoids secrets and system files.

## Features

- **Cross-platform:** Works on Windows, macOS (with PowerShell), and WSL.
- **.gitignore-aware:** Uses your repo’s ignore rules or falls back to manual parsing.
- **Automatic noise filtering:** Always skips folders like `node_modules`, `__pycache__`, `.venv`, `.env`, etc.
- **Easy to use:** Just place it in your root folder, run, and pick a project folder.

## Usage

1. Download [`ExportRepoCode.ps1`](ExportRepoCode.ps1) into your **host** directory that contains your projects.
2. Open a PowerShell terminal in that directory.
3. Run:
    ```powershell
    .\\ExportRepoCode.ps1
    ```
4. Pick the project folder when prompted.
5. Get a file named `<projectName>-ALLCODE.txt` containing all code from the repo.

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

## Contributing

Pull requests and issues are welcome!

