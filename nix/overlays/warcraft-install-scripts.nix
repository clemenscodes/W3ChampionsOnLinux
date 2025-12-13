{
  self,
  pkgs,
  ...
}: let
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
      export W3C_AUTH_DATA="''${W3C_AUTH_DATA:-}"
      export WARCRAFT_PATH="''${WARCRAFT_PATH:-}"
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
    runtimeInputs = [
      pkgs.wine
      pkgs.winetricks-compat
      pkgs.winetricks
    ];
    text = ''
      echo "Setting up wine prefix for Warcraft III"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
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
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export W3CHAMPIONS_HOME="$PROGRAM_FILES/W3Champions"
      export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"
      mkdir -p "$WARCRAFT_CONFIG_HOME/CustomKeyBindings" "$W3CHAMPIONS_HOME"
      echo "Installing Warcraft III settings..."
      cat ${self}/War3Preferences.txt > "$WARCRAFT_CONFIG_HOME/War3Preferences.txt"
      echo "Installing Warcraft III hotkeys..."
      cat ${self}/CustomKeys.txt > "$WARCRAFT_CONFIG_HOME/CustomKeyBindings/CustomKeys.txt"
    '';
  };
  w3c-maps = pkgs.writeShellApplication {
    name = "w3c-maps";
    text = ''
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export W3CHAMPIONS_HOME="$PROGRAM_FILES/W3Champions"
      export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"
      mkdir -p "$WARCRAFT_CONFIG_HOME/Maps/W3Champions"
      for map in ${self}/Maps/W3Champions/*; do
        cat "$map" > "$WARCRAFT_CONFIG_HOME/Maps/W3Champions/$(basename "$map")"
      done
    '';
  };
  warcraft-copy = pkgs.writeShellApplication {
    name = "warcraft-copy";
    text = ''
      function warcraft_copy() {
        export WINEPATH="$HOME/Games"
        export WINEPREFIX="$WINEPATH/W3Champions"
        export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
        export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
        export WARCRAFT_PATH="''${WARCRAFT_PATH:-}"
        if [[ -z "$WARCRAFT_PATH" ]]; then
          echo "Error: WARCRAFT_PATH is not set. Aborting."
          return
        fi

        if [[ ! -d "$WARCRAFT_PATH" ]]; then
          echo "Error: Source directory '$WARCRAFT_PATH' does not exist. Aborting."
          return
        fi

        if [ ! -d "$WARCRAFT_HOME" ]; then
          echo "Warcraft III is not installed..."
          if [ -n "$WARCRAFT_PATH" ]; then
            echo "Copying $WARCRAFT_PATH to $WARCRAFT_HOME"
            mkdir -p "$PROGRAM_FILES86"
            cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
            echo "Finished installing Warcraft III"
          else
            echo "You can provide the installer with an existing Warcraft III installation."
            echo "Pass WARCRAFT_PATH environment variable to the script pointing to an existing install of Warcraft III."
          fi
        else
          echo "Warcraft III is already installed. Done."
        fi
      }

      warcraft_copy
    '';
  };
  w3c-login-bypass = pkgs.writeShellApplication {
    name = "w3c-login-bypass";
    runtimeInputs = [
      pkgs.rsync
    ];
    text = ''
      function w3c_login_bypass() {
        export WINEPATH="$HOME/Games"
        export WINEPREFIX="$WINEPATH/W3Champions"
        export USER_HOME="$WINEPREFIX/drive_c/users/$USER"
        export APPDATA="$USER_HOME/AppData"
        export APPDATA_LOCAL="$APPDATA/Local"
        export W3C_DATA="$APPDATA_LOCAL/com.w3champions.client"
        export W3C_AUTH_DATA="''${W3C_AUTH_DATA:-}"

        if [[ -z "$W3C_AUTH_DATA" ]]; then
          echo "Error: W3C_AUTH_DATA is not set. Aborting."
          return
        fi

        if [[ ! -d "$W3C_AUTH_DATA" ]]; then
          echo "Error: Source directory '$W3C_AUTH_DATA' does not exist. Aborting."
          return
        fi

        mkdir -p "$W3C_DATA"

        rsync -av --delete "$W3C_AUTH_DATA/" "$W3C_DATA/"
      }

      w3c_login_bypass
    '';
  };
  cleanup-warcraft-wine = pkgs.writeShellApplication {
    name = "cleanup-warcraft-wine";
    text = ''
      echo "Cleaning up wine for Warcraft III"
      for proc in main Warcraft wine Microsoft srt-bwrap exe Cr mDNS; do
        pkill "$proc" || true
      done
    '';
  };
  download-webview = pkgs.writeShellApplication {
    name = "download-webview";
    runtimeInputs = [
      pkgs.curl
    ];
    text = ''
      echo "Downloading WebView2"
      export WEBVIEW2_SETUP_EXE="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
      export WEBVIEW2_DOWNLOAD_URL="https://github.com/clemenscodes/W3ChampionsOnLinux/releases/download/proton-ge-9-27/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
      mkdir -p "$HOME/Downloads"
      curl -L "$WEBVIEW2_DOWNLOAD_URL" --output "$WEBVIEW2_SETUP_EXE"
    '';
  };
  install-webview = pkgs.writeShellApplication {
    name = "install-webview";
    runtimeInputs = [
      download-webview
      cleanup-warcraft-wine
      pkgs.wine
    ];
    text = ''
      echo "Installing WebView2"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export WEBVIEW2_SETUP_EXE="$HOME/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeCore"

      mkdir -p "$WINEPREFIX"

      if [ ! -d "$WEBVIEW2_HOME" ]; then
        if [ ! -f "$WEBVIEW2_SETUP_EXE" ]; then
          download-webview
        fi

        echo "Installing WebView2 runtime... sit back and wait until it finishes."
        echo "There should be no errors."
        echo "If an error occurs, you might have an incompatible GPU or Vulkan driver."
        cleanup-warcraft-wine
        wine "$WEBVIEW2_SETUP_EXE" &
        INSTALL_PID="$!"

        (
          set +e
          echo "Monitoring webview2 installation process..."
          while true; do
            microsoft_process_count=$(pgrep -la Microsoft | wc -l)
            if [ "$microsoft_process_count" -gt 1 ]; then
              echo "Waiting for WebView2 installation to finish..."
              while true; do
                microsoft_process_count=$(pgrep -la Microsoft | wc -l)
                echo "Microsoft processes running: $microsoft_process_count"
                if [ "$microsoft_process_count" -eq 1 ]; then
                  echo "Killing all Microsoft processes"
                  pkill MicrosoftEdgeUp || true
                  break
                fi
                sleep 1
                if [ "$microsoft_process_count" -eq 0 ]; then
                  break
                fi
              done
              break
            fi
            sleep 1
          done
        ) &

        WATCHDOG_PID=$!

        wait "$INSTALL_PID"
        INSTALL_EXIT_CODE="$?"

        wait "$WATCHDOG_PID"

        if [ "$INSTALL_EXIT_CODE" -ne 0 ]; then
          echo "WebView2 installer failed with exit code $INSTALL_EXIT_CODE"
          exit 1
        fi

        if [ ! -d "$WEBVIEW2_HOME" ]; then
          echo "Failed installing WebView2 runtime... you might have the wrong wine version installed."
          echo "Recommended is at least wine 10.16"
          exit 1
        fi

        echo "Finished installing WebView2 runtime"
        echo "Fixing black screens for windows using the WebView2 runtime..."

        cleanup-warcraft-wine

        echo "Setting msedgewebview2.exe to Windows 7..."
        wine "$WINEPREFIX/drive_c/windows/regedit.exe" /S "${self}/msedgewebview2.exe.reg"
        echo "Done. WebView2 applications should render properly now."
      else
        echo "WebView2 is already installed."
      fi
    '';
  };
  download-w3c = pkgs.writeShellApplication {
    name = "download-w3c";
    runtimeInputs = [
      pkgs.curl
    ];
    text = ''
      echo "Downloading W3Champions"
      export W3CHAMPIONS_SETUP_EXE="$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
      export W3CHAMPIONS_DOWNLOAD_URL="https://update-service.w3champions.com/api/launcher-e"
      mkdir -p "$HOME/Downloads"
      curl -L "$W3CHAMPIONS_DOWNLOAD_URL" --output "$W3CHAMPIONS_SETUP_EXE"
    '';
  };
  install-w3c = pkgs.writeShellApplication {
    name = "install-w3c";
    runtimeInputs = [
      download-w3c
      cleanup-warcraft-wine
      install-webview
      pkgs.wine
    ];
    text = ''
      echo "Installing W3Champions"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export W3CHAMPIONS_SETUP_EXE="$HOME/Downloads/W3Champions_latest_x64_en-US.msi"
      if [ ! -f "$W3CHAMPIONS_SETUP_EXE" ]; then
        install-webview
        download-w3c
      fi
      mkdir -p "$WINEPREFIX"
      cleanup-warcraft-wine
      wine "$W3CHAMPIONS_SETUP_EXE"
    '';
  };
  download-battlenet = pkgs.writeShellApplication {
    name = "download-battlenet";
    runtimeInputs = [
      pkgs.curl
    ];
    text = ''
      echo "Downloading Battle.net"
      export BNET_DOWNLOAD_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
      export BNET_SETUP_EXE="$HOME/Downloads/Battle.net-Setup.exe"
      mkdir -p "$HOME/Downloads"
      curl -L "$BNET_DOWNLOAD_URL" --output "$BNET_SETUP_EXE"
    '';
  };
  install-battlenet = pkgs.writeShellApplication {
    name = "install-battlenet";
    runtimeInputs = [
      download-battlenet
      cleanup-warcraft-wine
      pkgs.wine
    ];
    text = ''
      echo "Installing Battle.net"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export BNET_SETUP_EXE="$HOME/Downloads/Battle.net-Setup.exe"
      if [ ! -f "$BNET_SETUP_EXE" ]; then
        download-battlenet
      fi
      mkdir -p "$WINEPREFIX"
      cleanup-warcraft-wine
      wine "$BNET_SETUP_EXE"
    '';
  };
  battlenet = pkgs.writeShellApplication {
    name = "battlenet";
    runtimeInputs = [
      cleanup-warcraft-wine
      install-battlenet
      pkgs.wine
    ];
    text = ''
      echo "Running Battle.net"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export BNET_HOME="$PROGRAM_FILES86/Battle.net"
      export BNET_EXE="$BNET_HOME/Battle.net.exe"
      if [ ! -f "$BNET_EXE" ]; then
        install-battlenet
      fi
      wine "$BNET_EXE"
    '';
  };
  warcraft = pkgs.writeShellApplication {
    name = "warcraft";
    runtimeInputs = [
      cleanup-warcraft-wine
      pkgs.wine
    ];
    text = ''
      echo "Running Warcraft III"
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
      export WARCRAFT_EXE="$WARCRAFT_HOME/_retail_/x86_64/Warcraft III.exe"
      if [ ! -f "$WARCRAFT_EXE" ]; then
        exit 0
      fi
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
      install-webview
      download-webview
      install-w3c
      download-w3c
      download-battlenet
      install-battlenet
      battlenet
      warcraft
    ];
  };
}
