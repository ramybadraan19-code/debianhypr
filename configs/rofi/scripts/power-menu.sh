#!/usr/bin/env bash
# DebRice — Rofi power menu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME="$SCRIPT_DIR/configs/rofi/theme.rasi"
options="  Lock\n  Logout\n  Suspend\n  Reboot\n  Shutdown"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power" -theme "$THEME")
case "$chosen" in
    *Lock*) hyprlock ;;
    *Logout*) hyprctl dispatch exit ;;
    *Suspend*) systemctl suspend ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
