#!/usr/bin/env bash
# DebRice — Rofi Bluetooth menu (backed by bluetoothctl)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME="$SCRIPT_DIR/configs/rofi/theme.rasi"
mapfile -t devices < <(bluetoothctl devices | awk '{$1="";print}')
menu=""
for d in "${devices[@]}"; do menu+=" $d\n"; done
chosen=$(echo -e "$menu" | rofi -dmenu -i -p "Bluetooth" -theme "$THEME")
mac=$(echo "$chosen" | awk '{print $1}')
[[ -n "$mac" ]] && bluetoothctl connect "$mac"
