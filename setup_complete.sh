#!/usr/bin/env bash

export WINEPREFIX="$HOME/Games/W3Champions"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none
GITHUB_TOKEN=""

for i in "$@"; do
  case $i in
    -p=*|--prefix=*)
      export WINEPREFIX="${i#*=}"
      shift
      ;;
    -t=*|--token=*)
      GITHUB_TOKEN="${i#*=}"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

## Detect distro and install Wine (Staging) ##

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "${ID_LIKE:-$ID}"
  else
    echo "unknown"
  fi
}

install_wine() {
  local distro
  distro=$(detect_distro)

  case "$distro" in
    *arch*)
      echo "Detected Arch-based distro. Installing wine-staging..."
      sudo pacman -S --needed --noconfirm wine-staging unzip winetricks
      ;;
    *debian*|*ubuntu*)
      echo "Detected Debian/Ubuntu-based distro. Installing wine-staging..."
      sudo dpkg --add-architecture i386
      sudo mkdir -pm755 /etc/apt/keyrings
      sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

      . /etc/os-release
      case "$ID" in
        debian)
          sudo wget -NP /etc/apt/sources.list.d/ \
            "https://dl.winehq.org/wine-builds/debian/dists/${VERSION_CODENAME}/winehq-${VERSION_CODENAME}.sources"
          ;;
        ubuntu|linuxmint|pop)
          sudo wget -NP /etc/apt/sources.list.d/ \
            "https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_CODENAME:-$VERSION_CODENAME}/winehq-${UBUNTU_CODENAME:-$VERSION_CODENAME}.sources"
          ;;
        *)
          echo "Unknown Debian-based distro '$ID'. Attempting with VERSION_CODENAME=$VERSION_CODENAME..."
          sudo wget -NP /etc/apt/sources.list.d/ \
            "https://dl.winehq.org/wine-builds/debian/dists/${VERSION_CODENAME}/winehq-${VERSION_CODENAME}.sources"
          ;;
      esac

      sudo apt update
      sudo apt install --install-recommends -y winehq-staging winetricks unzip
      ;;
    *)
      echo "Unsupported distro: $distro"
      echo "Please install wine-staging manually and re-run this script."
      exit 1
      ;;
  esac
}

if ! command -v wine &> /dev/null; then
  install_wine
else
  echo "Wine is already installed: $(wine --version)"
fi

mkdir -p "$WINEPREFIX"

## Initialize wine prefix ##

wineboot --init 2>/dev/null
winetricks -q dxvk 2>/dev/null

## Get and extract DXVK ##

DXVK_ZIP="dxvk-radv-slow-clear-workaround-a13849e9ab3d4459464f9f891916bb11dddd2963.zip"
DXVK_ARTIFACT_URL="https://github.com/doitsujin/dxvk/actions/runs/21858343809/artifacts/5445517868"
DXVK_API_URL="https://api.github.com/repos/doitsujin/dxvk/actions/artifacts/5445517868/zip"

download_dxvk_artifact() {
  # Try gh CLI first
  if command -v gh &> /dev/null; then
    echo "Using gh CLI to download DXVK artifact..."
    gh run download 21858343809 --repo doitsujin/dxvk --name "dxvk-radv-slow-clear-workaround-a13849e9ab3d4459464f9f891916bb11dddd2963" --dir dxvk_temp
    if [ $? -eq 0 ]; then
      # gh extracts directly, move files to expected location
      if [ -d "dxvk_temp" ]; then
        cp -r dxvk_temp/* .
        rm -rf dxvk_temp
        touch "$DXVK_ZIP"  # Create marker file
        return 0
      fi
    fi
    echo "gh download failed, trying alternative methods..."
  fi

  # Try with API token if provided
  if [ -n "$GITHUB_TOKEN" ]; then
    echo "Using API token to download DXVK artifact..."
    curl -L -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         "$DXVK_API_URL" -o "$DXVK_ZIP"
    if [ $? -eq 0 ] && [ -f "$DXVK_ZIP" ] && [ -s "$DXVK_ZIP" ]; then
      return 0
    fi
    echo "API token download failed..."
    rm -f "$DXVK_ZIP"
  fi

  # Manual download required
  echo ""
  echo "=============================================="
  echo "MANUAL DOWNLOAD REQUIRED"
  echo "=============================================="
  echo "Please download the DXVK artifact manually:"
  echo ""
  echo "  $DXVK_ARTIFACT_URL"
  echo ""
  echo "Save it as: $(pwd)/$DXVK_ZIP"
  echo ""
  echo "Note: You need to be logged into GitHub to download artifacts."
  echo "=============================================="
  echo ""

  while true; do
    read -p "Press Enter once you have downloaded the file (or 'q' to quit): " response
    if [ "$response" = "q" ] || [ "$response" = "Q" ]; then
      echo "Aborting setup."
      exit 1
    fi
    if [ -f "$DXVK_ZIP" ]; then
      echo "File found!"
      return 0
    fi
    echo "File not found at $(pwd)/$DXVK_ZIP"
    echo "Please ensure the file is downloaded to the correct location."
  done
}

if [ ! -f "$DXVK_ZIP" ] && [ ! -d "x64" ] && [ ! -d "x32" ]; then
  echo "DXVK artifact not found, attempting to download..."
  download_dxvk_artifact
fi

if [ -f "$DXVK_ZIP" ] && { [ ! -d "x64" ] || [ ! -d "x32" ]; }; then
  echo "Extracting DXVK artifact..."
  unzip -o "$DXVK_ZIP"
fi

echo "Installing DXVK DLLs"
for dll in x64/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/system32/"
done
for dll in x32/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/syswow64/"
done

## Install WebView ##

WEBVIEW_DOWNLOAD_URL="https://go.microsoft.com/fwlink/p/?LinkId=2124701"
WEBVIEW_DOWNLOAD_PATH="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
curl -L "$WEBVIEW_DOWNLOAD_URL" --output "$WEBVIEW_DOWNLOAD_PATH"

wine "$WEBVIEW_DOWNLOAD_PATH" 2>/dev/null

read -p "Press Enter once you have installed webview2 (or 'q' to quit): " response
if [ "$response" = "q" ] || [ "$response" = "Q" ]; then
  echo "Aborting setup."
  exit 1
fi

REG_FILE=$(mktemp /tmp/wine_reg_XXXXXX.reg)
cat > "$REG_FILE" <<'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\msedgewebview2.exe]
"Version"="win7"
EOF
wine regedit /S "$REG_FILE" 2>/dev/null

## Install Battle.net (and WC3) ##

BNET_DOWNLOAD_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
BNET_DOWNLOAD_PATH="$HOME/Downloads/Battle.net-Setup.exe"
curl -L "$BNET_DOWNLOAD_URL" --output "$BNET_DOWNLOAD_PATH"

wine "$BNET_DOWNLOAD_PATH" 2>/dev/null

read -p "Press Enter once you have installed bnet AND downloaded wc3 (or 'q' to quit): " response
if [ "$response" = "q" ] || [ "$response" = "Q" ]; then
  echo "Aborting setup."
  exit 1
fi

## Install W3Champions ##

W3CHAMPIONS_DOWNLOAD_URL="https://update-service.w3champions.com/api/launcher-e"
W3CHAMPIONS_DOWNLOAD_PATH="$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
curl -L "$W3CHAMPIONS_DOWNLOAD_URL" --output "$W3CHAMPIONS_DOWNLOAD_PATH"

wine "$W3CHAMPIONS_DOWNLOAD_PATH" 2>/dev/null
