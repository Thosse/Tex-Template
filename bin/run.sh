#!/usr/bin/env bash

# cd:   Always run relative to the directory where this script lives,
#       ensuring $(pwd) doesn't break if called from elsewhere.
# exit: exit on failure
cd "$(dirname "$0")/.." || exit 1

source bin/detect_engine.sh

# Run the container and pass all arguments ("$@") to the build pipeline
$ENGINE run --rm $ENGINE_SPECIFIC_FLAGS \
  --user "$TARGET_UID:$TARGET_GID" \
  -v "$(pwd)":/home/latexuser/app:Z \
  $CONTAINER_NAME make "$@"