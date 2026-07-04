#!/usr/bin/env bash
# DebRice — Rofi live theme switcher (calls into scripts/apply-theme.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME_RASI="$SCRIPT_DIR/configs/rofi/theme.rasi"
themes="Catppuccin\nTokyo Night\nNord\nDracula\nGruvbox\nAMOLED Black\nGlassmorphism\nCyberpunk Neon"
chosen=$(echo -e "$themes" | rofi -dmenu -i -p "Theme" -theme "$THEME_RASI")
slug=$(echo "$chosen" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
[[ -n "$slug" ]] && "$SCRIPT_DIR/scripts/apply-theme.sh" "$slug" && notify-send "DebRice" "Theme switched to $chosen"
