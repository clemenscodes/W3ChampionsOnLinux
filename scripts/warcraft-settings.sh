#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PREFERENCES_FILE="$PROJECT_ROOT/War3Preferences.txt"
CUSTOM_KEYS_FILE="$PROJECT_ROOT/CustomKeys.txt"
WINEPATH="$HOME/Games"
WINEPREFIX="$WINEPATH/W3Champions"
DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

mkdir -p "$WARCRAFT_CONFIG_HOME/CustomKeyBindings"

echo "Installing Warcraft III settings..."
cat "$PREFERENCES_FILE" > "$WARCRAFT_CONFIG_HOME/War3Preferences.txt"
echo "Installing Warcraft III hotkeys..."
cat "$CUSTOM_KEYS_FILE" > "$WARCRAFT_CONFIG_HOME/CustomKeyBindings/CustomKeys.txt"
