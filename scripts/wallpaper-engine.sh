#!/usr/bin/env bash
# ==============================================================================
# DebRice wallpaper engine: chooser, random, slideshow, hourly auto-change,
# and pywal-based recoloring of Waybar/Kitty/Rofi/GTK/Hyprland.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"
[[ -f "$DEBRICE_STATE_DIR/selection.env" ]] && source "$DEBRICE_STATE_DIR/selection.env"

WALLPAPER_DIR="${DEBRICE_WALLPAPER_DIR:-$REPO_DIR/wallpapers/${SELECTED_THEME:-catppuccin}}"
[[ -d "$WALLPAPER_DIR" ]] || WALLPAPER_DIR="$REPO_DIR/wallpapers"

set_wallpaper() {
    local wp="$1"
    [[ -f "$wp" ]] || { log_error "Wallpaper not found: $wp"; return 1; }
    echo "$wp" > "$DEBRICE_STATE_DIR/current-wallpaper"

    # hyprpaper
    mkdir -p "$HOME/.config/hypr"
    cat > "$HOME/.config/hypr/hyprpaper.conf" <<EOF
preload = $wp
wallpaper = ,$wp
splash = false
EOF
    if pgrep -x hyprpaper >/dev/null 2>&1; then
        hyprctl hyprpaper reload ",$wp" >/dev/null 2>&1 || true
    fi

    # pywal recolor (Waybar, Kitty, Rofi, GTK, Hyprland border accent)
    if command_exists wal; then
        wal -i "$wp" -n -q --backend colorz 2>/dev/null || wal -i "$wp" -n -q 2>/dev/null || true
        apply_pywal_colors
    else
        log_warn "pywal not installed — skipping auto-recolor (theme colors unaffected)"
    fi
    log_ok "Wallpaper set: $(basename "$wp")"
}

apply_pywal_colors() {
    local cache="$HOME/.cache/wal/colors.sh"
    [[ -f "$cache" ]] || return 0
    # shellcheck disable=SC1090
    source "$cache"
    # Re-apply theme templates, but inject pywal's accent as ACCENT for a
    # wallpaper-driven recolor on top of the base theme.
    local theme_dir="$REPO_DIR/themes/${SELECTED_THEME:-catppuccin}"
    if [[ -f "$theme_dir/colors.sh" ]]; then
        cp "$theme_dir/colors.sh" "$DEBRICE_STATE_DIR/.colors-backup.sh"
        # shellcheck disable=SC1090
        source "$theme_dir/colors.sh"
        ACCENT="${color4:-$ACCENT}"
        ACCENT2="${color5:-$ACCENT2}"
        export ACCENT ACCENT2
    fi
    "$SCRIPT_DIR/apply-theme.sh" "${SELECTED_THEME:-catppuccin}" "${SELECTED_WAYBAR_STYLE:-modern}" >/dev/null 2>&1 || true
}

pick_random() {
    find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | shuf -n1
}

choose_interactive() {
    if command_exists rofi; then
        local wp
        wp=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) 2>/dev/null \
            | rofi -dmenu -i -p "Wallpaper" -theme "$REPO_DIR/configs/rofi/theme.rasi")
        [[ -n "$wp" ]] && set_wallpaper "$wp"
    else
        local wp; wp="$(pick_random)"
        [[ -n "$wp" ]] && set_wallpaper "$wp"
    fi
}

slideshow_daemon() {
    log_info "Starting wallpaper slideshow (every ${1:-1800}s)"
    while true; do
        local wp; wp="$(pick_random)"
        [[ -n "$wp" ]] && set_wallpaper "$wp"
        sleep "${1:-1800}"
    done
}

hourly_daemon() { slideshow_daemon 3600; }

case "${1:-}" in
    --choose) choose_interactive ;;
    --random) wp="$(pick_random)"; [[ -n "$wp" ]] && set_wallpaper "$wp" ;;
    --set) set_wallpaper "$2" ;;
    --slideshow) slideshow_daemon "${2:-1800}" ;;
    --hourly) hourly_daemon ;;
    *)
        echo "Usage: wallpaper-engine.sh [--choose|--random|--set <path>|--slideshow [sec]|--hourly]"
        ;;
esac
