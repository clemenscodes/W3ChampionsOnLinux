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

echo "Activating autocast hotkey $HOTKEY" >>"$YDOTOOL_LOG_FILE"

MOUSE_POS=$(hyprctl cursorpos)
MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

case "$HOTKEY" in
Q)
  X=$((SCREEN_WIDTH * 72 / 100))
  Y=$((SCREEN_HEIGHT * 80 / 100))
  ;;
W)
  X=$((SCREEN_WIDTH * 76 / 100))
  Y=$((SCREEN_HEIGHT * 80 / 100))
  ;;
E)
  X=$((SCREEN_WIDTH * 80 / 100))
  Y=$((SCREEN_HEIGHT * 80 / 100))
  ;;
R)
  X=$((SCREEN_WIDTH * 84 / 100))
  Y=$((SCREEN_HEIGHT * 80 / 100))
  ;;
A)
  X=$((SCREEN_WIDTH * 72 / 100))
  Y=$((SCREEN_HEIGHT * 87 / 100))
  ;;
S)
  X=$((SCREEN_WIDTH * 76 / 100))
  Y=$((SCREEN_HEIGHT * 87 / 100))
  ;;
D)
  X=$((SCREEN_WIDTH * 80 / 100))
  Y=$((SCREEN_HEIGHT * 87 / 100))
  ;;
F)
  X=$((SCREEN_WIDTH * 84 / 100))
  Y=$((SCREEN_HEIGHT * 87 / 100))
  ;;
Y)
  X=$((SCREEN_WIDTH * 72 / 100))
  Y=$((SCREEN_HEIGHT * 94 / 100))
  ;;
X)
  X=$((SCREEN_WIDTH * 76 / 100))
  Y=$((SCREEN_HEIGHT * 94 / 100))
  ;;
C)
  X=$((SCREEN_WIDTH * 80 / 100))
  Y=$((SCREEN_HEIGHT * 94 / 100))
  ;;
V)
  X=$((SCREEN_WIDTH * 84 / 100))
  Y=$((SCREEN_HEIGHT * 94 / 100))
  ;;
esac

MOUSE_X=$((MOUSE_X / 2))
MOUSE_Y=$((MOUSE_Y / 2))
X=$((X / 2))
Y=$((Y / 2))

echo "Moving mouse to coordinate $X x $Y and clicking right mouse button" >>"$YDOTOOL_LOG_FILE"

ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$X" --ypos "$Y"
ydotool click 0xC1
ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
