#!/usr/bin/env bash
set -x

# Always run relative to the directory where this script lives, 
# ensuring $(pwd) doesn't break if called from elsewhere.
cd "$(dirname "$0")/.."

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/home/latexuser/app \
  latex-pipeline