#!/usr/bin/env bash
# W3Champions diagnostic script
# Run this and paste the full output into your GitHub issue.

export WINEPREFIX="${WINEPREFIX:-$HOME/Games/W3Champions}"

ISSUES=()
issue() { ISSUES+=("$*"); }

hdr() { echo; echo "### $*"; }

echo "=== W3ChampionsOnLinux Diagnostic Report ==="
echo "Date : $(date -u '+%Y-%m-%d %H:%M UTC')"

hdr "System"
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "Distro       : ${PRETTY_NAME:-unknown}"
fi
echo "Kernel       : $(uname -r)"
echo "Session type : ${XDG_SESSION_TYPE:-unknown}"
echo "DISPLAY      : ${DISPLAY:-not set}"
echo "WAYLAND      : ${WAYLAND_DISPLAY:-not set}"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    compositor="Hyprland"
elif [ -n "${SWAYSOCK:-}" ]; then
    compositor="Sway"
elif [ -n "${I3SOCK:-}" ]; then
    compositor="i3"
else
    compositor="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
fi
echo "Compositor   : $compositor"

hdr "GPU & Drivers"
if command -v lspci &>/dev/null; then
    lspci 2>/dev/null | grep -iE "VGA|3D|Display" | sed 's/^/  /'
else
    echo "  lspci not found. Install pciutils"
fi

if command -v nvidia-smi &>/dev/null; then
    nvidia_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
    echo "NVIDIA driver : ${nvidia_ver:-unknown}"
elif [ -f /sys/module/nvidia/version ]; then
    echo "NVIDIA driver : $(</sys/module/nvidia/version)"
fi

if command -v glxinfo &>/dev/null; then
    glxinfo 2>/dev/null | grep -E "OpenGL (renderer|version)" | sed 's/^/  /'
fi

if command -v vulkaninfo &>/dev/null; then
    echo "Vulkan:"
    vulkaninfo --summary 2>/dev/null \
        | grep -E "GPU|apiVersion|driverVersion|driverInfo" \
        | head -8 \
        | sed 's/^/  /'
fi

