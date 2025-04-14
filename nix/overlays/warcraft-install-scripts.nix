{
  self,
  pkgs,
  ...
}: let
  lutris-install-warcraft = pkgs.writeShellApplication {
    name = "lutris-install-warcraft";
    runtimeInputs = [
      pkgs.lutris
    ];
    text = ''
      lutris -i ${self}/W3Champions.yaml &
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
        echo "Failed to install W3Champions"
        exit 1
      fi

      if [ ! -d "$WEBVIEW2_HOME" ]; then
        echo "Failed installing WebView2 runtime... you might have the wrong Proton-GE version installed."
        echo "Recommended is at least Proton-GE-9-26".
        exit 1
      fi

      echo "Finished installing W3Champions"
    '';
  };
  install-webview2 = pkgs.writeShellApplication {
    name = "install-webview2";
    runtimeInputs = [
      pkgs.curl
      pkgs.umu-launcher
      pkgs.zenity
    ];
    text = ''
      export PROTON_VERB=run

      export WINEARCH="win64"
      export WINEDEBUG="-all"
      export WINEPREFIX=$HOME/Games/W3Champions

      export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export WEBVIEW2_SETUP_EXE="$DOWNLOADS/MicrosoftEdgeWebview2Setup.exe"
      export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeCore"
      export WEBVIEW2_URL="https://go.microsoft.com/fwlink/?linkid=2124703"

      if [ ! -d "$WEBVIEW2_HOME" ]; then
        if [ ! -f "$WEBVIEW2_SETUP_EXE" ]; then
          echo "Downloading WebView2 runtime installer..."
          mkdir -p "$DOWNLOADS"
          curl -L "$WEBVIEW2_URL" -o "$WEBVIEW2_SETUP_EXE"
        fi

        echo "Installing WebView2 runtime... sit back and wait until it finishes."
        echo "There should be no errors."
        echo "If an error occurs, you might have an incompatible GPU or Vulkan driver."
        umu-run "$WEBVIEW2_SETUP_EXE" &
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
          echo "Failed installing WebView2 runtime... you might have the wrong Proton-GE version installed."
          echo "Recommended is at least Proton-GE-9-26".
          exit 1
        fi

        echo "Finished installing WebView2 runtime"

        echo "Fixing black screens for windows using the WebView2 runtime..."
        echo "Setting msedgewebview2.exe to Windows 7..."

        (
          set +e
          while true; do
            microsoft_process_count=$(pgrep -la Microsoft | wc -l)
            if [ "$microsoft_process_count" -gt 0 ]; then
              pkill Microsoft || true
              break
            fi
            sleep 1
          done
        ) &

        WATCHDOG_PID=$!

        umu-run "$WINEPREFIX/drive_c/windows/regedit.exe" /S "${self}/msedgewebview2.exe.reg" &
        REGEDIT_PID="$!"

        wait "$REGEDIT_PID"
        wait "$WATCHDOG_PID"

        echo "Done. WebView2 applications should render properly now."
        echo "If they are rendered black, repeat this step and check your GPU."
      fi
    '';
  };
  install-w3champions = pkgs.writeShellApplication {
    name = "install-w3champions";
    runtimeInputs = [
      pkgs.curl
      pkgs.umu-launcher
      pkgs.zenity
    ];
    text = ''
      export PROTON_VERB=run

      export WINEPREFIX=$HOME/Games/W3Champions
      export WINEARCH="win64"
      export WINEDEBUG="-all"

      export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
      export W3C_SETUP_MSI="$DOWNLOADS/W3Champions_latest_x64_en-US.msi"
      export W3C_SETUP_URL="https://update-service.w3champions.com/api/launcher-e"

      if [ ! -f "$W3C_EXE" ]; then
        if [ ! -f "$W3C_SETUP_MSI" ]; then
          echo "Downloading W3Champions installer..."
          mkdir -p "$DOWNLOADS"
          curl -L "$W3C_SETUP_URL" -o "$W3C_SETUP_MSI"
        fi

        (
          set +e
          while true; do
            microsoft_process_count=$(pgrep -la Microsoft | wc -l)
            if [ "$microsoft_process_count" -gt 0 ]; then
              pkill Microsoft || true
              break
            fi
            sleep 1
          done
        ) &

        WATCHDOG_PID=$!

        echo "Installing W3Champions..."
        umu-run "$W3C_SETUP_MSI" &
        W3C_PID="$!"

        wait "$W3C_PID"
        wait "$WATCHDOG_PID"

        if [ ! -f "$W3C_EXE" ]; then
          echo "Failed installing W3Champions."
          exit 1
        fi

        echo "Finished installing W3Champions."
      fi
    '';
  };
  install-w3champions-legacy = pkgs.writeShellApplication {
    name = "install-w3champions-legacy";
    runtimeInputs = [
      pkgs.curl
      pkgs.umu-launcher
      pkgs.zenity
    ];
    text = ''
      export PROTON_VERB=run

      export WINEARCH="win64"
      export WINEDEBUG="-all"
      export WINEPREFIX=$HOME/Games/W3Champions

      export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
      export APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData"
      export APPDATA_LOCAL="$APPDATA/Local"
      export W3C_LEGACY_EXE="$APPDATA_LOCAL/Programs/w3champions/w3champions.exe"
      export W3C_LEGACY_SETUP_EXE="$DOWNLOADS/w3c-setup.exe"
      export W3C_LEGACY_SETUP_URL="https://update-service.w3champions.com/api/launcher/win"

      if [ ! -f "$W3C_LEGACY_EXE" ]; then
        if [ ! -f "$W3C_LEGACY_SETUP_EXE" ]; then
          echo "Downloading W3Champions installer..."
          mkdir -p "$DOWNLOADS"
          curl -L "$W3C_LEGACY_SETUP_URL" -o "$W3C_LEGACY_SETUP_EXE"
        fi

        echo "Installing legacy W3Champions..."
        umu-run "$W3C_LEGACY_SETUP_EXE"

        if [ ! -f "$W3C_LEGACY_EXE" ]; then
          echo "Failed installing legacy W3Champions."
          exit 1
        fi

        echo "Finished installing legacy W3Champions."
      fi
    '';
  };
  bonjour = pkgs.writeShellApplication {
    name = "bonjour";
    runtimeInputs = [
      pkgs.umu-launcher
      pkgs.zenity
    ];
    text = ''
      export PROTON_VERB=run

      export WINEARCH="win64"
      export WINEDEBUG="-all"
      export WINEPREFIX=$HOME/Games/W3Champions

      umu-run "$WINEPREFIX/drive_c/windows/system32/net.exe" stop 'Bonjour Service'
      umu-run "$WINEPREFIX/drive_c/windows/system32/net.exe" start 'Bonjour Service'
    '';
  };
  install-warcraft = pkgs.writeShellApplication {
    name = "install-warcraft";
    runtimeInputs = [
      install-webview2
      install-w3champions
    ];
    text = ''
      export PROTON_VERB=run

      export WINEARCH="win64"
      export WINEDEBUG="-all"
      export WINEPREFIX=$HOME/Games/W3Champions

      export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
      export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData"
      export APPDATA_LOCAL="$APPDATA/Local"
      export APPDATA_ROAMING="$APPDATA/Roaming"

      export WARCRAFT_PATH="''${WARCRAFT_PATH:-}"
      export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
      export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

      export WEBVIEW2_SETUP_EXE="$DOWNLOADS/MicrosoftEdgeWebview2Setup.exe"
      export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeCore"
      export WEBVIEW2_URL="https://go.microsoft.com/fwlink/?linkid=2124703"

      export W3C_LEGACY_SETUP_EXE="$DOWNLOADS/w3c-setup.exe"
      export W3C_LEGACY_EXE="$APPDATA_LOCAL/Programs/w3champions/w3champions.exe"
      export W3C_LEGACY_URL="https://update-service.w3champions.com/api/launcher/win"

      export W3C_SETUP_EXE="$DOWNLOADS/W3Champions_latest_x64_en-US.msi"
      export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
      export W3C_APPDATA="$APPDATA_LOCAL/com.w3champions.client"
      export W3C_URL="https://update-service.w3champions.com/api/launcher-e"

      if [ ! -d "$WINEPREFIX" ]; then
        echo "Creating wine prefix..."
        mkdir -p "$WINEPREFIX"
      fi

      install-webview2

      if [ ! -d "$WARCRAFT_HOME" ]; then
        echo "Warcraft III is not installed..."
        if [ -n "$WARCRAFT_PATH" ]; then
          echo "Copying $WARCRAFT_PATH to $WARCRAFT_HOME"
          cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
          rm -rf "$WARCRAFT_HOME/_retail_/webui" || true
          echo "Finished installing Warcraft III"
        else
          echo "You can provide the installer with an existing Warcraft III installation."
          echo "Pass WARCRAFT_HOME environment variable to the script pointing to an existing install of Warcraft III."
        fi
      fi

      install-w3champions
    '';
  };
  warcraft-settings = pkgs.writeShellApplication {
    name = "warcraft-settings";
    text = ''
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
      export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

      mkdir -p "$WARCRAFT_CONFIG_HOME/CustomKeyBindings"

      echo "Installing Warcraft III settings..."
      cat ${self}/War3Preferences.txt > "$WARCRAFT_CONFIG_HOME/War3Preferences.txt"
      echo "Installing Warcraft III hotkeys..."
      cat ${self}/CustomKeys.txt > "$WARCRAFT_CONFIG_HOME/CustomKeyBindings/CustomKeys.txt"
      echo "Installing W3Champions.bat with Bonjour workarounds..."
      cat ${self}/W3Champions.bat > "$W3CHAMPIONS_HOME/W3Champions.bat"
    '';
  };
  warcraft-copy = pkgs.writeShellApplication {
    name = "warcraft-copy";
    text = ''
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export WINEARCH="win64"
      export WINEDEBUG="-all"
      export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
      export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
      export WARCRAFT_PATH="''${WARCRAFT_PATH:-}"

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
    '';
  };
  w3c-login-bypass = pkgs.writeShellApplication {
    name = "w3c-login-bypass";
    runtimeInputs = [
      pkgs.rsync
    ];
    text = ''
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

      rsync -av --delete "$W3C_AUTH_DATA/" "$W3C_DATA/"
    '';
  };
in {
  warcraft-install-scripts = pkgs.symlinkJoin {
    name = "warcraft-install-scripts";
    paths = [
      install-webview2
      install-w3champions
      install-w3champions-legacy
      bonjour
      install-warcraft
      lutris-install-warcraft
      warcraft-settings
      warcraft-copy
      w3c-login-bypass
    ];
  };
}
