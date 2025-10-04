# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A cross-platform system information application built with **Tauri v2**, **React**, **TypeScript**, and **C++**. The architecture demonstrates **FFI (Foreign Function Interface)** integration across multiple layers:

- **Frontend**: React + TypeScript (UI layer)
- **Backend**: Rust via Tauri (application framework)
- **System Library**: Cross-platform C++ library loaded dynamically via `libloading`

The C++ library provides low-level system operations (computer name, memory info, process ID, factorial calculation) that are exposed through Rust to the React frontend.

## Common Development Commands

### Development
```bash
# Start dev server (works without C++ library - will show errors but UI functions)
npm run tauri dev

# Build frontend only
npm run build
```

### C++ Library Development
```bash
# Build the C++ library (required for full functionality)
cd cpp_cross_platform
mkdir build
cd build
cmake ..
cmake --build . --config Release

# The library will be built to:
# - Windows: cpp_cross_platform/build/bin/Release/systemapi.dll
# - macOS: cpp_cross_platform/build/lib/libsystemapi.dylib
# - Linux: cpp_cross_platform/build/lib/libsystemapi.so
```

### Production Build
```bash
# Build the Tauri application
npm run tauri build
```

## Architecture

### FFI Integration Flow
1. **C++ Layer** (`cpp_cross_platform/`):
   - Header: `include/systemapi.h` - defines FFI-compatible C ABI functions
   - Implementation: `src/systemapi.cpp` - platform-specific implementations
   - Exports: `GetComputerNameString`, `GetTotalPhysicalMemory`, `GetCurrentProcessID`, `CalculateFactorial`

2. **Rust Layer** (`src-tauri/src/lib.rs`):
   - Uses `libloading` crate to dynamically load the C++ shared library
   - Loads library from multiple paths (see `load_cpp_library()` function)
   - Exposes Tauri commands that call into C++ via FFI
   - State management: `CppLibrary` struct with `Mutex<Option<Library>>`

3. **React Layer** (`src/`):
   - Calls Tauri commands via `@tauri-apps/api/core`
   - Example: `invoke<string>("get_computer_name")`

### Library Loading Strategy
The Rust code searches for the C++ library in this order:
1. Same directory as executable
2. Windows: `resources/` folder next to exe
3. macOS: `../Resources/` (app bundle structure)
4. Development path: `../cpp_cross_platform/build/...`

### CI/CD (GitHub Actions)
The `.github/workflows/release.yml` workflow:
- Builds C++ library for each platform (Windows x64, macOS ARM64)
- Copies library to `src-tauri/lib/` before Tauri build
- On macOS: Code signs the library with Developer ID
- Creates draft releases on version tags (`v*`)

## Key Implementation Details

### Tauri Commands
All Tauri commands in `src-tauri/src/lib.rs` follow this pattern:
- Take `State<CppLibrary>` as parameter
- Lock the mutex to access the library
- Use `Symbol<FunctionTypeFn>` to get function pointer
- Call unsafe FFI function
- Return `Result<T, String>` for error handling

### C++ Library Notes
- Uses `extern "C"` to prevent name mangling
- Platform-specific export macros (`SYSTEMAPI_API`)
- CMake builds shared library (`.dll`/`.dylib`/`.so`)
- Windows: `WINDOWS_EXPORT_ALL_SYMBOLS` enabled

### Frontend Error Handling
- If C++ library fails to load, app shows error UI with retry button
- All system info calls are wrapped in try-catch
- Graceful degradation: UI works without library (shows errors)

## Platform-Specific Requirements

### Windows
- Visual Studio or Build Tools required
- CMake generates Visual Studio project files

### macOS
- Xcode Command Line Tools
- For distribution: Code signing certificates required (Developer ID Application & Installer)
- Library must be signed with hardened runtime for notarization

### Linux
- GCC/G++ compiler
- GTK 3 and WebKit2GTK development packages
- CMake for building C++ library

## Project Structure

- `src/` - React frontend
- `src-tauri/` - Tauri Rust backend
  - `src/lib.rs` - Main application logic and FFI integration
  - `src/main.rs` - Entry point (minimal, calls lib.rs)
  - `build.rs` - Tauri build script
- `cpp_cross_platform/` - C++ system library
  - `include/` - Header files
  - `src/` - Implementation
  - `CMakeLists.txt` - CMake build configuration
- `.github/workflows/` - CI/CD automation

## Testing the C++ Integration

After building the C++ library, verify integration:
1. Start dev server: `npm run tauri dev`
2. Check console for "✓ C++ library loaded successfully!"
3. UI should display computer name, memory, and process ID
4. Factorial calculator should work without errors
