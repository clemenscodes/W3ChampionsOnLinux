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

mkdir -p "$WINEPREFIX"

cleanup_wine() {
  echo "Cleaning up wine processes"
  for proc in main Warcraft wine Microsoft srt-bwrap exe Cr mDNS; do
    pkill "$proc" 2>/dev/null || true
  done
}

setup_wine() {
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
}

warcraft_copy() {
  export WARCRAFT_PATH="${WARCRAFT_PATH:-}"

  if [[ -z "$WARCRAFT_PATH" ]]; then
    echo "WARCRAFT_PATH not set, skipping copy"
    return
  fi

  if [[ ! -d "$WARCRAFT_PATH" ]]; then
    echo "Invalid WARCRAFT_PATH"
    return
  fi

  local WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"

  if [[ ! -d "$WARCRAFT_HOME" ]]; then
    echo "Copying Warcraft III to wine prefix"
    mkdir -p "$PROGRAM_FILES86"
    cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
  else
    echo "Warcraft III already installed"
  fi
}

install_settings() {
  echo "Installing Warcraft settings"
  local CFG="$DOCUMENTS/Warcraft III"
  local W3C_HOME="$PROGRAM_FILES/W3Champions"

  mkdir -p "$CFG/CustomKeyBindings" "$W3C_HOME"

  cp "$BASE_DIR/War3Preferences.txt" "$CFG/War3Preferences.txt"
  cp "$BASE_DIR/CustomKeys.txt" "$CFG/CustomKeyBindings/CustomKeys.txt"
}

install_maps() {
  echo "Installing W3Champions maps"
  local MAP_DIR="$DOCUMENTS/Warcraft III/Maps/W3Champions"
  mkdir -p "$MAP_DIR"

  for map in "$BASE_DIR"/Maps/W3Champions/*; do
    cp "$map" "$MAP_DIR/"
  done
}

w3c_login_bypass() {
  export W3C_AUTH_DATA="${W3C_AUTH_DATA:-}"

  if [[ -z "$W3C_AUTH_DATA" || ! -d "$W3C_AUTH_DATA" ]]; then
    echo "Skipping W3C login bypass"
    return
  fi

  local TARGET="$WINEPREFIX/drive_c/users/$USER/AppData/Local/com.w3champions.client"
  mkdir -p "$TARGET"

  rsync -av --delete "$W3C_AUTH_DATA/" "$TARGET/"
}

download_webview() {
  local OUT="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
  mkdir -p "$HOME/Downloads"
  curl -L \
    "https://github.com/clemenscodes/W3ChampionsOnLinux/releases/download/proton-ge-9-27/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" \
    -o "$OUT"
}

install_webview() {
  local EXE="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
  local TARGET="$PROGRAM_FILES86/Microsoft/EdgeCore"

  if [[ -d "$TARGET" ]]; then
    echo "WebView2 already installed"
    return
  fi

  [[ -f "$EXE" ]] || download_webview

  cleanup_wine
  echo "Installing WebView2 (this may take a while)"
  wine "$EXE" &

  local PID=$!
  wait "$PID" || true

  if [[ ! -d "$TARGET" ]]; then
    echo "WebView2 installation failed"
    exit 1
  fi

  cleanup_wine
  wine regedit /S "$BASE_DIR/msedgewebview2.exe.reg"
}

download_w3c() {
  mkdir -p "$HOME/Downloads"
  curl -L "https://update-service.w3champions.com/api/launcher-e" \
    -o "$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
}

install_w3c() {
  local MSI="$HOME/Downloads/W3Champions_latest_x64_en-US.msi"

  [[ -f "$MSI" ]] || download_w3c

  cleanup_wine
  wine "$MSI"
}

download_battlenet() {
  mkdir -p "$HOME/Downloads"
  curl -L \
    "https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe" \
    -o "$HOME/Downloads/Battle.net-Setup.exe"
}

install_battlenet() {
  local EXE="$HOME/Downloads/Battle.net-Setup.exe"
  [[ -f "$EXE" ]] || download_battlenet

  cleanup_wine
  wine "$EXE"
}

run_battlenet() {
  local EXE="$PROGRAM_FILES86/Battle.net/Battle.net.exe"
  [[ -f "$EXE" ]] || install_battlenet
  wine "$EXE"
}

run_warcraft() {
  local EXE="$PROGRAM_FILES86/Warcraft III/_retail_/x86_64/Warcraft III.exe"
  [[ -f "$EXE" ]] || return
  wine "$EXE" -launcher
}

echo "Installing Warcraft III + W3Champions"

setup_wine
warcraft_copy || true
w3c_login_bypass || true
install_settings || true
install_maps || true
install_webview
install_w3c

echo "Installation complete 🎉"
