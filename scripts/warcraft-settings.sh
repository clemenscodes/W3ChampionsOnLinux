#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PREFERENCES_FILE="$PROJECT_ROOT/War3Preferences.txt"
CUSTOM_KEYS_FILE="$PROJECT_ROOT/CustomKeys.txt"
BATCHFILE="$PROJECT_ROOT/W3Champions.bat"
WINEPATH="$HOME/Games"
WINEPREFIX="$WINEPATH/W3Champions"
DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
W3CHAMPIONS_HOME="$PROGRAM_FILES/W3Champions"
WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

mkdir -p "$WARCRAFT_CONFIG_HOME/CustomKeyBindings"

echo "Installing Warcraft III settings..."
cp "$PREFERENCES_FILE" "$WARCRAFT_CONFIG_HOME/War3Preferences.txt"
echo "Installing Warcraft III hotkeys..."
cp "$CUSTOM_KEYS_FILE" "$WARCRAFT_CONFIG_HOME/CustomKeyBindings/CustomKeys.txt"
echo "Installing W3Champions.bat with Bonjour workarounds..."
cp "$BATCHFILE" "$W3CHAMPIONS_HOME/W3Champions.bat"
