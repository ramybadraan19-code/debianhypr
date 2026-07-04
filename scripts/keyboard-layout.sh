#!/usr/bin/env bash
# ==============================================================================
# DebRice keyboard layout helper: EN/AR switch on Alt+Shift, notification on
# change, and a --status output consumed by Waybar's custom/keyboard-layout.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

STATE_FILE="$DEBRICE_STATE_DIR/kb-layout"

current_layout() {
    if command_exists hyprctl; then
        hyprctl devices -j 2>/dev/null | jq -r '.keyboards[0].active_keymap // "English (US)"' 2>/dev/null || echo "English (US)"
    else
        echo "English (US)"
    fi
}

case "${1:-}" in
    --status)
        layout="$(current_layout)"
        if echo "$layout" | grep -qi "ara"; then echo "🇸🇦 AR"; else echo "🇺🇸 EN"; fi
        ;;
    --toggle)
        hyprctl switchxkblayout all next >/dev/null 2>&1 || true
        sleep 0.15
        layout="$(current_layout)"
        notify-send -t 1200 "Keyboard Layout" "$layout" -i input-keyboard 2>/dev/null || true
        echo "$layout" > "$STATE_FILE"
        ;;
    --daemon)
        # Watches Hyprland's IPC event socket and fires a notification whenever
        # the active keymap changes (covers the built-in Alt+Shift toggle too).
        [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || exit 0
        sock="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        [[ -S "$sock" ]] || exit 0
        socat -U - UNIX-CONNECT:"$sock" 2>/dev/null | while read -r line; do
            if [[ "$line" == activelayout* ]]; then
                layout="${line#*,}"
                notify-send -t 1200 "Keyboard Layout" "$layout" -i input-keyboard 2>/dev/null || true
                echo "$layout" > "$STATE_FILE"
            fi
        done
        ;;
    *)
        echo "Usage: keyboard-layout.sh [--status|--toggle|--daemon]"
        ;;
esac
