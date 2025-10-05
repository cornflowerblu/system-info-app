#!/bin/bash
# Build macOS release version of System Info App
# This script replicates the GitHub Actions workflow for local testing
#
# Usage:
#   ./scripts/build-macos.sh          # Standard build (no code signing)
#   ./scripts/build-macos.sh --clean  # Clean build
#   ./scripts/build-macos.sh --sign   # Build with code signing

set -e

CLEAN_FLAG=false
SIGN_FLAG=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN_FLAG=true
            shift
            ;;
        --sign)
            SIGN_FLAG=true
            shift
            ;;
    esac
done

# Color output functions
color_output() {
    local message=$1
    local color=$2

    case $color in
        "cyan")
            echo -e "\033[0;36m${message}\033[0m"
            ;;
        "green")
            echo -e "\033[0;32m${message}\033[0m"
            ;;
        "yellow")
            echo -e "\033[0;33m${message}\033[0m"
            ;;
        "red")
            echo -e "\033[0;31m${message}\033[0m"
            ;;
        "gray")
            echo -e "\033[0;90m${message}\033[0m"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

print_step() {
    color_output "" "cyan"
    color_output "▶ $1" "cyan"
}

print_success() {
    color_output "✓ $1" "green"
}

print_error() {
    color_output "✗ $1" "red"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Banner
color_output "" "cyan"
color_output "========================================" "cyan"
color_output "  System Info App - macOS Release Build" "cyan"
color_output "========================================" "cyan"
color_output "" "cyan"

# Step 1: Check prerequisites
print_step "Checking prerequisites..."

MISSING_TOOLS=()

# Check for Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
    print_error "Xcode Command Line Tools are NOT installed"
    MISSING_TOOLS+=("Xcode Command Line Tools (run: xcode-select --install)")
else
    print_success "Xcode Command Line Tools installed"
fi

# Check CMake
if command_exists cmake; then
    print_success "cmake is installed"
else
    print_error "cmake is NOT installed"
    MISSING_TOOLS+=("CMake (run: brew install cmake)")
fi

# Check Node.js
if command_exists node; then
    print_success "node is installed"
else
    print_error "node is NOT installed"
    MISSING_TOOLS+=("Node.js 20.x or later (https://nodejs.org/)")
fi

# Check Rust
if command_exists rustc; then
    print_success "rustc is installed"
else
    print_error "rustc is NOT installed"
    MISSING_TOOLS+=("Rust (https://rustup.rs/)")
fi

# Check Cargo
if command_exists cargo; then
    print_success "cargo is installed"
else
    print_error "cargo is NOT installed"
    MISSING_TOOLS+=("Rust Cargo (comes with Rust)")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error ""
    print_error "Missing required tools:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    color_output "Please install missing tools and try again." "yellow"
    exit 1
fi

# Check Rust target
print_step "Checking Rust target..."
if rustup target list --installed | grep -q "aarch64-apple-darwin"; then
    print_success "Rust target aarch64-apple-darwin is installed"
else
    color_output "Installing aarch64-apple-darwin target..." "yellow"
    rustup target add aarch64-apple-darwin
    print_success "Rust target aarch64-apple-darwin installed"
fi

# Step 2: Clean previous builds if requested
if [ "$CLEAN_FLAG" = true ]; then
    print_step "Cleaning previous builds..."
    bash "$(dirname "$0")/clean.sh"
fi

# Step 3: Build C++ library
print_step "Building C++ library..."
cd cpp_cross_platform

# Create build directory
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# Generate build files
color_output "  Generating CMake build files..." "gray"
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 .. >/dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "CMake generation failed"
    exit 1
fi

# Build in Release mode
color_output "  Compiling C++ library in Release mode..." "gray"
cmake --build . --config Release
if [ $? -ne 0 ]; then
    print_error "C++ library build failed"
    exit 1
fi

# Verify dylib was created
DYLIB_PATH="lib/libsystemapi.dylib"
if [ ! -f "$DYLIB_PATH" ]; then
    print_error "libsystemapi.dylib not found at $DYLIB_PATH"
    exit 1
fi
print_success "C++ library built successfully"

# Copy dylib to Tauri lib directory
color_output "  Copying libsystemapi.dylib to src-tauri/lib/..." "gray"
TARGET_DIR="../../src-tauri/lib"
mkdir -p "$TARGET_DIR"
cp "$DYLIB_PATH" "$TARGET_DIR/"
print_success "Copied libsystemapi.dylib to src-tauri/lib/"

cd ../..

# Step 4: Code signing (optional)
if [ "$SIGN_FLAG" = true ]; then
    print_step "Signing C++ library..."

    # If running in CI (APPLE_APP_CERTIFICATE env var exists), import certificate first
    if [ -n "$APPLE_APP_CERTIFICATE" ]; then
        color_output "  Detected CI environment - importing certificates..." "gray"

        # Create temporary keychain
        KEYCHAIN_PATH=$(mktemp -d)/signing.keychain-db
        KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
        security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

        # Set keychain settings and make it default
        security default-keychain -s "$KEYCHAIN_PATH"
        security set-keychain-settings -t 3600 -u "$KEYCHAIN_PATH"
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

        # Import certificate from base64 env var
        CERT_PATH=$(mktemp)
        echo -n "$APPLE_APP_CERTIFICATE" | base64 --decode > "$CERT_PATH"
        security import "$CERT_PATH" -P "$APPLE_APP_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"

        # Append to keychain search list (don't replace)
        EXISTING_KEYCHAINS=$(security list-keychains -d user | sed 's/"//g' | tr '\n' ' ')
        security list-keychain -d user -s "$KEYCHAIN_PATH" $EXISTING_KEYCHAINS

        # Allow codesign to access the keychain
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

        # Debug: List all identities in the keychain
        color_output "  Identities in keychain:" "gray"
        security find-identity -v "$KEYCHAIN_PATH"

        # Clean up temp cert file
        rm "$CERT_PATH"

        print_success "Certificates imported to temporary keychain"

        # Find identity from the keychain we just created
        APP_IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')
    else
        # Find the Developer ID Application certificate from default keychain (local dev)
        APP_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')
    fi

    # Use the identity we found
    if [ -n "$APPLE_APP_CERTIFICATE" ] && [ -n "$APP_IDENTITY" ]; then
        # In CI, identity found from imported cert
        true
    elif [ -z "$APPLE_APP_CERTIFICATE" ]; then
        # Local dev - already searched above
        true
    fi

    if [ -z "$APP_IDENTITY" ]; then
        color_output "⚠ Warning: No Developer ID Application certificate found" "yellow"
        color_output "  Skipping code signing (local builds can run without signing)" "yellow"
    else
        color_output "  Using identity: $APP_IDENTITY" "gray"

        # Export identity for Tauri to use during app bundle signing
        export APPLE_SIGNING_IDENTITY="$APP_IDENTITY"

        # Sign the dylib with hardened runtime and timestamp
        codesign --force --sign "$APP_IDENTITY" \
            --timestamp \
            --options runtime \
            src-tauri/lib/libsystemapi.dylib

        # Verify the signature
        codesign -vvv --deep --strict src-tauri/lib/libsystemapi.dylib
        print_success "C++ library signed successfully"
    fi
else
    color_output "  Skipping code signing (use --sign flag if needed)" "gray"
fi

# Step 5: Install npm dependencies
print_step "Installing npm dependencies..."
npm install >/dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "npm install failed"
    exit 1
fi
print_success "npm dependencies installed"

# Step 6: Build frontend
print_step "Building frontend (TypeScript + Vite)..."
npm run build
if [ $? -ne 0 ]; then
    print_error "Frontend build failed"
    exit 1
fi
print_success "Frontend built successfully"

# Step 7: Build Tauri app
print_step "Building Tauri release bundle..."
color_output "  This may take several minutes..." "yellow"
npm run tauri build -- --target aarch64-apple-darwin
if [ $? -ne 0 ]; then
    print_error "Tauri build failed"
    exit 1
fi
print_success "Tauri build completed"

# Step 8: Report build artifacts
color_output "" "cyan"
color_output "========================================" "cyan"
color_output "  Build Complete!" "green"
color_output "========================================" "cyan"
color_output "" "cyan"

BUNDLE_PATH="src-tauri/target/aarch64-apple-darwin/release/bundle"
color_output "Build artifacts location:" "cyan"
echo "  $BUNDLE_PATH"
echo ""

if [ -d "$BUNDLE_PATH/dmg" ]; then
    color_output "DMG Installer:" "cyan"
    find "$BUNDLE_PATH/dmg" -name "*.dmg" -exec echo "  {}" \;
fi

if [ -d "$BUNDLE_PATH/macos" ]; then
    color_output "" "cyan"
    color_output "Application Bundle:" "cyan"
    find "$BUNDLE_PATH/macos" -name "*.app" -maxdepth 1 -exec echo "  {}" \;
fi

echo ""
