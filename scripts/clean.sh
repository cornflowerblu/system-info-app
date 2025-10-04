#!/bin/bash
# Clean build artifacts for System Info App
# Usage:
#   ./scripts/clean.sh          # Clean build artifacts
#   ./scripts/clean.sh --all    # Deep clean (includes node_modules)

set -e

ALL_FLAG=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --all)
            ALL_FLAG=true
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
        "gray")
            echo -e "\033[0;90m${message}\033[0m"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

remove_directory_if_exists() {
    local path=$1
    local description=$2

    if [ -d "$path" ]; then
        color_output "[*] Removing $description..." "yellow"
        rm -rf "$path"
        color_output "[OK] Removed $description" "green"
    else
        color_output "[INFO] $description not found (already clean)" "gray"
    fi
}

color_output "" "cyan"
color_output "========================================" "cyan"
color_output "  System Info App - Clean Build Artifacts" "cyan"
color_output "========================================" "cyan"
color_output "" "cyan"

# Clean C++ build directory
remove_directory_if_exists "cpp_cross_platform/build" "C++ build directory"

# Clean Tauri library directory
remove_directory_if_exists "src-tauri/lib" "Tauri library directory"

# Clean Tauri target directory
remove_directory_if_exists "src-tauri/target" "Tauri build artifacts"

# Clean frontend dist directory
remove_directory_if_exists "dist" "Frontend build artifacts"

# Deep clean: node_modules
if [ "$ALL_FLAG" = true ]; then
    color_output "" "yellow"
    color_output "[WARNING] Deep clean mode enabled" "yellow"
    remove_directory_if_exists "node_modules" "Node modules"
    color_output "" "cyan"
    color_output "[INFO] Remember to run 'npm install' before next build" "cyan"
fi

color_output "" "green"
color_output "[OK] Clean complete!" "green"
color_output "" "green"
