{
  self,
  pkgs,
  ...
}: let
  kill-games = pkgs.writeShellApplication {
    name = "kill-games";
    text = ''
      for proc in main Warcraft wine Microsoft edge srt-bwrap exe Cr mDNS; do
        pkill "$proc" || true
      done
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
      SCREEN_WIDTH="$(hyprctl monitors -j | jq -r '.[] | .width')"
      SCREEN_HEIGHT="$(hyprctl monitors -j | jq -r '.[] | .height')"
      SCREEN_CENTER_X=$((SCREEN_WIDTH / 2))
      SCREEN_CENTER_Y=$((SCREEN_HEIGHT / 2))

      socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
        ADDRESS="$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "Warcraft III") | .address' | head -n1)"
        if [ -n "$ADDRESS" ]; then
          WARCRAFT_ADDRESS="$ADDRESS"
        fi
        case "$line" in
          fullscreen*)
            if [ "$(hyprctl activewindow)" = "Invalid" ]; then
              notify-send --expire-time 3000 "W3Champions match started!" --icon "${self}/assets/W3Champions.png"
              sleep 6
              warcraft-mode-start
              hyprctl --batch "dispatch workspace 3 ; dispatch fullscreen 0 ; dispatch movecursor $SCREEN_CENTER_X $SCREEN_CENTER_Y"
            fi
            ;;
          closewindow*)
            address="$(echo "$line" | awk -F '>>' '{print $2}')"
            if [ "0x$address" = "$WARCRAFT_ADDRESS" ]; then
              warcraft-mode-stop
              hyprctl --batch "dispatch workspace 2 ; dispatch movecursor 1350 330"
            fi
            ;;
          openwindow*)
            case "$line" in
              *Warcraft*) WARCRAFT_ADDRESS="$(echo "$line" | awk -F '>>' '{print $2}' | awk -F ',' '{print $1}')" ;;
            esac
            ;;
        esac
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

      LUTRIS_SKIP_INIT=1 lutris lutris:rungame/battlenet
    '';
  };
  w3champions = pkgs.writeShellApplication {
    name = "w3champions";
    runtimeInputs = [
      focus-warcraft-game
      pkgs.lutris
      pkgs.libnotify
      pkgs.hyprland
      (pkgs.wrapOBS.override {inherit (pkgs) obs-studio;} {
        plugins = [
          pkgs.obs-studio-plugins.wlrobs
          pkgs.obs-studio-plugins.input-overlay
          pkgs.obs-studio-plugins.obs-pipewire-audio-capture
          pkgs.obs-studio-plugins.obs-vkcapture
          pkgs.obs-studio-plugins.obs-gstreamer
          pkgs.obs-studio-plugins.obs-vaapi
        ];
      })
    ];
    text = ''
      kill-games

      notify-send "Starting W3Champions" --icon "${self}/assets/W3Champions.png"

      if ! pgrep obs > /dev/null 2>&1; then
        obs --disable-shutdown-check --multi --startreplaybuffer &
      fi

      LUTRIS_SKIP_INIT=1 lutris lutris:rungame/W3Champions &
      GAME_PID="$!"

      focus-warcraft-game &
      WATCHDOG_PID="$!"

      while true; do
        W3C_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "W3Champions") | .pid' | head -n 1)
        if [ -n "$W3C_PID" ]; then
          hyprctl --batch "dispatch focuswindow pid:$W3C_PID; dispatch resizeactive exact 1600 900 ; dispatch centerwindow"
          while true; do
            WARCRAFT_PID=$(hyprctl clients -j | jq -r '.[] | select(.class == "steam_app_default" and .title == "Warcraft III") | .pid' | head -n 1)
            if [ -n "$WARCRAFT_PID" ]; then
              hyprctl --batch "dispatch focuswindow pid:$WARCRAFT_PID; dispatch fullscreen 0 ; dispatch focuswindow pid:$W3C_PID; dispatch resizeactive exact 1600 900 ; dispatch centerwindow ; "
              break
            fi
          done
          break
        fi
      done

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
        1) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 89 / 108)); ;;
        2) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 89 / 108)); ;;
        3) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 8 / 9)); ;;
        4) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 8 / 9)); ;;
        5) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 205 / 216)); ;;
        6) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 205 / 216)); ;;
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
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
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
      echo "Writing control group keycode" >> "$YDOTOOL_LOG_FILE"
      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      sleep 0.1

      ydotool key "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-create-control-group = pkgs.writeShellApplication {
    name = "warcraft-create-control-group";
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
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
    excludeShellChecks = [
      "SC2046"
      "SC2086"
    ];
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
    excludeShellChecks = [
      "SC2046"
      "SC2086"
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
in {
  warcraft-scripts = pkgs.symlinkJoin {
    name = "warcraft-scripts";
    paths = [
      kill-games
      focus-warcraft-game
      battlenet
      w3champions
      warcraft-mode-start
      warcraft-mode-stop
      warcraft-chat-open
      warcraft-chat-send
      warcraft-chat-close
      warcraft-autocast-hotkey
      warcraft-inventory-hotkey
      warcraft-write-control-group
      warcraft-create-control-group
      warcraft-edit-unit-control-group
      warcraft-select-unit
    ];
  };
}
