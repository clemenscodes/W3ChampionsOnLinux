#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

export WINEPATH="$HOME/Games"
export WINEPREFIX="$WINEPATH/W3Champions"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

echo "Setting up wine prefix"

mkdir -p "$WINEPREFIX"
wineboot --init
winetricks -q dxvk

echo "Installing DXVK DLLs"
for dll in "$BASE_DIR"/dxvk/x64/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/system32/"
done
for dll in "$BASE_DIR"/dxvk/x32/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/syswow64/"
done
