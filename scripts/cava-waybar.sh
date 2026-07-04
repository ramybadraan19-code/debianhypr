#!/usr/bin/env bash
# ==============================================================================
# DebRice Cava-in-Waybar bridge. Renders a compact bar-graph of audio levels
# as a Waybar custom module string, appears only while audio is playing and
# hides automatically when it stops.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CAVA_CONFIG="$DEBRICE_STATE_DIR/cava-waybar.conf"
BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

write_cava_config() {
    cat > "$CAVA_CONFIG" <<EOF
[general]
bars = 10
framerate = 30

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59

[smoothing]
noise_reduction = 65
EOF
}

is_audio_playing() {
    command_exists playerctl && [[ "$(playerctl status 2>/dev/null)" == "Playing" ]] && return 0
    pactl list sink-inputs 2>/dev/null | grep -q "State: RUNNING" && return 0
    return 1
}

render_line() {
    local raw="$1" out=""
    IFS=';' read -ra vals <<< "$raw"
    for v in "${vals[@]}"; do
        [[ -z "$v" ]] && continue
        idx=$(( v > 7 ? 7 : v ))
        out+="${BARS[$idx]}"
    done
    echo "$out"
}

case "${1:-}" in
    --daemon|"")
        write_cava_config
        if ! is_audio_playing; then exit 0; fi
        command_exists cava && cava -p "$CAVA_CONFIG" 2>/dev/null | while read -r line; do
            is_audio_playing || break
            render_line "$line"
        done
        ;;
esac
