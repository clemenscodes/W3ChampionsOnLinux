# Installing W3Champions on Linux

## Automated Setup

A [`setup_complete.sh`](./setup_complete.sh) script is available that automates the full setup.
It detects whether you are on an Arch-based or Debian/Ubuntu-based distro and installs Wine (Staging) accordingly,
then proceeds to set up DXVK, WebView2, Battle.net, and W3Champions.

```sh
bash setup_complete.sh
```

You can optionally pass a custom wine prefix path and a GitHub token (needed to download the DXVK artifact without the `gh` CLI):

```sh
bash setup_complete.sh --prefix="$HOME/Games/W3Champions" --token="<your-github-token>"
```

If you prefer to follow the steps manually, continue below.

## Install Wine (Staging)

At least wine 10.16 is required,
which added [initial support for D3DKMT objects](https://gitlab.winehq.org/wine/wine/-/releases/wine-10.16).

Those are used by the Chromium based WebUI of Warcraft III
that was introduced with Reforged.

Before wine 10.16, only Proton supported these shared resources.

Personally, I found the most stable experience using version 10.18.
Some later versions have actually caused some issues.
For now, `wine-10.18 (Staging)` is the recommended version to use, until I was able to do more testing with later versions.

### Arch Linux

```sh
pacman -S wine-staging
```

### Debian / Ubuntu

First, enable 32-bit support and add the WineHQ signing key:

```sh
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
```

Then add the repository for your distribution. Use the block that matches your OS:

**Debian 12 (Bookworm):**

```sh
sudo wget -NP /etc/apt/sources.list.d/ \
  https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
```

**Ubuntu 24.04 (Noble):**

```sh
sudo wget -NP /etc/apt/sources.list.d/ \
  https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
```

**Ubuntu 22.04 (Jammy):**

```sh
sudo wget -NP /etc/apt/sources.list.d/ \
  https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
```

Then install wine-staging and winetricks:

```sh
sudo apt update
sudo apt install --install-recommends winehq-staging winetricks
```

## Install DXVK

Since wine added support for shared resources, DXVK has not yet published a release that is compatible with this new change.
However, the support is implemented on the [master branch](https://github.com/doitsujin/dxvk)
thanks to the following [Pull Request](https://github.com/doitsujin/dxvk/pull/5257).

To get a supported DXVK version one can manually download the artifacts from the
[action workflows](<https://github.com/doitsujin/dxvk/actions?query=branch%3Amaster+workflow%3A"Artifacts%20(Package)">).

You should manually download the latest artifact that has a green checkmark.

![DXVK Workflow Actions Download Page](./assets/dxvk-actions.png)

![DXVK Artifact Download](./assets/dxvk-artifact-download.png)

Once you got a version with support, extract the ZIP file.

![DXVK ZIP extraction](./assets/dxvk-extract.png)

> [!NOTE]
> Debian/Ubuntu users: make sure `unzip` is installed first: `sudo apt install unzip`

```sh
unzip <dxvk-branch-download-revision>.zip
```

Assuming you are in the same directory as when you extracted the DXVK ZIP file, you should have two directories.

`x64` and `x32`.

Then you can install this DXVK version in the desired wine prefix as follows:

```sh
export WINEPATH="$HOME/Games"
export WINEPREFIX="$WINEPATH/W3Champions"

mkdir -p "$WINEPREFIX"
wineboot --init
winetricks -q dxvk

echo "Installing DXVK DLLs"
for dll in ./x64/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/system32/"
done
for dll in ./x32/*.dll; do
  cp "$dll" "$WINEPREFIX/drive_c/windows/syswow64/"
done
```

> [!NOTE]
> It may seem unintuitive, but the DLLs really have to go in these respective directories
> according to the upstream [documentation](https://github.com/doitsujin/dxvk?tab=readme-ov-file#how-to-use)

## WebView2 Runtime (IMPORTANT)

Before, only a very old WebView2 runtime version was supported (109.X).
Using the new versions as described above, one can install the very latest WebView2 runtime versions,
which is required by W3Champions.

### Download

```sh
WEBVIEW_DOWNLOAD_URL="https://go.microsoft.com/fwlink/p/?LinkId=2124701"
WEBVIEW_DOWNLOAD_PATH="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
curl -L "$WEBVIEW_DOWNLOAD_URL" --output "$WEBVIEW_DOWNLOAD_PATH"
```

### Install

```sh
wine "$WEBVIEW_DOWNLOAD_PATH"
```

### Default Windows version

The default Windows version is typically set to "Windows 10". This is fine.

If it is set to "Windows 11", W3Champions will later only render a white screen.

### Set Edge to Windows 7 (IMPORTANT)

You must tell the `msedgewebview2.exe` that the Windows version is 7.

If you forget to do this, W3Champions will later only render a white screen.

You can either do this using `winecfg` or by running the following in a terminal.

```sh
REG_FILE=$(mktemp /tmp/wine_reg_XXXXXX.reg)

cat > "$REG_FILE" <<'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\msedgewebview2.exe]
"Version"="win7"
EOF

wine regedit /S "$REG_FILE"
```

## Battle.net & Warcraft III

### Download

```sh
BNET_DOWNLOAD_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
BNET_DOWNLOAD_PATH="$HOME/Downloads/Battle.net-Setup.exe"
curl -L "$BNET_DOWNLOAD_URL" --output "$BNET_DOWNLOAD_PATH"
```

### Install

```sh
wine "$BNET_DOWNLOAD_PATH"
```

After installing Battle.net, login and download Warcraft III.
Then run Warcraft III once to verify the installed wine and dxvk versions work.

## W3Champions

### Download

```sh
W3CHAMPIONS_DOWNLOAD_URL="https://update-service.w3champions.com/api/launcher-e"
W3CHAMPIONS_DOWNLOAD_PATH="$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
curl -L "$W3CHAMPIONS_DOWNLOAD_URL" --output "$W3CHAMPIONS_DOWNLOAD_PATH"
```

### Install

This should work without any errors.
The login should now not crash since we use a new version of the WebView2 runtime.

```sh
wine "$W3CHAMPIONS_DOWNLOAD_PATH"
```

### Run

```sh
wine "$WINEPREFIX/drive_c/Program Files/W3Champions/W3Champions.exe"
```

## Troubleshooting

If something isn't working, run the diagnostic script and paste the full output into a [GitHub issue](https://github.com/clemenscodes/W3ChampionsOnLinux/issues):

```sh
bash scripts/diagnose.sh
```

It checks Wine version, DXVK version and DLL overrides, Windows version in the prefix, WebView2 runtime, Vulkan drivers (64-bit and 32-bit), GPU driver versions against DXVK minimum requirements, game installations, Bonjour, and firewall ports.

## Known Issues

### Mouse cursor disappears

When the mouse disappears, switching workspaces while moving the mouse tends to re-render it on top of the W3Champions window.
Preventing the window manager from decorating the Warcraft and W3Champions windows can help.
As a last resort, you can use a virtual desktop in wine. The cursor will be rendered properly at all times inside it.

On Hyprland, setting the following windowrules can help:

```hyprlang
windowrule = content game,class:(explorer.exe),title:()
windowrule = content game,class:(battle.net.exe),title:(Battle.net)
windowrule = content game,class:(w3champions.exe),title:(W3Champions)
windowrule = content game,class:(warcraft iii.exe),title:(Warcraft III)
windowrule = workspace 2,class:(battle.net.exe),title:(Battle.net)
windowrule = workspace 3,class:(explorer.exe),title:()
windowrule = workspace 3,class:(w3champions.exe),title:(W3Champions)
windowrule = workspace 4,class:(warcraft iii.exe),title:(Warcraft III)
windowrule = tile,class:(battle.net.exe),title:(Battle.net)
windowrule = tile,class:(w3champions.exe),title:(W3Champions)
windowrule = tile,class:(warcraft iii.exe),title:(Warcraft III)
windowrule = noinitialfocus,class:(explorer.exe),title:()
windowrule = noinitialfocus,class:(warcraft iii.exe),title:(Warcraft III)
windowrule = move 47% 96%,class:(explorer.exe),title:()
windowrule = opacity 0%,class:(explorer.exe),title:()
```

### W3Champions cannot verify Warcraft III with Battle.net

If you never played W3Champions before, you may need to verify your Warcraft III installation.
Download the legacy launcher from the [w3champions GitHub release page](https://github.com/w3champions/launcher/releases),
run it inside the prefix, then click Play on the legacy launcher to start Warcraft through Battle.net and verify it.

### White screen / W3Champions not launching

Run `bash scripts/diagnose.sh` first. It will flag the most common causes automatically.

Manual checks:

- Make sure the default Windows version in `winecfg` is set to **Windows 10** (not Windows 11).
  Fix: `winecfg /v win10`
- Make sure `msedgewebview2.exe` is set to **Windows 7** (see above).
- If the white screen persists, try killing all lingering wine processes and restarting:

```sh
for proc in main Warcraft wine Microsoft edge exe Cr mDNS; do
  pkill "$proc" || true
done
```

## Discord

- [W3Champions Discord](https://discord.gg/uJmQxG2)

Happy ladder climbing!

<details>
<summary><strong>Legacy Method: Lutris + Proton-GE (deprecated)</strong></summary>

> [!WARNING]
> This method is deprecated. The Wine-based guide above is the recommended approach.
> This section is kept for reference in case the Lutris/Proton-GE method works better for your setup.

### Prerequisites

- A valid **Warcraft III: Reforged** installation (through Battle.net).
- **Proton-GE (Latest, at least 9-26)** installed, or wine-staging (latest).
- **Lutris** for managing the installation.
- A **Vulkan-capable GPU**.
- The **latest Mesa drivers** installed.
- Follow **Lutris' instructions** for setting up drivers and Wine dependencies on Arch Linux.

### Arch Linux Setup

First, enable multilib (32-bit support) by uncommenting the `[multilib]` section in `/etc/pacman.conf`:

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Then upgrade the system:

```sh
sudo pacman -Syu
```

#### AMD GPU

```sh
sudo pacman -S --needed lib32-mesa vulkan-radeon lib32-vulkan-radeon \
    vulkan-icd-loader lib32-vulkan-icd-loader
```

#### Wine dependencies

```sh
sudo pacman -S wine-staging
sudo pacman -S --needed --asdeps giflib lib32-giflib gnutls lib32-gnutls \
    v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins \
    alsa-lib lib32-alsa-lib sqlite lib32-sqlite libxcomposite lib32-libxcomposite \
    ocl-icd lib32-ocl-icd libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs \
    lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader \
    sdl2-compat lib32-sdl2-compat
```

### Installing Proton-GE with ProtonPlus

We recommend [ProtonPlus](https://github.com/Vysp3r/ProtonPlus) to manage Proton versions:

```sh
yay -S protonplus
```

Run ProtonPlus and install the latest available Proton-GE.

### Setting up Lutris

```sh
pacman -S lutris
```

> [!CAUTION]
> Download the latest Lutris release from [here](https://github.com/lutris/lutris/releases) if you run into issues.
> Outdated Lutris versions may not work with the latest Proton-GE.

Start Lutris and let it download its runtime. By default it downloads `wine-ge-8-26`, which does **not** work for W3Champions.

> [!CAUTION]
> After Lutris downloads `wine-ge-8-26`, it sets that as the default runner.
> Change the runner back to **Proton-GE (Latest)** before proceeding, or you will need to start over in a fresh prefix.

In Lutris, select the Wine runner on the left, then change it to Proton-GE (Latest).

In the system options, toggle `Advanced` and add the environment variable `WINE_SIMULATE_WRITECOPY=1` if you have issues with Battle.net.

### Creating a Lutris Game

1. Press the **+** button → **Add locally installed game**.
2. Set the name to `W3Champions`, select the **wine** runner.
3. In game options, set the wineprefix to `~/Games/W3Champions`.
4. Save.

### Installing WebView2

> [!IMPORTANT]
> In the Lutris/Proton-GE method, only the **old WebView2 version 109.X** is supported.
> Download it from the [releases page](https://github.com/clemenscodes/W3ChampionsOnLinux/releases)
> or from [archive.org](https://archive.org/download/microsoft-edge-web-view-2-runtime-installer-v109.0.1518.78/MicrosoftEdgeWebView2RuntimeInstallerX64.exe).

```sh
curl -L "https://github.com/clemenscodes/W3ChampionsOnLinux/releases/download/proton-ge-9-27/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" \
  --output "$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
```

Kill any lingering processes, then right-click the game in Lutris → **Run EXE inside Wine prefix** and select the installer.

```sh
for proc in lutris main Warcraft wine Microsoft edge srt-bwrap exe Cr mDNS; do
  pkill "$proc" || true
done
```

### Enabling msedgewebview2.exe compatibility

Open **Wine configuration** for the game (`winecfg`) and find `msedgewebview2.exe`.
Change its Windows version from **Windows 8.1** to **Windows 7**, then Apply and OK.

### Installing Battle.net

```sh
curl -L "https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe" \
  --output "$HOME/Downloads/Battle.net-Setup.exe"
```

Run this EXE inside the prefix. Log in, download Warcraft III: Reforged, and launch it once to confirm it works.

### Installing W3Champions

```sh
curl -L "https://update-service.w3champions.com/api/launcher-e" \
  --output "$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
```

Run this EXE inside the prefix. After installation, set the game executable in Lutris to
`$HOME/Games/W3Champions/drive_c/Program Files/W3Champions/W3Champions.exe`.

### Signing In

The sign-in step is unreliable. If it keeps crashing, try starting the launcher, then Battle.net, then resetting the Battle.net state. Rebooting first sometimes also helps.

#### Bypassing Sign In via Windows AppData

Sign in to W3Champions on a Windows system (or VM), then copy
`C:\users\<user>\AppData\Local\com.w3champions.client` to Linux:

```sh
rm -rf "$HOME/Games/W3Champions/drive_c/users/steamuser/AppData/Local/com.w3champions.client"
cp -r /mnt/com.w3champions.client "$HOME/Games/W3Champions/drive_c/users/steamuser/AppData/Local/com.w3champions.client"
```

### Post-installation: Bonjour Service

> [!IMPORTANT]
> On first launch W3Champions installs Bonjour and runs a LAN test automatically.
> On subsequent launches you must restart the Bonjour Service.
> Create a batch file with this content and set it as the game executable in Lutris:

```batch
C:
start "" "C:\Program Files\W3Champions\W3Champions.exe"
net stop "Bonjour Service"
net start "Bonjour Service"
```

### Lutris Known Issues

#### Blackscreen / W3Champions not launching

- Ensure `PROTON_VERB=run` is set in the environment variables.
- If you switch runners inside the prefix, reinstall WebView2 and reset `msedgewebview2.exe` to Windows 7.
- Kill lingering processes:

```sh
for proc in lutris main Warcraft wine Microsoft srt-bwrap exe Cr mDNS; do
  pkill "$proc" || true
done
```

</details>
