{
  self,
  pkgs,
  ...
}: let
  wineEnv = ''
    : "''${WINEPATH:=$HOME/Games}"
    : "''${WINEPREFIX:=$WINEPATH/W3Champions}"
    : "''${WINEDEBUG:=-all}"
    : "''${DXVK_LOG_LEVEL:=none}"
    export WINEPATH WINEPREFIX WINEDEBUG DXVK_LOG_LEVEL
  '';

  install-warcraft = pkgs.writeShellApplication {
    name = "install-warcraft";
    runtimeInputs = [
      setup-warcraft-wine
      warcraft-settings
      warcraft-copy
      w3c-login-bypass
      w3c-maps
      install-webview
      install-w3c
    ];
    text = ''
      echo "Installing Warcraft III"

      : "''${W3C_AUTH_DATA:=}"
      : "''${WARCRAFT_PATH:=}"
      export W3C_AUTH_DATA WARCRAFT_PATH

      WARCRAFT_PATH="$WARCRAFT_PATH" warcraft-copy || true
      W3C_AUTH_DATA="$W3C_AUTH_DATA" w3c-login-bypass || true

      setup-warcraft-wine
      warcraft-settings || true
      w3c-maps || true
      install-webview
      install-w3c
    '';
  };

  setup-warcraft-wine = pkgs.writeShellApplication {
    name = "setup-warcraft-wine";
    runtimeInputs = [pkgs.wine pkgs.winetricks pkgs.winetricks-compat];
    text = ''
      echo "Setting up wine prefix for Warcraft III"
      ${wineEnv}

      mkdir -p "$WINEPREFIX"
      wineboot --init
      winetricks dxvk

      for dll in ${self}/dxvk/x64/*.dll; do
        cat "$dll" > "$WINEPREFIX/drive_c/windows/system32/$(basename "$dll")"
      done

      for dll in ${self}/dxvk/x32/*.dll; do
        cat "$dll" > "$WINEPREFIX/drive_c/windows/syswow64/$(basename "$dll")"
      done
    '';
  };

  warcraft-settings = pkgs.writeShellApplication {
    name = "warcraft-settings";
    text = ''
      ${wineEnv}

      : "''${DOCUMENTS:=$WINEPREFIX/drive_c/users/$USER/Documents}"
      : "''${PROGRAM_FILES:=$WINEPREFIX/drive_c/Program Files}"
      : "''${W3CHAMPIONS_HOME:=$PROGRAM_FILES/W3Champions}"
      : "''${WARCRAFT_CONFIG_HOME:=$DOCUMENTS/Warcraft III}"
      export DOCUMENTS PROGRAM_FILES W3CHAMPIONS_HOME WARCRAFT_CONFIG_HOME

      mkdir -p "$WARCRAFT_CONFIG_HOME/CustomKeyBindings" "$W3CHAMPIONS_HOME"

      cat ${self}/War3Preferences.txt > "$WARCRAFT_CONFIG_HOME/War3Preferences.txt"
      cat ${self}/CustomKeys.txt > "$WARCRAFT_CONFIG_HOME/CustomKeyBindings/CustomKeys.txt"
      cat ${self}/W3Champions.bat > "$W3CHAMPIONS_HOME/W3Champions.bat"
    '';
  };

  w3c-maps = pkgs.writeShellApplication {
    name = "w3c-maps";
    text = ''
      ${wineEnv}

      : "''${DOCUMENTS:=$WINEPREFIX/drive_c/users/$USER/Documents}"
      : "''${WARCRAFT_CONFIG_HOME:=$DOCUMENTS/Warcraft III}"
      export DOCUMENTS WARCRAFT_CONFIG_HOME

      mkdir -p "$WARCRAFT_CONFIG_HOME/Maps/W3Champions"

      for map in ${self}/Maps/W3Champions/*; do
        cat "$map" > "$WARCRAFT_CONFIG_HOME/Maps/W3Champions/$(basename "$map")"
      done
    '';
  };

  warcraft-copy = pkgs.writeShellApplication {
    name = "warcraft-copy";
    text = ''
      ${wineEnv}

      : "''${PROGRAM_FILES86:=$WINEPREFIX/drive_c/Program Files (x86)}"
      : "''${WARCRAFT_HOME:=$PROGRAM_FILES86/Warcraft III}"
      : "''${WARCRAFT_PATH:=}"
      export PROGRAM_FILES86 WARCRAFT_HOME WARCRAFT_PATH

      if [[ -z "$WARCRAFT_PATH" ]]; then
        echo "WARCRAFT_PATH not set"
        exit 1
      fi

      if [[ ! -d "$WARCRAFT_PATH" ]]; then
        echo "WARCRAFT_PATH does not exist"
        exit 1
      fi

      if [[ ! -d "$WARCRAFT_HOME" ]]; then
        mkdir -p "$PROGRAM_FILES86"
        cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
      fi
    '';
  };

  w3c-login-bypass = pkgs.writeShellApplication {
    name = "w3c-login-bypass";
    runtimeInputs = [pkgs.rsync];
    text = ''
      ${wineEnv}

      : "''${W3C_AUTH_DATA:=}"
      : "''${USER_HOME:=$WINEPREFIX/drive_c/users/$USER}"
      : "''${W3C_DATA:=$USER_HOME/AppData/Local/com.w3champions.client}"
      export W3C_AUTH_DATA USER_HOME W3C_DATA

      if [[ -z "$W3C_AUTH_DATA" || ! -d "$W3C_AUTH_DATA" ]]; then
        echo "Invalid W3C_AUTH_DATA"
        exit 1
      fi

      mkdir -p "$W3C_DATA"
      rsync -av --delete "$W3C_AUTH_DATA/" "$W3C_DATA/"
    '';
  };

  cleanup-warcraft-wine = pkgs.writeShellApplication {
    name = "cleanup-warcraft-wine";
    text = ''
      echo "Cleaning up wine processes"
      for proc in Warcraft wine Microsoft mDNS; do
        pkill "$proc" || true
      done
    '';
  };

  download-webview = pkgs.writeShellApplication {
    name = "download-webview";
    runtimeInputs = [pkgs.curl];
    text = ''
      : "''${WEBVIEW2_SETUP_EXE:=$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe}"
      : "''${WEBVIEW2_DOWNLOAD_URL:=https://github.com/clemenscodes/W3ChampionsOnLinux/releases/download/proton-ge-9-27/MicrosoftEdgeWebView2RuntimeInstallerX64.exe}"
      export WEBVIEW2_SETUP_EXE WEBVIEW2_DOWNLOAD_URL

      mkdir -p "$HOME/Downloads"
      curl -L "$WEBVIEW2_DOWNLOAD_URL" -o "$WEBVIEW2_SETUP_EXE"
    '';
  };

  install-webview = pkgs.writeShellApplication {
    name = "install-webview";
    runtimeInputs = [download-webview cleanup-warcraft-wine pkgs.wine];
    text = ''
      ${wineEnv}

      : "''${WEBVIEW2_SETUP_EXE:=$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe}"
      : "''${PROGRAM_FILES86:=$WINEPREFIX/drive_c/Program Files (x86)}"
      : "''${WEBVIEW2_HOME:=$PROGRAM_FILES86/Microsoft/EdgeCore}"
      export WEBVIEW2_SETUP_EXE PROGRAM_FILES86 WEBVIEW2_HOME

      mkdir -p "$WINEPREFIX"

      if [[ ! -d "$WEBVIEW2_HOME" ]]; then
        [[ -f "$WEBVIEW2_SETUP_EXE" ]] || download-webview
        cleanup-warcraft-wine
        wine "$WEBVIEW2_SETUP_EXE"
        cleanup-warcraft-wine
        wine "$WINEPREFIX/drive_c/windows/regedit.exe" /S "${self}/msedgewebview2.exe.reg"
      fi
    '';
  };

  download-w3c = pkgs.writeShellApplication {
    name = "download-w3c";
    runtimeInputs = [pkgs.curl];
    text = ''
      : "''${W3CHAMPIONS_SETUP_EXE:=$HOME/Downloads/W3Champions_latest_x64_en-US.msi}"
      : "''${W3CHAMPIONS_DOWNLOAD_URL:=https://update-service.w3champions.com/api/launcher-e}"
      export W3CHAMPIONS_SETUP_EXE W3CHAMPIONS_DOWNLOAD_URL

      mkdir -p "$HOME/Downloads"
      curl -L "$W3CHAMPIONS_DOWNLOAD_URL" -o "$W3CHAMPIONS_SETUP_EXE"
    '';
  };

  install-w3c = pkgs.writeShellApplication {
    name = "install-w3c";
    runtimeInputs = [download-w3c cleanup-warcraft-wine install-webview pkgs.wine];
    text = ''
      ${wineEnv}

      : "''${W3CHAMPIONS_SETUP_EXE:=$HOME/Downloads/W3Champions_latest_x64_en-US.msi}"
      export W3CHAMPIONS_SETUP_EXE

      [[ -f "$W3CHAMPIONS_SETUP_EXE" ]] || download-w3c
      cleanup-warcraft-wine
      wine "$W3CHAMPIONS_SETUP_EXE"
    '';
  };

  download-battlenet = pkgs.writeShellApplication {
    name = "download-battlenet";
    runtimeInputs = [pkgs.curl];
    text = ''
      : "''${BNET_SETUP_EXE:=$HOME/Downloads/Battle.net-Setup.exe}"
      : "''${BNET_DOWNLOAD_URL:=https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe}"
      export BNET_SETUP_EXE BNET_DOWNLOAD_URL

      mkdir -p "$HOME/Downloads"
      curl -L "$BNET_DOWNLOAD_URL" -o "$BNET_SETUP_EXE"
    '';
  };

  install-battlenet = pkgs.writeShellApplication {
    name = "install-battlenet";
    runtimeInputs = [download-battlenet cleanup-warcraft-wine pkgs.wine];
    text = ''
      ${wineEnv}

      : "''${BNET_SETUP_EXE:=$HOME/Downloads/Battle.net-Setup.exe}"
      export BNET_SETUP_EXE

      [[ -f "$BNET_SETUP_EXE" ]] || download-battlenet
      cleanup-warcraft-wine
      wine "$BNET_SETUP_EXE"
    '';
  };

  battlenet = pkgs.writeShellApplication {
    name = "battlenet";
    runtimeInputs = [cleanup-warcraft-wine install-battlenet pkgs.wine];
    text = ''
      ${wineEnv}

      : "''${PROGRAM_FILES86:=$WINEPREFIX/drive_c/Program Files (x86)}"
      : "''${BNET_EXE:=$PROGRAM_FILES86/Battle.net/Battle.net.exe}"
      export PROGRAM_FILES86 BNET_EXE
      export VK_INSTANCE_LAYERS="VK_LAYER_WARCRAFT_overlay"
      export VK_LAYER_PATH="${self.packages.x86_64-linux.warcraft-vulkan-overlay}/share/vulkan/explicit_layer.d"

      [[ -f "$BNET_EXE" ]] || install-battlenet
      wine "$BNET_EXE"
    '';
  };

  warcraft = pkgs.writeShellApplication {
    name = "warcraft";
    runtimeInputs = [cleanup-warcraft-wine pkgs.wine];
    text = ''
      ${wineEnv}

      : "''${PROGRAM_FILES86:=$WINEPREFIX/drive_c/Program Files (x86)}"
      : "''${WARCRAFT_EXE:=$PROGRAM_FILES86/Warcraft III/_retail_/x86_64/Warcraft III.exe}"
      export PROGRAM_FILES86 WARCRAFT_EXE
      export VK_INSTANCE_LAYERS="VK_LAYER_WARCRAFT_overlay"
      export VK_LAYER_PATH="${self.packages.x86_64-linux.warcraft-vulkan-overlay}/share/vulkan/explicit_layer.d"

      [[ -f "$WARCRAFT_EXE" ]] || exit 0
      wine "$WARCRAFT_EXE" -launcher
    '';
  };
in {
  warcraft-install-scripts = pkgs.symlinkJoin {
    name = "warcraft-install-scripts";
    paths = [
      install-warcraft
      setup-warcraft-wine
      warcraft-settings
      w3c-maps
      warcraft-copy
      w3c-login-bypass
      cleanup-warcraft-wine
      download-webview
      install-webview
      download-w3c
      install-w3c
      download-battlenet
      install-battlenet
      battlenet
      warcraft
    ];
  };
}
