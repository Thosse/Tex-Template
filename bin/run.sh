#!/usr/bin/env bash

CONTAINER_NAME=latex-pipeline

# cd:   Always run relative to the directory where this script lives,
#       ensuring $(pwd) doesn't break if called from elsewhere.
# exit: exit on failure
cd "$(dirname "$0")/.." || exit 1


# Check for podman first (preferred), then fallback to docker
if command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
elif command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
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

# Run the container and pass all arguments ("$@") to the build pipeline
$ENGINE run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/home/latexuser/app:Z \
  $CONTAINER_NAME make "$@"