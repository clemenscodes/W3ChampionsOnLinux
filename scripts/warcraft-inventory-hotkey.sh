#!/usr/bin/env bash

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

echo "Activating inventory hotkey $HOTKEY" >>"$YDOTOOL_LOG_FILE"

MOUSE_POS=$(hyprctl cursorpos)
MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

case "$HOTKEY" in
1)
  X=$((SCREEN_WIDTH * 79 / 128))
  Y=$((SCREEN_HEIGHT * 89 / 108)) return
  ;;
2)
  X=$((SCREEN_WIDTH * 21 / 32))
  Y=$((SCREEN_HEIGHT * 89 / 108)) return
  ;;
3)
  X=$((SCREEN_WIDTH * 79 / 128))
  Y=$((SCREEN_HEIGHT * 8 / 9)) return
  ;;
4)
  X=$((SCREEN_WIDTH * 21 / 32))
  Y=$((SCREEN_HEIGHT * 8 / 9)) return
  ;;
5)
  X=$((SCREEN_WIDTH * 79 / 128))
  Y=$((SCREEN_HEIGHT * 205 / 216)) return
  ;;
6)
  X=$((SCREEN_WIDTH * 21 / 32))
  Y=$((SCREEN_HEIGHT * 205 / 216)) return
  ;;
esac

MOUSE_X=$((MOUSE_X / 2))
MOUSE_Y=$((MOUSE_Y / 2))
X=$((X / 2))
Y=$((Y / 2))

echo "Moving mouse to coordinate $X x $Y and clicking left mouse button" >>"$YDOTOOL_LOG_FILE"

ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$X" --ypos "$Y"
ydotool click 0xC0
ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
