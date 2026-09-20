#!/usr/bin/env bash

################################################################################
CONTAINER_NAME="localhost/latex-pipeline"

################################################################################
# --- Asserts for required host project structure ---
# Determine the host project root (one directory up from where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Assert that the submodule is housed exactly inside a folder named 'bin'
if [ "$(basename "$SCRIPT_DIR")" != "bin" ]; then
    echo "Error: The build engine submodule must be placed in a directory named 'bin'." >&2
    echo "Current location: '$SCRIPT_DIR'" >&2
    echo "Pathing will fail otherwise. Please rename the directory to 'bin'." >&2
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/src" ]; then
    echo "Error: Required source directory '$PROJECT_ROOT/src' not found." >&2
    echo "Please ensure the build engine submodule is placed correctly within the host project." >&2
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/src/main.tex" ]; then
    echo "Error: Required entry point '$PROJECT_ROOT/src/main.tex' not found." >&2
    exit 1
fi

################################################################################
# Check for podman first (preferred), then fallback to docker
if command -v podman >/dev/null 2>&1; then
    ENGINE="podman"
    ENGINE_SPECIFIC_FLAGS="--userns=keep-id"
elif command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
    ENGINE_SPECIFIC_FLAGS=""
else
    echo "Error: Neither Podman nor Docker was found on this system." >&2
    exit 1
fi

# Verify if the user has permission to run the engine without sudo
if ! $ENGINE info >/dev/null 2>&1; then
    echo "Error: Permission denied. $ENGINE requires superuser rights or the daemon is not running." >&2
    echo "Please configure rootless Podman/Docker or ensure you have the correct user permissions." >&2
    exit 1
fi

################################################################################
# Actual user and group ID detection, bypassing sudo's root ID
if [ -n "$SUDO_USER" ]; then
    TARGET_UID=$(id -u "$SUDO_USER")
    TARGET_GID=$(id -g "$SUDO_USER")
else
    TARGET_UID=$(id -u)
    TARGET_GID=$(id -g)
fi

################################################################################
# Export the variables so calling scripts can use it
export CONTAINER_NAME
export ENGINE
export ENGINE_SPECIFIC_FLAGS
export TARGET_UID
export TARGET_GID