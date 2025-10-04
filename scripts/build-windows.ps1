# Build Windows release version of System Info App
# This script replicates the GitHub Actions workflow for local testing
#
# Usage:
#   .\scripts\build-windows.ps1          # Standard build
#   .\scripts\build-windows.ps1 -Clean   # Clean build (removes all previous artifacts)

param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "`n▶ $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Banner
Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "  System Info App - Windows Release Build" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

# Step 1: Check prerequisites
Write-Step "Checking prerequisites..."

$prerequisites = @{
    "cmake" = "CMake (https://cmake.org/download/)"
    "node" = "Node.js 20.x or later (https://nodejs.org/)"
    "rustc" = "Rust (https://rustup.rs/)"
    "cargo" = "Rust Cargo (comes with Rust)"
}

$missingTools = @()

foreach ($tool in $prerequisites.Keys) {
    if (Test-CommandExists $tool) {
        Write-Success "$tool is installed"
    } else {
        Write-Error "$tool is NOT installed"
        $missingTools += $prerequisites[$tool]
    }
}

if ($missingTools.Count -gt 0) {
    Write-Error "`nMissing required tools:`n"
    $missingTools | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host "`nPlease install missing tools and try again.`n" -ForegroundColor Yellow
    exit 1
}

# Check Rust target
Write-Step "Checking Rust target..."
$rustTargets = rustup target list --installed
if ($rustTargets -notcontains "x86_64-pc-windows-msvc") {
    Write-ColorOutput "Installing x86_64-pc-windows-msvc target..." "Yellow"
    rustup target add x86_64-pc-windows-msvc
}
Write-Success "Rust target x86_64-pc-windows-msvc is installed"

# Step 2: Clean previous builds if requested
if ($Clean) {
    Write-Step "Cleaning previous builds..."
    & "$PSScriptRoot\clean.ps1"
}

# Step 3: Build C++ library
Write-Step "Building C++ library..."
Push-Location cpp_cross_platform

try {
    # Create build directory
    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
    }

    Push-Location build

    try {
        # Generate build files
        Write-ColorOutput "  Generating CMake build files..." "Gray"
        cmake .. 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "CMake generation failed"
        }

        # Build in Release mode
        Write-ColorOutput "  Compiling C++ library in Release mode..." "Gray"
        cmake --build . --config Release
        if ($LASTEXITCODE -ne 0) {
            throw "C++ library build failed"
        }

        # Verify DLL was created
        $dllPath = "bin\Release\systemapi.dll"
        if (-not (Test-Path $dllPath)) {
            throw "systemapi.dll not found at $dllPath"
        }
        Write-Success "C++ library built successfully"

        # Copy DLL to Tauri lib directory
        Write-ColorOutput "  Copying systemapi.dll to src-tauri/lib/..." "Gray"
        $targetDir = "..\..\src-tauri\lib"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }
        Copy-Item $dllPath $targetDir -Force
        Write-Success "Copied systemapi.dll to src-tauri/lib/"

    } finally {
        Pop-Location
    }

} finally {
    Pop-Location
}

# Step 4: Install npm dependencies
Write-Step "Installing npm dependencies..."
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install failed"
    exit 1
}
Write-Success "npm dependencies installed"

# Step 5: Build frontend
Write-Step "Building frontend (TypeScript + Vite)..."
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Frontend build failed"
    exit 1
}
Write-Success "Frontend built successfully"

# Step 6: Build Tauri app
Write-Step "Building Tauri release bundle..."
Write-ColorOutput "  This may take several minutes..." "Yellow"
npm run tauri build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tauri build failed"
    exit 1
}
Write-Success "Tauri build completed"

# Step 7: Report build artifacts
Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "  Build Complete!" "Green"
Write-ColorOutput "========================================`n" "Cyan"

$bundlePath = "src-tauri\target\release\bundle"
Write-ColorOutput "Build artifacts location:" "Cyan"
Write-Host "  $bundlePath`n" -ForegroundColor Yellow

if (Test-Path "$bundlePath\msi") {
    Write-ColorOutput "MSI Installer:" "Cyan"
    Get-ChildItem "$bundlePath\msi\*.msi" | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor Green
    }
}

if (Test-Path "$bundlePath\nsis") {
    Write-ColorOutput "`nNSIS Installer:" "Cyan"
    Get-ChildItem "$bundlePath\nsis\*.exe" | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor Green
    }
}

Write-Host ""
