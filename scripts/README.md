# Build Scripts Documentation

This directory contains scripts for building release versions of the System Info App locally. These scripts replicate the GitHub Actions CI/CD workflow, allowing you to test and debug builds before pushing to GitHub.

## Overview

- **`build-windows.ps1`** - Build Windows release bundle (MSI/NSIS installers)
- **`build-macos.sh`** - Build macOS release bundle (DMG/App bundle)
- **`clean.ps1`** - Clean Windows build artifacts
- **`clean.sh`** - Clean macOS build artifacts

## Prerequisites

### Windows

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **Visual Studio** | 2019/2022 | [Download](https://visualstudio.microsoft.com/) with C++ Desktop Development |
| **CMake** | 3.15+ | `winget install Kitware.CMake` |
| **Node.js** | 20.x | [Download](https://nodejs.org/) |
| **Rust** | stable | [rustup.rs](https://rustup.rs/) |
| **PowerShell** | 5.1+ | Included with Windows |

**Verify installation:**
```powershell
cmake --version
node --version
rustc --version
cargo --version
```

**Add required Rust target:**
```powershell
rustup target add x86_64-pc-windows-msvc
```

### macOS

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| **Xcode CLI Tools** | Latest | `xcode-select --install` |
| **Homebrew** | Latest | [brew.sh](https://brew.sh/) |
| **CMake** | 3.15+ | `brew install cmake` |
| **Node.js** | 20.x | `brew install node@20` |
| **Rust** | stable | [rustup.rs](https://rustup.rs/) |

**Verify installation:**
```bash
xcode-select -p
cmake --version
node --version
rustc --version
cargo --version
```

**Add required Rust target:**
```bash
rustup target add aarch64-apple-darwin
```

**Optional: Code Signing**
- Apple Developer ID Application certificate
- Apple Developer ID Installer certificate
- Installed in System Keychain

## Usage

### Windows Build

**Standard build:**
```powershell
.\scripts\build-windows.ps1
```

**Clean build (removes all previous artifacts):**
```powershell
.\scripts\build-windows.ps1 -Clean
```

**Or use npm script:**
```powershell
npm run build:release:win
```

**Build output:**
```
src-tauri/target/release/bundle/
├── msi/              # Windows Installer (.msi)
└── nsis/             # NSIS Installer (.exe)
```

### macOS Build

**Standard build (no code signing):**
```bash
./scripts/build-macos.sh
```

**Clean build:**
```bash
./scripts/build-macos.sh --clean
```

**Build with code signing:**
```bash
./scripts/build-macos.sh --sign
```

**Or use npm script:**
```bash
npm run build:release:mac
```

**Build output:**
```
src-tauri/target/aarch64-apple-darwin/release/bundle/
├── dmg/              # macOS Disk Image (.dmg)
└── macos/            # Application Bundle (.app)
```

### Cleaning Build Artifacts

**Windows:**
```powershell
# Clean build artifacts
.\scripts\clean.ps1

# Deep clean (includes node_modules)
.\scripts\clean.ps1 -All
```

**macOS:**
```bash
# Clean build artifacts
./scripts/clean.sh

# Deep clean (includes node_modules)
./scripts/clean.sh --all
```

**Or use npm scripts:**
```bash
npm run clean:win   # Windows
npm run clean:mac   # macOS
```

## Build Process Flow

Both scripts follow the same sequence:

1. **Check Prerequisites** - Verify all required tools are installed
2. **Clean (Optional)** - Remove previous build artifacts if `--clean` flag is used
3. **Build C++ Library**
   - Create `cpp_cross_platform/build/` directory
   - Run CMake configuration
   - Compile in Release mode
   - Verify library file was created (`systemapi.dll` or `libsystemapi.dylib`)
   - Copy library to `src-tauri/lib/`
4. **Install Dependencies** - Run `npm install`
5. **Build Frontend**
   - Run TypeScript compilation (`tsc`)
   - Run Vite build
6. **Build Tauri App** - Create platform-specific bundles
7. **Report Results** - Display artifact locations

## Differences from CI/CD

| Aspect | CI/CD (GitHub Actions) | Local Build Scripts |
|--------|----------------------|-------------------|
| **Environment** | Fresh VM on each run | Your development machine |
| **Code Signing (macOS)** | Always signs with Developer ID | Optional (`--sign` flag) |
| **Clean State** | Always clean | Incremental by default (`--clean` flag available) |
| **Rust Version** | Pinned in workflow | Whatever version you have installed |
| **Build Speed** | ~10-15 minutes | ~5-10 minutes (incremental builds faster) |
| **Artifacts** | Uploaded to GitHub Releases | Remain in `target/` directories |
| **Debugging** | View logs after workflow completes | Real-time output |

## Troubleshooting

### Windows Issues

#### CMake not found
```powershell
# Install via winget
winget install Kitware.CMake

# Or download from https://cmake.org/download/
```

#### Missing Visual Studio C++ tools
```powershell
# Install Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# Then add "Desktop development with C++" workload
```

#### Rust target missing
```powershell
rustup target add x86_64-pc-windows-msvc
```

#### PowerShell execution policy error
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### DLL not found after build
- Ensure CMake build completed successfully
- Check `cpp_cross_platform/build/bin/Release/systemapi.dll` exists
- Verify copy step didn't fail
- Try clean build: `.\scripts\build-windows.ps1 -Clean`

### macOS Issues

#### Xcode Command Line Tools not installed
```bash
xcode-select --install
```

#### CMake not found
```bash
brew install cmake
```

#### Rust target missing
```bash
rustup target add aarch64-apple-darwin
```

#### Permission denied when running script
```bash
chmod +x scripts/build-macos.sh
chmod +x scripts/clean.sh
```

#### dylib not found after build
- Ensure CMake build completed successfully
- Check `cpp_cross_platform/build/lib/libsystemapi.dylib` exists
- Verify copy step didn't fail
- Try clean build: `./scripts/build-macos.sh --clean`

#### Code signing errors
Local builds can skip code signing:
```bash
# Build without signing (default)
./scripts/build-macos.sh
```

If you need signed builds locally:
1. Ensure Developer ID certificates are in your Keychain
2. Unlock keychain: `security unlock-keychain`
3. Build with signing: `./scripts/build-macos.sh --sign`

### Common Issues (All Platforms)

#### Out of disk space
Run deep clean to remove `node_modules`:
```bash
# Windows
.\scripts\clean.ps1 -All
npm install

# macOS
./scripts/clean.sh --all
npm install
```

#### Build fails after dependency update
```bash
# Clean everything and rebuild
npm run clean:win  # or clean:mac
rm -rf node_modules  # macOS/Linux
Remove-Item -Recurse node_modules  # Windows
npm install
npm run build:release:win  # or build:release:mac
```

#### TypeScript compilation errors
```bash
# Ensure you have the latest TypeScript
npm install

# Check for type errors
npm run build
```

## Code Signing (macOS Only)

### Local Development
By default, local builds **skip code signing** to allow testing without certificates:
```bash
./scripts/build-macos.sh
```

The app will run on your local machine but won't be distributable.

### Signed Builds
If you have Developer ID certificates:
```bash
./scripts/build-macos.sh --sign
```

**Requirements:**
- Developer ID Application certificate in Keychain
- Developer ID Installer certificate in Keychain
- Keychain unlocked during build

**Note:** Signed builds are NOT notarized locally. For notarization, use the GitHub Actions workflow which includes Apple notarization service.

## Testing Built Apps

### Windows
After build completes, test the installer:
```powershell
# Install using MSI
cd src-tauri\target\release\bundle\msi
.\*.msi

# Or use NSIS installer
cd ..\nsis
.\*.exe
```

### macOS
After build completes, test the app:
```bash
# Mount DMG and test
open src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/*.dmg

# Or directly run app bundle
open src-tauri/target/aarch64-apple-darwin/release/bundle/macos/*.app
```

## Performance Tips

1. **Use incremental builds** - Don't use `--clean` unless necessary
2. **Keep `node_modules`** - Only deep clean when updating dependencies
3. **Build locally first** - Catch errors before pushing to CI
4. **Use SSD for builds** - Much faster compile times
5. **Close resource-heavy apps** - Free up RAM and CPU during builds

## Related Documentation

- [Main README](../README.md) - Project overview and development setup
- [Technical Design Overview](https://rurich.atlassian.net/wiki/spaces/SIAW/pages/98802) - Architecture details
- [GitHub Actions Workflow](../.github/workflows/release.yml) - CI/CD configuration
- [Tauri Configuration](../src-tauri/tauri.conf.json) - App bundling settings

## Getting Help

If you encounter issues not covered here:
1. Check the Tauri documentation: https://tauri.app/
2. Review GitHub Actions workflow logs for CI build differences
3. Search Tauri GitHub issues: https://github.com/tauri-apps/tauri/issues
4. Ask in the project Slack channel or create a Jira ticket
