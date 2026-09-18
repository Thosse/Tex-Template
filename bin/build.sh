#!/usr/bin/env bash

# cd:   Always run relative to the directory where this script lives,
#       ensuring $(pwd) doesn't break if called from elsewhere.
# exit: exit on failure
cd "$(dirname "$0")/.." || exit 1

source bin/detect_engine.sh

# Build the Docker image using the Dockerfile in the root folder
$ENGINE build -t $CONTAINER_NAME .