icd_exists() {
    local name="$1" suffix="$2"; shift 2
    for dir in "$@"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*"${name}"*."${suffix}".json; do
            [ -f "$f" ] || continue
            local lib
            lib=$(grep -m1 'library_path' "$f" | sed 's/.*"library_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            [ -f "$lib" ] && return 0
        done
    done
    return 1
}

print_vulkan_icds() {
    local suffix="$1"; shift
    local found=0
    for dir in "$@"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*."$suffix".json; do
            [ -f "$f" ] || continue
            local lib api name
            lib=$(grep -m1 'library_path' "$f" | sed 's/.*"library_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            [ -f "$lib" ] || continue
            api=$(grep -m1 'api_version' "$f" | sed 's/.*"api_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            name=$(basename "$lib" | sed 's/\.so.*//; s/^libvulkan_//; s/^libGLX_//')
            echo "  $name  (Vulkan $api)"
            found=1
        done
        [ "$found" -gt 0 ] && break
    done
    [ "$found" -eq 0 ] && echo "  none"
    return $((found == 0))
}

dirs64=(/run/opengl-driver/share/vulkan/icd.d /usr/share/vulkan/icd.d)
dirs32=(/run/opengl-driver-32/share/vulkan/icd.d /usr/share/vulkan/icd.d)

echo "Vulkan drivers (64-bit):"
print_vulkan_icds x86_64 "${dirs64[@]}"

echo "Vulkan drivers (32-bit):"
if ! print_vulkan_icds i686 "${dirs32[@]}"; then
    issue "No 32-bit Vulkan drivers found. DXVK 32-bit (syswow64) will not work. Install lib32-vulkan-radeon, lib32-nvidia-utils, etc."
fi

ver_gte() {
    [ "$(printf '%s\n%s' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

gpu_list=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display")

if echo "$gpu_list" | grep -qiE "AMD|ATI|Radeon"; then
    if icd_exists radeon x86_64 "${dirs64[@]}" && icd_exists radeon i686 "${dirs32[@]}"; then
        echo "AMD GPU     : radeon (RADV/Mesa) ICD OK for 64-bit and 32-bit"
    else
        echo "AMD GPU     : radeon (RADV/Mesa) ICD missing or incomplete"
        issue "AMD GPU detected but radeon (RADV/Mesa) ICD missing. Install mesa + lib32-mesa (Arch) or mesa-vulkan-drivers + mesa-vulkan-drivers:i386 (Debian/Ubuntu)."
    fi
    for dir in "${dirs64[@]}"; do
        [ -d "$dir" ] || continue
        for f in "$dir"/*radeon*.x86_64.json; do
            [ -f "$f" ] || continue
            mesa_lib=$(grep -m1 'library_path' "$f" | sed 's/.*"library_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            [ -f "$mesa_lib" ] || continue
            mesa_ver=$(strings "$mesa_lib" 2>/dev/null | grep -oE '^Mesa [0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | cut -d' ' -f2)
            break 2
        done
    done
    if [ -n "$mesa_ver" ]; then
        echo "AMD driver  : Mesa $mesa_ver"
        if ! ver_gte "$mesa_ver" "25.0"; then
            issue "Mesa $mesa_ver is too old for DXVK 2.7. RADV requires >= 25.0. Update your Mesa drivers."
        fi
    fi
fi

if echo "$gpu_list" | grep -qiE "NVIDIA"; then
    if icd_exists nvidia x86_64 "${dirs64[@]}" && icd_exists nvidia i686 "${dirs32[@]}"; then
        echo "NVIDIA GPU  : nvidia ICD OK for 64-bit and 32-bit"
    else
        echo "NVIDIA GPU  : nvidia ICD missing or incomplete"
        issue "NVIDIA GPU detected but nvidia Vulkan ICD missing. Install nvidia-utils + lib32-nvidia-utils (Arch) or equivalent."
    fi
    nvidia_drv=${nvidia_ver:-$(</sys/module/nvidia/version 2>/dev/null)}
    if [ -n "$nvidia_drv" ]; then
        if ! ver_gte "$nvidia_drv" "575.51.02"; then
            issue "NVIDIA driver $nvidia_drv is too old for DXVK 2.7. Requires >= 575.51.02. Update your NVIDIA driver."
        fi
    fi
fi

hdr "Required Tools"
for tool in wine winecfg winetricks unzip curl; do
    if command -v "$tool" &>/dev/null; then
        echo "$tool : OK"
    else
        echo "$tool : NOT FOUND"
        issue "$tool not found in PATH. Install it before running setup"
    fi
done

hdr "Wine"
if command -v wine &>/dev/null; then
    wine_ver=$(wine --version 2>/dev/null)
    echo "Version    : $wine_ver"
    wine_num=$(echo "$wine_ver" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    wine_major=$(echo "$wine_num" | cut -d. -f1)
    wine_minor=$(echo "$wine_num" | cut -d. -f2)
    if [ -n "$wine_major" ]; then
        if [ "$wine_major" -lt 10 ] || { [ "$wine_major" -eq 10 ] && [ "$wine_minor" -lt 16 ]; }; then
            issue "Wine $wine_ver is too old. Needs >= 10.16 for shared resource support"
        fi
    fi
else
    echo "Version    : NOT FOUND"
    issue "wine not found in PATH"
fi
echo "WINEPREFIX : $WINEPREFIX"
echo "WINEARCH   : ${WINEARCH:-not set}"
[ -n "${WINE:-}" ]     && echo "WINE       : $WINE"
[ -n "${DXVK_HUD:-}" ] && echo "DXVK_HUD  : $DXVK_HUD"

hdr "DXVK"

# Minimum master build with shared-resource support (DXVK PR #5257): v2.7.1-452
dxvk_new_enough() {
    local ver="$1"
    local tag n vmaj vmin vpat
    tag=$(echo "$ver" | grep -oE '^v[0-9]+\.[0-9]+(\.[0-9]+)?')
    n=$(echo "$ver" | sed -E 's/^v[^-]+-([0-9]+)-.*/\1/')
    if [ -z "$tag" ] || [ -z "$n" ]; then return 1; fi
    vmaj=$(echo "$tag" | tr -d 'v' | cut -d. -f1)
    vmin=$(echo "$tag" | cut -d. -f2)
    vpat=$(echo "$tag" | cut -d. -f3); vpat=${vpat:-0}
    local min_maj=2 min_min=7 min_pat=1 min_n=452
    if   [ "$vmaj" -gt "$min_maj" ]; then return 0
    elif [ "$vmaj" -lt "$min_maj" ]; then return 1
    elif [ "$vmin" -gt "$min_min" ]; then return 0
    elif [ "$vmin" -lt "$min_min" ]; then return 1
    elif [ "$vpat" -gt "$min_pat" ]; then return 0
    elif [ "$vpat" -lt "$min_pat" ]; then return 1
    else [ "$n" -ge "$min_n" ]
    fi
}

check_dxvk_dll() {
    local dll="$1" bits="$2"
    if [ ! -f "$dll" ]; then
        echo "${bits}-bit d3d11.dll : NOT FOUND"
        issue "DXVK ${bits}-bit d3d11.dll missing from $dll"
        return
    fi
    # Prefer git-describe string (v2.7.1-452-ga13849e9) over bare tag which also appears in the DLL
    local ver
    ver=$(strings "$dll" 2>/dev/null \
        | grep -E '^v[0-9]+\.[0-9]+(\.[0-9]+)?-[0-9]+-g[0-9a-f]+$' \
        | head -1)
    [ -z "$ver" ] && ver=$(strings "$dll" 2>/dev/null \
        | grep -E '^v[0-9]+\.[0-9]+(\.[0-9]+)?$' \
        | head -1)
    [ -z "$ver" ] && ver="unknown (strings parse failed)"
    echo "${bits}-bit d3d11.dll : $ver"
    if echo "$ver" | grep -qE -- '-[0-9]+-g[0-9a-f]+'; then
        if ! dxvk_new_enough "$ver"; then
            issue "DXVK ${bits}-bit is too old ($ver). Needs a master build >= v2.7.1-452 (PR #5257). Download a newer artifact from https://github.com/doitsujin/dxvk/actions"
        fi
    else
        issue "DXVK ${bits}-bit is a release build ($ver). Release builds don't have PR #5257 yet. Download a master artifact from https://github.com/doitsujin/dxvk/actions"
    fi
}

check_dxvk_dll "$WINEPREFIX/drive_c/windows/system32/d3d11.dll" 64
check_dxvk_dll "$WINEPREFIX/drive_c/windows/syswow64/d3d11.dll" 32

d3d11_override=$(wine reg query "HKCU\Software\Wine\DllOverrides" /v "*d3d11" 2>/dev/null \
    | grep "REG_SZ" | awk '{print $NF}' | tr -d '\r')
echo "d3d11 override : ${d3d11_override:-NOT SET}"
if [ "${d3d11_override:-}" != "native" ]; then
    issue "d3d11 DLL override not set to 'native'. Run 'winetricks dxvk' to fix"
fi

hdr "Wineprefix Configuration"
if [ ! -d "$WINEPREFIX" ]; then
    echo "Prefix : NOT FOUND ($WINEPREFIX)"
    issue "WINEPREFIX directory does not exist"
else
    echo "Prefix : $WINEPREFIX"

    wine_ver_key=$(winecfg /v 2>&1 | grep -E '^win|^vista')
    echo "Windows version : ${wine_ver_key:-unknown}"
    case "${wine_ver_key:-}" in
        win10*) ;;
        "") issue "Could not read Windows version (winecfg /v failed)" ;;
        *) issue "Windows version is set to $wine_ver_key (should be win10). Fix: run 'winecfg /v win10'. Windows 11 causes a white screen." ;;
    esac

    edge_ver=$(wine reg query "HKCU\Software\Wine\AppDefaults\msedgewebview2.exe" \
        /v Version 2>/dev/null \
        | grep "REG_SZ" | awk '{print $NF}' | tr -d '\r')
    echo "msedgewebview2 compat : ${edge_ver:-NOT SET}"
    if [ "${edge_ver:-}" != "win7" ]; then
        issue "msedgewebview2.exe compatibility not set to win7 (got: ${edge_ver:-not set}). W3Champions will show a white screen."
    fi
fi

hdr "WebView2 Runtime"
webview_dir="$WINEPREFIX/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"
if [ -d "$webview_dir" ]; then
    webview_ver=$(find "$webview_dir" -maxdepth 1 -mindepth 1 2>/dev/null | head -1 | xargs -I{} basename {})
    echo "Version : ${webview_ver:-unknown (directory exists but empty)}"
    webview_major=$(echo "$webview_ver" | cut -d. -f1)
    if [ -n "$webview_major" ] 2>/dev/null; then
        if [ "$webview_major" -lt 109 ]; then
            issue "WebView2 version $webview_ver is too old and will not work. Reinstall the latest runtime from Microsoft."
        elif [ "$webview_major" -gt 109 ] && [ "$webview_major" -lt 144 ]; then
            issue "WebView2 version $webview_ver is in the broken range (110-143). Reinstall the latest runtime from Microsoft."
        fi
    fi
else
    echo "Not found. Expected: $webview_dir"
    issue "WebView2 runtime not installed in prefix. Run the WebView2 installer inside Wine."
fi

hdr "Game Installations"
if [ -d "$WINEPREFIX" ]; then
    bnet_exe="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net.exe"
    if [ -f "$bnet_exe" ]; then
        echo "Battle.net   : $bnet_exe"
    else
        echo "Battle.net   : NOT FOUND"
        issue "Battle.net not installed in prefix"
    fi

    w3c_exe="$WINEPREFIX/drive_c/Program Files/W3Champions/W3Champions.exe"
    if [ -f "$w3c_exe" ]; then
        echo "W3Champions  : $w3c_exe"
    else
        echo "W3Champions  : NOT FOUND"
        issue "W3Champions not installed in prefix"
    fi

    wc3_exe=$(find "$WINEPREFIX/drive_c" -iname "Warcraft III.exe" 2>/dev/null | head -1)
    if [ -n "$wc3_exe" ]; then
        echo "Warcraft III : $wc3_exe"
    else
        echo "Warcraft III : NOT FOUND"
        issue "Warcraft III not found in prefix. Download it via Battle.net"
    fi

    bonjour_exe="$WINEPREFIX/drive_c/Program Files/Blizzard/Bonjour Service/mDNSResponder.exe"
    if [ -f "$bonjour_exe" ]; then
        echo "Bonjour      : $bonjour_exe"
    else
        echo "Bonjour      : NOT FOUND"
        issue "Bonjour not installed. W3Champions installs it on first launch. If missing, run W3Champions once and check again."
    fi
else
    echo "(skipped. Prefix not found)"
fi

hdr "Firewall"
# Required: TCP 3550 3551 3552 | UDP 3552 5353 | mDNS multicast 224.0.0.251:5353
echo "Required : TCP 3550 3551 3552  |  UDP 3552 5353  |  mDNS multicast 224.0.0.251 UDP 5353"
fw_rules=""
fw_tool=""
if nft list ruleset &>/dev/null; then
    fw_rules=$(nft list ruleset 2>/dev/null)
    fw_tool="nftables"
elif sudo -n nft list ruleset &>/dev/null; then
    fw_rules=$(sudo nft list ruleset 2>/dev/null)
    fw_tool="nftables"
elif iptables -L -n &>/dev/null; then
    fw_rules=$(iptables -L -n 2>/dev/null)
    fw_tool="iptables"
elif sudo -n iptables -L -n &>/dev/null; then
    fw_rules=$(sudo iptables -L -n 2>/dev/null)
    fw_tool="iptables"
elif command -v ufw &>/dev/null; then
    fw_rules=$(ufw status 2>/dev/null)
    fw_tool="ufw"
fi

if [ -n "$fw_rules" ]; then
    echo "Firewall tool : $fw_tool"
    all_ok=1
    for port in 3550 3551 3552 5353; do
        if ! echo "$fw_rules" | grep -qE "$port"; then
            echo "Port $port : not found in ruleset"
            all_ok=0
        fi
    done
    if [ "$all_ok" -eq 0 ]; then
        echo "Note : if Bonjour/LAN features are broken, open TCP 3550 3551 3552 and UDP 3552 5353 in your firewall"
    else
        echo "Ports : required ports appear open"
    fi
else
    echo "Firewall tool : could not read ruleset (try running as root)"
    echo "Note : if Bonjour/LAN features are broken, check that TCP 3550 3551 3552 and UDP 3552 5353 are open"
    echo "  sudo nft list ruleset | grep -E '3550|3551|3552|5353'"
    echo "  sudo iptables -L -n   | grep -E '3550|3551|3552|5353'"
fi

hdr "Summary"
if [ ${#ISSUES[@]} -eq 0 ]; then
    echo "No issues detected."
else
    echo "${#ISSUES[@]} issue(s) found:"
    for i in "${!ISSUES[@]}"; do
        echo "  $((i+1)). ${ISSUES[$i]}"
    done
fi
echo
