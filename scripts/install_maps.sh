#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

export WINEPATH="$HOME/Games"
export WINEPREFIX="$WINEPATH/W3Champions"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"

MAP_DIR="$DOCUMENTS/Warcraft III/Maps/W3Champions"

echo "Installing W3Champions maps"
mkdir -p "$MAP_DIR"

for map in "$BASE_DIR"/Maps/W3Champions/*; do
  cp "$map" "$MAP_DIR/"
done
