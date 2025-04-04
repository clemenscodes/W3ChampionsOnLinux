#!/usr/bin/env bash

hyprctl dispatch submap CONTROLGROUP

YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
CONTROL_GROUP="$1"

echo "$CONTROL_GROUP" >"$WARCRAFT_HOME/control_group"

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

echo "Creating control group $CONTROL_GROUP" >>"$YDOTOOL_LOG_FILE"
echo "Writing control group keycode" >>"YDOTOOL_LOG_FILE"
echo "$CONTROL_GROUP_KEYCODE" >"$WARCRAFT_HOME/control_group_keycode"

sleep 0.1

ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

hyprctl dispatch submap WARCRAFT
