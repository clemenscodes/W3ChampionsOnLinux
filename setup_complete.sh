#!/usr/bin/env bash

export WINEPREFIX="$HOME/Games/W3Champions"
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

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

install_vulkan_drivers() {
  local distro
  distro=$(detect_distro)

  case "$distro" in
    *arch*)
      echo "Installing 32-bit Vulkan support (Arch)..."
      sudo pacman -S --needed --noconfirm lib32-vulkan-icd-loader
      if lspci 2>/dev/null | grep -qiE "NVIDIA"; then
        sudo pacman -S --needed --noconfirm lib32-nvidia-utils
      fi
      if lspci 2>/dev/null | grep -qiE "AMD|ATI|Radeon"; then
        sudo pacman -S --needed --noconfirm lib32-vulkan-radeon
      fi
      ;;
    *debian*|*ubuntu*)
      echo "Installing 32-bit Vulkan support (Debian/Ubuntu)..."
      sudo dpkg --add-architecture i386
      sudo apt update -qq
      sudo apt install -y libvulkan1 libvulkan1:i386 || true
      # NVIDIA: 32-bit Vulkan libs (libnvidia-gl-<ver>:i386) are NOT pulled in automatically
      if command -v nvidia-smi &>/dev/null; then
        local nvidia_major
        nvidia_major=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 | cut -d. -f1)
        if [ -n "$nvidia_major" ]; then
          echo "Installing libnvidia-gl-${nvidia_major}:i386 for 32-bit DXVK support..."
          sudo apt install -y "libnvidia-gl-${nvidia_major}:i386" || \
            echo "Warning: could not install libnvidia-gl-${nvidia_major}:i386 — check that the package exists for your driver version."
        fi
      fi
      # Mesa (AMD/Intel): install 32-bit drivers if 64-bit Mesa ICDs are present
      if [ -f /usr/share/vulkan/icd.d/radeon_icd.x86_64.json ] || \
         [ -f /usr/share/vulkan/icd.d/intel_icd.x86_64.json ]; then
        echo "Installing mesa-vulkan-drivers:i386 for 32-bit DXVK support..."
        sudo apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:i386 || true
      fi
      ;;
  esac
}

if ! command -v wine &> /dev/null; then
  install_wine
else
  echo "Wine is already installed: $(wine --version)"
fi

install_vulkan_drivers

mkdir -p "$WINEPREFIX"

## Initialize wine prefix ##

wineboot --init 2>/dev/null
winetricks -q dxvk 2>/dev/null

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
