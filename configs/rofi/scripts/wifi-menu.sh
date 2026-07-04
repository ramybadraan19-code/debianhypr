#!/usr/bin/env bash
# DebRice — Rofi Wi-Fi menu (backed by NetworkManager)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME="$SCRIPT_DIR/configs/rofi/theme.rasi"
mapfile -t networks < <(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | awk -F: '!seen[$1]++')
menu=""
for n in "${networks[@]}"; do
    ssid="${n%%:*}"
    [[ -z "$ssid" ]] && continue
    menu+="  $ssid\n"
done
chosen=$(echo -e "$menu" | rofi -dmenu -i -p "Wi-Fi" -theme "$THEME")
ssid="${chosen#  }"
[[ -n "$ssid" ]] && nmcli dev wifi connect "$ssid" --ask
