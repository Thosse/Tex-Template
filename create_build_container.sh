#!/usr/bin/env bash

# cd:   Always run relative to the directory where this script lives,
#       ensuring $(pwd) doesn't break if called from elsewhere.
# exit: exit on failure
cd "$(dirname "$0")/.." || exit 1

source bin/set_build_environment.sh

# Build the Docker image using the Dockerfile inside bin/ but context is root (.)
$ENGINE build -f bin/Dockerfile -t $CONTAINER_NAME .