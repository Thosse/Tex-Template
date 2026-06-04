#!/usr/bin/env bash
set -x

# Change directory to the folder where this script lives (bin/)
# and move one level up (..) into the project root folder.
cd "$(dirname "$0")/.."

# Build the Docker image using the Dockerfile in the root folder
docker build -t latex-pipeline .