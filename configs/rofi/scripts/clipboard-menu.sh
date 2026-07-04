#!/usr/bin/env bash
# DebRice — Rofi clipboard manager (backed by cliphist)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME="$SCRIPT_DIR/configs/rofi/theme.rasi"
cliphist list | rofi -dmenu -i -p "Clipboard" -theme "$THEME" | cliphist decode | wl-copy
