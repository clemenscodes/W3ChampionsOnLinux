{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    webview2 = pkgs.writeShellApplication {
      name = "webview2";
      runtimeInputs = [
        pkgs.curl
        pkgs.umu-launcher
        pkgs.zenity
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

        export WINEARCH="win64"
        export WINEDEBUG="-all"
        export WINEPREFIX=$HOME/Games/W3Champions

        export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
        export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
        export WEBVIEW2_SETUP_EXE="$DOWNLOADS/MicrosoftEdgeWebview2Setup.exe"
        export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeWebView/Application"
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
            while true; do
              microsoft_process_count=$(pgrep -la Microsoft | wc -l)
              if [ "$microsoft_process_count" -gt 1 ]; then
                echo "Waiting for WebView2 installation to finish..."
                sleep 1
                while true; do
                  microsoft_process_count=$(pgrep -la Microsoft | wc -l)
                  if [ "$microsoft_process_count" -eq 1 ]; then
                    pkill Microsoft || true
                    pkill edge || true
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
    battlenet = pkgs.writeShellApplication {
      name = "battlenet";
      runtimeInputs = [
        pkgs.curl
        pkgs.umu-launcher
        pkgs.zenity
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

        export WINEARCH="win64"
        export WINEDEBUG="-all"
        export WINEPREFIX=$HOME/Games/W3Champions

        export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
        export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
        export BNET_EXE="$PROGRAM_FILES86/Battle.net/Battle.net.exe"
        export BNET_SETUP_EXE="$DOWNLOADS/BattleNet-Setup.exe"
        export BATTLENET_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"

        if [ ! -f "$BNET_EXE" ]; then
          if [ ! -f "$BNET_SETUP_EXE" ]; then
            echo "Downloading Battle.net Launcher..."
            mkdir -p "$DOWNLOADS"
            curl -L "$BATTLENET_URL" -o "$BNET_SETUP_EXE"
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

          echo "Installing Battle.net..."
          echo "Run Warcraft III at least once before you start W3Champions."
          echo "Then close Warcraft III and Battle.net to proceed."
          umu-run "$BNET_SETUP_EXE" &
          BATTLE_NET_PID="$!"

          wait "$BATTLE_NET_PID"
          wait "$WATCHDOG_PID"

          if [ ! -f "$BNET_EXE" ]; then
            echo "Failed installing Battle.net."
            exit 1
          fi

          echo "Finished installing Battle.net."
        fi
      '';
    };
    w3champions = pkgs.writeShellApplication {
      name = "w3champions";
      runtimeInputs = [
        pkgs.curl
        pkgs.umu-launcher
        pkgs.zenity
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

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
          echo "Do not launch W3Champions after the installation finishes."
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
    w3champions-legacy = pkgs.writeShellApplication {
      name = "w3champions-legacy";
      runtimeInputs = [
        pkgs.curl
        pkgs.umu-launcher
        pkgs.zenity
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

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
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

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
        pkgs.curl
        pkgs.umu-launcher
        webview2
        battlenet
        w3champions
        bonjour
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

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
        export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeWebView/Application"
        export WEBVIEW2_URL="https://go.microsoft.com/fwlink/?linkid=2124703"

        export BNET_SETUP_EXE="$DOWNLOADS/BattleNet-Setup.exe"
        export BNET_EXE="$PROGRAM_FILES86/Battle.net/Battle.net.exe"
        export BATTLENET_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"

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

        webview2

        if [ ! -d "$WARCRAFT_HOME" ]; then
          echo "Warcraft III is not installed..."
          echo "You can provide the installer with an existing Warcraft III installation."
          echo "Pass WARCRAFT_HOME environment variable to the script pointing to an existing install of Warcraft III."
          if [ -n "$WARCRAFT_PATH" ]; then
            echo "Copying $WARCRAFT_PATH to $WARCRAFT_HOME"
            cp -r "$WARCRAFT_PATH" "$WARCRAFT_HOME"
            rm -rf "$WARCRAFT_HOME/_retail_/webui" || true
            echo "Finished installing Warcraft III"
          fi
        fi

        battlenet
        w3champions
      '';
    };
    warcraft = pkgs.writeShellApplication {
      name = "warcraft";
      runtimeInputs = [
        install-warcraft
        pkgs.umu-launcher
      ];
      text = ''
        export PROTON_VERB=run
        export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
        export PROTONFIXES_DISABLE=0
        export UMU_LOG=0
        export UMU_ZENITY=1
        export UMU_RUNTIME_UPDATE=1
        export STORE=none
        export GAMEID=w3champions

        export WINEPATH="$HOME/Games"
        export WINEPREFIX="$WINEPATH/W3Champions"
        export WINEARCH="win64"
        export WINEDEBUG="-all"

        export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
        export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"

        install-warcraft

        (
          set +e
          while true; do
            microsoft_process_count=$(pgrep -la Microsoft | wc -l)
            if [ "$microsoft_process_count" -gt 0 ]; then
              pkill Microsoft || true
            fi
            sleep 1
          done
        ) &

        WATCHDOG_PID=$!

        echo "Running W3Champions..."
        umu-run "$W3C_EXE" &
        W3C_PID="$!"

        wait "$W3C_PID"
        wait "$WATCHDOG_PID"
      '';
    };
  in {
    packages = {
      ${system} = {
        inherit
          webview2
          battlenet
          w3champions
          w3champions-legacy
          bonjour
          install-warcraft
          warcraft
          ;
        default = self.packages.${system}.warcraft;
      };
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          buildInputs = [
            webview2
            battlenet
            w3champions
            w3champions-legacy
            bonjour
            install-warcraft
            warcraft
          ];
          nativeBuildInputs = [
            pkgs.curl
            pkgs.umu-launcher
          ];
          shellHook = ''
            export PROTON_VERB=run
            export PROTONPATH="${pkgs.proton-ge-bin.steamcompattool}"
            export PROTONFIXES_DISABLE=0
            export UMU_LOG=0
            export UMU_ZENITY=1
            export UMU_RUNTIME_UPDATE=1
            export STORE=none
            export GAMEID=w3champions

            export WINEPATH="$HOME/Games"
            export WINEPREFIX="$WINEPATH/W3Champions"
            export WINEARCH="win64"
            export WINEDEBUG="-all"

            export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
            export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
            export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
            export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
            export APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData"
            export APPDATA_LOCAL="$APPDATA/Local"
            export APPDATA_ROAMING="$APPDATA/Roaming"

            export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
            export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

            export WEBVIEW2_SETUP_EXE="$DOWNLOADS/MicrosoftEdgeWebview2Setup.exe"
            export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeWebView/Application"
            export WEBVIEW2_URL="https://go.microsoft.com/fwlink/?linkid=2124703"

            export BNET_SETUP_EXE="$DOWNLOADS/BattleNet-Setup.exe"
            export BNET_EXE="$PROGRAM_FILES86/Battle.net/Battle.net.exe"
            export BATTLENET_URL="https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"

            export W3C_LEGACY_SETUP_EXE="$DOWNLOADS/w3c-setup.exe"
            export W3C_LEGACY_EXE="$APPDATA_LOCAL/Programs/w3champions/w3champions.exe"
            export W3C_LEGACY_URL="https://update-service.w3champions.com/api/launcher/win"

            export W3C_SETUP_EXE="$DOWNLOADS/W3Champions_latest_x64_en-US.msi"
            export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
            export W3C_APPDATA="$APPDATA_LOCAL/com.w3champions.client"
            export W3C_URL="https://update-service.w3champions.com/api/launcher-e"
          '';
        };
      };
    };
  };
}
