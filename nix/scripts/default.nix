{
  self,
  pkgs,
  ...
}: rec {
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
  focus-warcraft-game = pkgs.writeShellApplication {
    name = "focus-warcraft-game";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.socat
      pkgs.jq
      pkgs.libnotify
      warcraft-mode-start
      warcraft-mode-stop
    ];
    text = ''
      handle_fullscreen() {
        active_window="$(hyprctl activewindow)"
        if [ "$active_window" = "Invalid" ]; then
          active_workspace="$(hyprctl activeworkspace -j | jq .id)"
          if [ "$active_workspace" -ne 3 ]; then
            WARCRAFT_PID="$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "Warcraft III") | .pid' | head -n 1)"
            if [ -n "$WARCRAFT_PID" ]; then
              notify-send --expire-time 3000 "W3Champions match started!" --icon "${self}/assets/W3Champions.png"
              warcraft-mode-start
              sleep 5
              hyprctl --batch "dispatch focuswindow pid:$WARCRAFT_PID ; dispatch fullscreen 0"
            fi
          fi
        fi
      }

      handle_closewindow() {
        active_workspace="$(hyprctl activeworkspace -j | jq .id)"
        if [ "$active_workspace" -ne 2 ]; then
          W3C_PID="$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "W3Champions") | .pid' | head -n 1)"
          if [ -n "$W3C_PID" ]; then
            warcraft-mode-stop
            notify-send --expire-time 3000 "W3Champions match ended!" --icon "${self}/assets/W3Champions.png"
            hyprctl --batch "dispatch focuswindow pid:$W3C_PID"
          fi
        fi
      }

      handle() {
        case "$1" in
          fullscreen*) handle_fullscreen ;;
          closewindow*) handle_closewindow ;;
        esac
      }

      socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        handle "$line";
      done
    '';
  };
  kill-games = pkgs.writeShellApplication {
    name = "kill-games";
    text = ''
      for proc in main Warcraft wine Microsoft edge srt-bwrap exe Cr mDNS; do
        pkill "$proc" || true
      done
    '';
  };
  battlenet = pkgs.writeShellApplication {
    name = "battlenet";
    runtimeInputs = [
      pkgs.lutris
      pkgs.libnotify
      kill-games
    ];
    text = ''
      notify-send "Starting Battle.net" --icon "${self}/assets/Battle.net.png"

      kill-games

      LUTRIS_SKIP_INIT=1 lutris lutris:rungame/battlenet &
      GAME_PID="$!"

      (
        set +e
        while true; do
          PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "") | .pid' | head -n 1)
          if [ -n "$PID" ]; then
            sleep 0.1
            kill "$PID"
            break
          fi
        done
      ) &

      WATCHDOG_PID=$!

      wait "$WATCHDOG_PID"
      wait "$GAME_PID"
    '';
  };
  w3champions = pkgs.writeShellApplication {
    name = "w3champions";
    runtimeInputs = [
      pkgs.lutris
      pkgs.libnotify
      kill-games
      focus-warcraft-game
    ];
    text = ''
      kill-games

      notify-send "Starting W3Champions" --icon "${self}/assets/W3Champions.png"

      if ! pgrep obs > /dev/null 2>&1; then
        obs --disable-shutdown-check --multi --startreplaybuffer &
      fi

      LUTRIS_SKIP_INIT=1 lutris lutris:rungame/W3Champions &
      GAME_PID="$!"

      while true; do
        W3C_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "W3Champions") | .pid' | head -n 1)
        if [ -n "$W3C_PID" ]; then
          hyprctl --batch "dispatch focuswindow pid:$W3C_PID; dispatch resizeactive exact 1600 900 ; dispatch centerwindow"
          while true; do
            WARCRAFT_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "Warcraft III") | .pid' | head -n 1)
            if [ -n "$WARCRAFT_PID" ]; then
              hyprctl --batch "dispatch focuswindow pid:$W3C_PID; dispatch resizeactive exact 1600 900 ; dispatch centerwindow"
              break
            fi
          done
          break
        fi
      done

      focus-warcraft-game &
      GAME_WATCHDOG_PID="$!"

      wait "$GAME_PID"
      kill "$GAME_WATCHDOG_PID"
    '';
  };
  warcraft-mode-start = pkgs.writeShellApplication {
    name = "warcraft-mode-start";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-mode-stop = pkgs.writeShellApplication {
    name = "warcraft-mode-stop";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap reset
    '';
  };
  warcraft-chat-open = pkgs.writeShellApplication {
    name = "warcraft-chat-open";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      ydotool key 96:1 96:0
      hyprctl dispatch submap CHAT
    '';
  };
  warcraft-chat-send = pkgs.writeShellApplication {
    name = "warcraft-chat-send";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      ydotool key 96:1 96:0
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-chat-close = pkgs.writeShellApplication {
    name = "warcraft-chat-close";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.ydotool
    ];
    text = ''
      ydotool key 1:1 1:0
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-autocast-hotkey = pkgs.writeShellApplication {
    name = "warcraft-autocast-hotkey";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            HOTKEY="$1"
            shift
            ;;
        esac
      done

      echo "Activating autocast hotkey $HOTKEY" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$HOTKEY" in
        Q) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); ;;
        W) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); ;;
        E) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); ;;
        R) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); ;;
        A) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); ;;
        S) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); ;;
        D) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); ;;
        F) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); ;;
        Y) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); ;;
        X) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); ;;
        C) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); ;;
        V) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and clicking right mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC1
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-inventory-hotkey = pkgs.writeShellApplication {
    name = "warcraft-inventory-hotkey";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            HOTKEY="$1"
            shift
            ;;
        esac
      done

      echo "Activating inventory hotkey $HOTKEY" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$HOTKEY" in
        1) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
        2) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
        3) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
        4) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
        5) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
        6) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and clicking left mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-write-control-group = pkgs.writeShellApplication {
    name = "warcraft-write-control-group";
    excludeShellChecks = ["SC2046" "SC2086"];
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap CONTROLGROUP

      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP="$1"

      echo "$CONTROL_GROUP" > "$WARCRAFT_HOME/control_group"

      case "$CONTROL_GROUP" in
        1) CONTROL_GROUP_KEYCODE=2 ;;
        2) CONTROL_GROUP_KEYCODE=3 ;;
        3) CONTROL_GROUP_KEYCODE=4 ;;
        4) CONTROL_GROUP_KEYCODE=5 ;;
        5) CONTROL_GROUP_KEYCODE=6 ;;
        6) CONTROL_GROUP_KEYCODE=7 ;;
        7) CONTROL_GROUP_KEYCODE=8 ;;
        8) CONTROL_GROUP_KEYCODE=9 ;;
        9) CONTROL_GROUP_KEYCODE=10 ;;
        0) CONTROL_GROUP_KEYCODE=11 ;;
      esac

      echo "Selecting control group $CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"
      echo "Writing control group keycode" >> "YDOTOOL_LOG_FILE"
      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      sleep 0.1

      ydotool key "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-create-control-group = pkgs.writeShellApplication {
    name = "warcraft-create-control-group";
    excludeShellChecks = ["SC2046" "SC2086"];
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap CONTROLGROUP

      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP="$1"

      echo "$CONTROL_GROUP" > "$WARCRAFT_HOME/control_group"

      case "$CONTROL_GROUP" in
        1) CONTROL_GROUP_KEYCODE=2 ;;
        2) CONTROL_GROUP_KEYCODE=3 ;;
        3) CONTROL_GROUP_KEYCODE=4 ;;
        4) CONTROL_GROUP_KEYCODE=5 ;;
        5) CONTROL_GROUP_KEYCODE=6 ;;
        6) CONTROL_GROUP_KEYCODE=7 ;;
        7) CONTROL_GROUP_KEYCODE=8 ;;
        8) CONTROL_GROUP_KEYCODE=9 ;;
        9) CONTROL_GROUP_KEYCODE=10 ;;
        0) CONTROL_GROUP_KEYCODE=11 ;;
      esac

      echo "Creating control group $CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"
      echo "Writing control group keycode" >> "$YDOTOOL_LOG_FILE"
      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      sleep 0.1

      ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-edit-unit-control-group = pkgs.writeShellApplication {
    name = "warcraft-edit-unit-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP_KEYCODE_FILE="$WARCRAFT_HOME/control_group_keycode"
      CONTROL_GROUP_KEYCODE="$(cat "$CONTROL_GROUP_KEYCODE_FILE")"

      echo "Editing unit from control group" >> "$YDOTOOL_LOG_FILE"

      hyprctl dispatch submap CONTROLGROUP

      sleep 0.1

      ydotool key 42:1
      ydotool click 0xC0
      ydotool key 42:0
      ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-select-unit = pkgs.writeShellApplication {
    name = "warcraft-select-unit";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            SELECTED_UNIT="$1"
            shift
            ;;
        esac
      done

      echo "Selecting unit $SELECTED_UNIT from current control group" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$SELECTED_UNIT" in
        1) X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        2) X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        3) X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        4) X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        5) X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        6) X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); ;;
        7) X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
        8) X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
        9) X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
        10) X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
        11) X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
        12) X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and double clicking left mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
}
