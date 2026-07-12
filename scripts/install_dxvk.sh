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
