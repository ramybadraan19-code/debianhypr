#!/usr/bin/env bash
# ==============================================================================
# DebRice weather fetcher (wttr.in, no API key needed). Used by Waybar, EWW,
# and Hyprlock. Caches results for 15 minutes to avoid rate limits.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CACHE_FILE="$DEBRICE_STATE_DIR/weather-cache.json"
CACHE_TTL=900

fetch() {
    if [[ -f "$CACHE_FILE" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) )) -lt $CACHE_TTL ]]; then
        cat "$CACHE_FILE"; return
    fi
    local data
    data="$(curl -fsSL "wttr.in/?format=%C|%t|%h" --max-time 5 2>/dev/null)" || data="Unknown|--|--"
    echo "$data" > "$CACHE_FILE"
    echo "$data"
}

raw="$(fetch)"
IFS='|' read -r cond temp humidity <<< "$raw"

case "${1:-}" in
    --waybar)
        printf '{"text":" %s","tooltip":"%s, humidity %s"}\n' "${temp:-N/A}" "${cond:-Unknown}" "${humidity:-N/A}"
        ;;
    --short)
        echo " ${temp:-N/A}  ${cond:-Unknown}"
        ;;
    *)
        echo "${cond:-Unknown} ${temp:-N/A} (humidity ${humidity:-N/A})"
        ;;
esac
