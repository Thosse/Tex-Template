#!/usr/bin/env bash

CONTAINER_NAME=latex-pipeline


# Change directory to the folder where this script lives (bin/)
# and move one level up (..) into the project root folder.
cd "$(dirname "$0")/.."

# Build the Docker image using the Dockerfile in the root folder
docker build -t $CONTAINER_NAME .