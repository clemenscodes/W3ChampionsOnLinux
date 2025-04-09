#!/usr/bin/env bash

WINEPATH="$HOME/Games"
WINEPREFIX="$WINEPATH/W3Champions"
WINEARCH="win64"
WINEDEBUG="-all"
DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
WARCRAFT_PATH="''${WARCRAFT_PATH:-}"

if [[ -z "$WARCRAFT_PATH" ]]; then
  echo "Error: WARCRAFT_PATH is not set. Aborting."
  exit 1
fi

if [[ ! -d "$WARCRAFT_PATH" ]]; then
  echo "Error: Source directory '$WARCRAFT_PATH' does not exist. Aborting."
  exit 1
fi

if [ ! -d "$WARCRAFT_HOME" ]; then
  echo "Warcraft III is not installed..."
  if [ -n "$WARCRAFT_PATH" ]; then
    echo "Copying $WARCRAFT_PATH to $WARCRAFT_HOME"
    cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
    rm -rf "$WARCRAFT_HOME/_retail_/webui" || true
    echo "Finished installing Warcraft III"
  else
    echo "You can provide the installer with an existing Warcraft III installation."
    echo "Pass WARCRAFT_PATH environment variable to the script pointing to an existing install of Warcraft III."
  fi
else
  echo "Warcraft III is already installed. Done."
fi
