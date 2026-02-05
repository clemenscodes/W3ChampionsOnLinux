{
  self,
  pkgs,
  ...
}: let
  kill-games = pkgs.writeShellApplication {
    name = "kill-games";
    text = ''
      for proc in main Warcraft warcraft focus wine Microsoft edge srt-bwrap exe Cr mDNS; do
        pkill "$proc" || true
      done
    '';
  };
  focus-warcraft-game = pkgs.writeShellApplication {
    name = "focus-warcraft-game";
    runtimeInputs = [pkgs.hyprland pkgs.socat pkgs.jq warcraft-mode-start warcraft-mode-stop];
    text = ''
      SCREEN_WIDTH="$(hyprctl monitors -j | jq -r '.[] | .width')"
      SCREEN_HEIGHT="$(hyprctl monitors -j | jq -r '.[] | .height')"
      X=$((SCREEN_WIDTH * 8 / 10))
      Y=$((SCREEN_HEIGHT * 8 / 10))
      WARCRAFT_ADDRESS=""
      W3CHAMPIONS_ADDRESS=""
      W3CHAMPIONS_PID=""
      EXPLORER_PID=""
      ACTIVE_WINDOW=""
      socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        case "$line" in
          closewindow*)
            address="$(echo "$line" | awk -F '>>' '{print $2}')"
            if [ "0x$address" = "$WARCRAFT_ADDRESS" ]; then
              warcraft-mode-stop
              W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
              if [ -n "$W3CHAMPIONS_PID" ]; then
                hyprctl --batch "dispatch focuswindow pid:$W3CHAMPIONS_PID; dispatch resizeactive exact $X $Y; dispatch centerwindow" >/dev/null
              fi
            fi
            if [ "$address" = "$WARCRAFT_ADDRESS" ]; then
              warcraft-mode-stop
              W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
              if [ -n "$W3CHAMPIONS_PID" ]; then
                hyprctl --batch "dispatch focuswindow pid:$W3CHAMPIONS_PID; dispatch resizeactive exact $X $Y; dispatch centerwindow" >/dev/null
              fi
            fi
            ;;
          activewindow*)
            ACTIVE_WINDOW="$(echo "$line" | awk -F '>>' '{print $2}' | awk -F ',' '{print $1}')"
            case "$ACTIVE_WINDOW" in
              w3champions.exe*)
                W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
                ;;
            esac
            ;;
          openwindow*)
            case "$line" in
              *Warcraft*)
                WARCRAFT_ADDRESS="$(echo "$line" | awk -F '>>' '{print $2}' | awk -F ',' '{print $1}')"
                WARCRAFT_PID="$(hyprctl clients -j | jq -r '.[] | select(.class == "warcraft iii.exe" and .title == "Warcraft III") | .pid' | head -n1)"
                if [ -n "$WARCRAFT_PID" ]; then
                  hyprctl --batch "dispatch focuswindow pid:$WARCRAFT_PID; dispatch fullscreen" >/dev/null
                fi
                warcraft-mode-start
                ;;
              *w3champions.exe*)
                W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
                if [ -n "$W3CHAMPIONS_PID" ]; then
                  hyprctl --batch "dispatch focuswindow pid:$W3CHAMPIONS_PID; dispatch resizeactive exact $X $Y; dispatch centerwindow" >/dev/null
                fi
                ;;
            esac
            ;;
          windowtitlev2*)
            case "$line" in
              *W3Champions)
                W3CHAMPIONS_ADDRESS="$(echo "$line" | awk -F '>>' '{print $2}' | awk -F ',' '{print $1}')"
                W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
              ;;
              *Warcraft*)
                WARCRAFT_ADDRESS="$(echo "$line" | awk -F '>>' '{print $2}' | awk -F ',' '{print $1}')"
                EXPLORER_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "explorer.exe" and .title == "") | .pid' | head -n 1)
                if [ -n "$EXPLORER_PID" ]; then
                  hyprctl --batch "dispatch killwindow pid:$EXPLORER_PID" >/dev/null
                fi
                ;;
            esac
            ;;
          urgent*)
            address="$(echo "$line" | awk -F '>>' '{print $2}')"
            if [ "$address" = "$W3CHAMPIONS_ADDRESS" ]; then
              W3CHAMPIONS_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "w3champions.exe" and .title == "W3Champions") | .pid' | head -n 1)
              if [ -n "$W3CHAMPIONS_PID" ]; then
                hyprctl --batch "dispatch focuswindow pid:$W3CHAMPIONS_PID; dispatch togglefloating; dispatch togglefloating" >/dev/null
              fi
            fi
            ;;
        esac
      done
    '';
  };
  w3champions = pkgs.writeShellApplication {
    name = "w3champions";
    runtimeInputs = [
      kill-games
      pkgs.hyprland
      pkgs.wine
      self.packages.x86_64-linux.warcraft-install-scripts
    ];
    text = ''
      export WINEPATH="$HOME/Games"
      export WINEPREFIX="$WINEPATH/W3Champions"
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export W3CHAMPIONS_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
      export WINEDEBUG=-all
      export DXVK_LOG_LEVEL=none
      export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
      export W3CHAMPIONS_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
      export VK_INSTANCE_LAYERS="VK_LAYER_WARCRAFT_overlay"
      export VK_LAYER_PATH="${self.packages.x86_64-linux.warcraft-vulkan-overlay}/share/vulkan/explicit_layer.d"

      if [ ! -f "$W3CHAMPIONS_EXE" ]; then
        install-warcraft
      fi

      kill-games

      focus-warcraft-game >/dev/null &
      WATCHDOG_PID="$!"

      wine ${self}/W3Champions.bat >/dev/null &
      GAME_PID="$!"

      wait "$GAME_PID"
      kill "$WATCHDOG_PID"
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
  warcraft-back-to-base = pkgs.writeShellApplication {
    name = "warcraft-back-to-base";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 14:1 14:0
    '';
  };
  warcraft-select-first-hero = pkgs.writeShellApplication {
    name = "warcraft-select-first-hero";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 59:1 59:0
    '';
  };
  warcraft-select-second-hero = pkgs.writeShellApplication {
    name = "warcraft-select-second-hero";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 60:1 60:0
    '';
  };
  warcraft-select-third-hero = pkgs.writeShellApplication {
    name = "warcraft-select-third-hero";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 61:1 61:0
    '';
  };
  warcraft-select-first-item = pkgs.writeShellApplication {
    name = "warcraft-select-first-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 40:1 40:0
    '';
  };
  warcraft-select-second-item = pkgs.writeShellApplication {
    name = "warcraft-select-second-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 43:1 43:0
    '';
  };
  warcraft-select-third-item = pkgs.writeShellApplication {
    name = "warcraft-select-third-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 50:1 50:0
    '';
  };
  warcraft-select-fourth-item = pkgs.writeShellApplication {
    name = "warcraft-select-fourth-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 51:1 51:0
    '';
  };
  warcraft-select-fifth-item = pkgs.writeShellApplication {
    name = "warcraft-select-fifth-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 52:1 52:0
    '';
  };
  warcraft-select-sixth-item = pkgs.writeShellApplication {
    name = "warcraft-select-sixth-item";
    runtimeInputs = [pkgs.ydotool];
    text = ''
      ydotool key 53:1 53:0
    '';
  };
  warcraft-write-control-group = pkgs.writeShellApplication {
    name = "warcraft-write-control-group";
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      CONTROL_GROUP="$1"

      case "$CONTROL_GROUP" in
        1) CONTROL_GROUP_KEYCODE=12 ;;
        2) CONTROL_GROUP_KEYCODE=65 ;;
        3) CONTROL_GROUP_KEYCODE=21 ;;
        4) CONTROL_GROUP_KEYCODE=23 ;;
        5) CONTROL_GROUP_KEYCODE=62 ;;
        6) CONTROL_GROUP_KEYCODE=7 ;;
        7) CONTROL_GROUP_KEYCODE=8 ;;
        8) CONTROL_GROUP_KEYCODE=9 ;;
        9) CONTROL_GROUP_KEYCODE=10 ;;
        0) CONTROL_GROUP_KEYCODE=11 ;;
      esac

      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      ydotool key "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0
    '';
  };
  warcraft-set-selection-control-group = pkgs.writeShellApplication {
    name = "warcraft-set-selection-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
    text = ''
      CONTROL_GROUP_KEYCODE_FILE="$WARCRAFT_HOME/control_group_keycode"
      CONTROL_GROUP_KEYCODE="$(cat "$CONTROL_GROUP_KEYCODE_FILE")"

      ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0
    '';
  };
  warcraft-select-unit = pkgs.writeShellApplication {
    name = "warcraft-select-unit";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
      pkgs.jq
    ];
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
    text = ''
      SCREEN_WIDTH="$(hyprctl monitors -j | jq -r '.[0].width')"
      SCREEN_HEIGHT="$(hyprctl monitors -j | jq -r '.[0].height')"
      SELECTED_UNIT="$1"

      MOUSE_POS="$(hyprctl cursorpos)"
      MOUSE_X="$(echo "$MOUSE_POS" | cut -d',' -f1)"
      MOUSE_Y="$(echo "$MOUSE_POS" | cut -d',' -f2)"

      case "$SELECTED_UNIT" in
        1)  X_P=42; Y_P=85 ;;
        2)  X_P=45; Y_P=85 ;;
        3)  X_P=48; Y_P=85 ;;
        4)  X_P=51; Y_P=85 ;;
        5)  X_P=54; Y_P=85 ;;
        6)  X_P=57; Y_P=85 ;;
        7)  X_P=42; Y_P=93 ;;
        8)  X_P=45; Y_P=93 ;;
        9)  X_P=48; Y_P=93 ;;
        10) X_P=51; Y_P=93 ;;
        11) X_P=54; Y_P=93 ;;
        12) X_P=57; Y_P=93 ;;
        *) exit 0 ;;
      esac

      X=$(( SCREEN_WIDTH  * X_P / 100 ))
      Y=$(( SCREEN_HEIGHT * Y_P / 100 ))

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-autocast = pkgs.writeShellApplication {
    name = "warcraft-autocast";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      SCREEN_WIDTH="$(hyprctl monitors -j | jq -r '.[] | .width')"
      SCREEN_HEIGHT="$(hyprctl monitors -j | jq -r '.[] | .height')"
      HOTKEY="$1"

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

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC1
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
in {
  warcraft-scripts = pkgs.symlinkJoin {
    name = "warcraft-scripts";
    paths = [
      kill-games
      focus-warcraft-game
      w3champions
      warcraft-mode-start
      warcraft-mode-stop
      warcraft-chat-open
      warcraft-chat-send
      warcraft-chat-close
      warcraft-back-to-base
      warcraft-select-first-hero
      warcraft-select-second-hero
      warcraft-select-third-hero
      warcraft-select-first-item
      warcraft-select-second-item
      warcraft-select-third-item
      warcraft-select-fourth-item
      warcraft-select-fifth-item
      warcraft-select-sixth-item
      warcraft-write-control-group
      warcraft-set-selection-control-group
      warcraft-select-unit
      warcraft-autocast
    ];
  };
}
