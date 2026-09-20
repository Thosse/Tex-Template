#!/usr/bin/env bash

################################################################################
CONTAINER_NAME="localhost/latex-pipeline"

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