#!/usr/bin/env bash

export WINEPATH="$HOME/Games"
export WINEPREFIX="$WINEPATH/W3Champions"
export WINEARCH="win64"
export WINEDEBUG="-all"
export USER_HOME="$WINEPREFIX/drive_c/users/$USER"
export APPDATA="$USER_HOME/AppData"
export APPDATA_LOCAL="$APPDATA/Local"
export W3C_DATA="$APPDATA_LOCAL/com.w3champions.client"
export W3C_AUTH_DATA="''${W3C_AUTH_DATA:-}"

if [[ -z "$W3C_AUTH_DATA" ]]; then
  echo "Error: W3C_AUTH_DATA is not set. Aborting."
  exit 1
fi

if [[ ! -d "$W3C_AUTH_DATA" ]]; then
  echo "Error: Source directory '$W3C_AUTH_DATA' does not exist. Aborting."
  exit 1
fi

mkdir -p "$W3C_DATA"

rm -rf "$W3C_DATA"
cp -r "$W3C_AUTH_DATA" "$W3C_DATA"
