#!/usr/bin/env bash

YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
CONTROL_GROUP_KEYCODE_FILE="$WARCRAFT_HOME/control_group_keycode"
CONTROL_GROUP_KEYCODE="$(cat "$CONTROL_GROUP_KEYCODE_FILE")"

echo "Editing unit from control group" >>"$YDOTOOL_LOG_FILE"

hyprctl dispatch submap CONTROLGROUP

sleep 0.1

ydotool key 42:1
ydotool click 0xC0
ydotool key 42:0
ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

hyprctl dispatch submap WARCRAFT
