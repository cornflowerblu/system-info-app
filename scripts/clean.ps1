# Clean build artifacts for System Info App
# Usage:
#   .\scripts\clean.ps1          # Clean build artifacts
#   .\scripts\clean.ps1 -All     # Deep clean (includes node_modules)

param(
    [switch]$All
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Remove-DirectoryIfExists {
    param(
        [string]$Path,
        [string]$Description
    )

    if (Test-Path $Path) {
        Write-ColorOutput "[*] Removing $Description..." "Yellow"
        Remove-Item -Path $Path -Recurse -Force
        Write-ColorOutput "[OK] Removed $Description" "Green"
    } else {
        Write-ColorOutput "[INFO] $Description not found (already clean)" "Gray"
    }
}

Write-ColorOutput "" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "  System Info App - Clean Build Artifacts" "Cyan"
Write-ColorOutput "========================================" "Cyan"
Write-ColorOutput "" "Cyan"

# Clean C++ build directory
Remove-DirectoryIfExists "cpp_cross_platform\build" "C++ build directory"

# Clean Tauri library directory
Remove-DirectoryIfExists "src-tauri\lib" "Tauri library directory"

# Clean Tauri target directory
Remove-DirectoryIfExists "src-tauri\target" "Tauri build artifacts"

# Clean frontend dist directory
Remove-DirectoryIfExists "dist" "Frontend build artifacts"

# Deep clean: node_modules
if ($All) {
    Write-ColorOutput "" "Yellow"
    Write-ColorOutput "[WARNING] Deep clean mode enabled" "Yellow"
    Remove-DirectoryIfExists "node_modules" "Node modules"
    Write-ColorOutput "" "Cyan"
    Write-ColorOutput "[INFO] Remember to run 'npm install' before next build" "Cyan"
}

Write-ColorOutput "" "Green"
Write-ColorOutput "[OK] Clean complete!" "Green"
Write-ColorOutput "" "Green"
