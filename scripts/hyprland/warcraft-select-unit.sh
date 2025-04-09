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
    SELECTED_UNIT="$1"
    shift
    ;;
  esac
done

echo "Selecting unit $SELECTED_UNIT from current control group" >>"$YDOTOOL_LOG_FILE"

MOUSE_POS=$(hyprctl cursorpos)
MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

case "$SELECTED_UNIT" in
1)
  X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
2)
  X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
3)
  X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
4)
  X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
5)
  X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
6)
  X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT))
  ;;
7)
  X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
8)
  X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
9)
  X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
10)
  X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
11)
  X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
12)
  X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH))
  Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT))
  ;;
esac

MOUSE_X=$((MOUSE_X / 2))
MOUSE_Y=$((MOUSE_Y / 2))
X=$((X / 2))
Y=$((Y / 2))

echo "Moving mouse to coordinate $X x $Y and double clicking left mouse button" >>"$YDOTOOL_LOG_FILE"

ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$X" --ypos "$Y"
ydotool click 0xC0 0xC0
ydotool mousemove --absolute --xpos 0 --ypos 0
ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
