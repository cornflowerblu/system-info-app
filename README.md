# System Info App

A cross-platform system information application built with Tauri, React, and TypeScript. The app includes a C++ library for system-level operations.

## Features

- Computer name retrieval
- Total physical memory information  
- Current process ID
- Factorial calculator

## Architecture

- **Frontend**: React + TypeScript + Vite
- **Backend**: Rust (Tauri)
- **System Library**: C++ cross-platform library

## Development Setup

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Rust](https://rustup.rs/)
- [CMake](https://cmake.org/) (for C++ library)
- C++ compiler (Visual Studio on Windows, Xcode on macOS, GCC on Linux)

### Quick Start

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start development server:
   ```bash
   npm run tauri dev
   ```

   **Note**: The app will work without the C++ library - system functions will show error messages but the UI will still function.

### Building with C++ Library (Optional)

If you want full functionality with the C++ library:

1. Build the C++ library:
   ```bash
   cd cpp_cross_platform
   mkdir build
   cd build
   cmake ..
   cmake --build . --config Release
   ```

2. The Tauri app will automatically detect and load the library if available.

## Production Build

```bash
npm run tauri build
```

The GitHub Actions workflow automatically builds the C++ library for each target platform.

## Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)
