#!/usr/bin/env bash
# ==============================================================================
# DebRice theme engine.
# Usage: apply-theme.sh <theme-slug> [waybar-style]
# Renders every {{PLACEHOLDER}} template in configs/ using the chosen theme's
# colors.sh, writes real configs into ~/.config/*, and reloads running apps.
# Idempotent: safe to re-run any number of times.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

THEME_SLUG="${1:-}"
[[ -f "$DEBRICE_STATE_DIR/selection.env" ]] && source "$DEBRICE_STATE_DIR/selection.env"
THEME_SLUG="${THEME_SLUG:-${SELECTED_THEME:-catppuccin}}"
WAYBAR_STYLE="${2:-${SELECTED_WAYBAR_STYLE:-modern}}"
CURSOR_CHOICE="${SELECTED_CURSOR:-bibata-ice}"
ICON_CHOICE="${SELECTED_ICONS:-papirus}"

THEME_DIR="$REPO_DIR/themes/$THEME_SLUG"
if [[ ! -f "$THEME_DIR/colors.sh" ]]; then
    log_error "Unknown theme: $THEME_SLUG (looked in $THEME_DIR)"
    exit 1
fi
# shellcheck disable=SC1090
source "$THEME_DIR/colors.sh"
log_step "Applying theme '$THEME_NAME' (waybar style: $WAYBAR_STYLE)"

hex_no_hash() { echo "${1#\#}"; }
hex_alpha() { # $1 = #rrggbb, $2 = 0-255 dec -> rgba() for waybar/gtk css
    local h="${1#\#}"; local a="$2"
    printf "rgba(%d,%d,%d,%s)" "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}" "$a"
}

# Common substitution list applied to every template
render_template() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    sed \
        -e "s|{{THEME_NAME}}|$THEME_NAME|g" \
        -e "s|{{BG_HEX}}|$(hex_no_hash "$BG")|g" \
        -e "s|{{BG_ALT_HEX}}|$(hex_no_hash "$BG_ALT")|g" \
        -e "s|{{FG_HEX}}|$(hex_no_hash "$FG")|g" \
        -e "s|{{FG_ALT_HEX}}|$(hex_no_hash "$FG_ALT")|g" \
        -e "s|{{ACCENT_HEX}}|$(hex_no_hash "$ACCENT")|g" \
        -e "s|{{ACCENT2_HEX}}|$(hex_no_hash "$ACCENT2")|g" \
        -e "s|{{RED_HEX}}|$(hex_no_hash "$RED")|g" \
        -e "s|{{GREEN_HEX}}|$(hex_no_hash "$GREEN")|g" \
        -e "s|{{YELLOW_HEX}}|$(hex_no_hash "$YELLOW")|g" \
        -e "s|{{BLUE_HEX}}|$(hex_no_hash "$BLUE")|g" \
        -e "s|{{MAGENTA_HEX}}|$(hex_no_hash "$MAGENTA")|g" \
        -e "s|{{CYAN_HEX}}|$(hex_no_hash "$CYAN")|g" \
        -e "s|{{BORDER_ACTIVE_HEX}}|$(hex_no_hash "$BORDER_ACTIVE")|g" \
        -e "s|{{BORDER_INACTIVE_HEX}}|$(hex_no_hash "$BORDER_INACTIVE")|g" \
        -e "s|{{BG_HEX_A}}|$(hex_alpha "$BG" "$TRANSPARENCY")|g" \
        -e "s|{{BG_ALT_HEX_A}}|$(hex_alpha "$BG_ALT" "$TRANSPARENCY")|g" \
        -e "s|{{BG_HEX_ALPHA_LOW}}|$(hex_alpha "$BG" "0.35")|g" \
        -e "s|{{TRANSPARENCY}}|$TRANSPARENCY|g" \
        -e "s|{{ROUNDING_SM}}|$(( ROUNDING > 4 ? ROUNDING - 4 : ROUNDING ))|g" \
        -e "s|{{ROUNDING}}|$ROUNDING|g" \
        -e "s|{{BLUR}}|$BLUR|g" \
        -e "s|{{BLUR_KITTY}}|$( [[ $BLUR == true ]] && echo yes || echo no )|g" \
        -e "s|{{BLUR_SIZE}}|$( [[ $RAM_TIER == low ]] && echo 4 || echo 8 )|g" \
        -e "s|{{BLUR_PASSES}}|$( [[ $RAM_TIER == low ]] && echo 1 || echo 3 )|g" \
        -e "s|{{ANIM_SPEED}}|6|g" \
        -e "s|{{GAPS_OUT}}|$( [[ $ROUNDING -eq 0 ]] && echo 4 || echo 10 )|g" \
        -e "s|{{RESOLUTION}}|${RESOLUTION:-1920x1080}|g" \
        -e "s|{{CURSOR_THEME}}|$(cursor_theme_name "$CURSOR_CHOICE")|g" \
        -e "s|{{DEBRICE_HOME}}|$DEBRICE_HOME|g" \
        -e "s|{{WALLPAPER_PATH}}|$(current_wallpaper)|g" \
        "$src" > "$dest.tmp"

    # NVIDIA_ENV_BLOCK can be multi-line, which plain `sed s|||` can't handle
    # safely across shells/sed versions — substitute it with awk instead.
    local nvidia_block; nvidia_block="$(nvidia_env_block)"
    awk -v block="$nvidia_block" '{ gsub(/\{\{NVIDIA_ENV_BLOCK\}\}/, block); print }' "$dest.tmp" > "$dest"
    rm -f "$dest.tmp"
}

cursor_theme_name() {
    case "$1" in
        bibata-ice) echo "Bibata-Modern-Ice" ;;
        bibata-classic) echo "Bibata-Modern-Classic" ;;
        nordzy) echo "Nordzy-cursors" ;;
        *) echo "Bibata-Modern-Ice" ;;
    esac
}

icon_theme_name() {
    case "$1" in
        papirus) echo "Papirus-Dark" ;;
        tela) echo "Tela-dark" ;;
        colloid) echo "Colloid-Dark" ;;
        whitesur) echo "WhiteSur-Dark" ;;
        *) echo "Papirus-Dark" ;;
    esac
}

current_wallpaper() {
    local wp="$DEBRICE_STATE_DIR/current-wallpaper"
    if [[ -f "$wp" ]]; then cat "$wp"; else echo "$REPO_DIR/wallpapers/${THEME_SLUG}/default.jpg"; fi
}

nvidia_env_block() {
    [[ -f "$DEBRICE_STATE_DIR/hardware.env" ]] && source "$DEBRICE_STATE_DIR/hardware.env"
    if [[ "${GPU_VENDOR:-}" == "nvidia" ]]; then
        cat <<'NVENV'
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = WLR_NO_HARDWARE_CURSORS,1
NVENV
    fi
}

[[ -f "$DEBRICE_STATE_DIR/hardware.env" ]] && source "$DEBRICE_STATE_DIR/hardware.env"

# ---- Render Hyprland --------------------------------------------------
render_template "$REPO_DIR/configs/hypr/hyprland.conf.template" "$HOME/.config/hypr/hyprland.conf"
render_template "$REPO_DIR/configs/hypr/hypridle.conf.template" "$HOME/.config/hypr/hypridle.conf"
render_template "$REPO_DIR/configs/hyprlock/hyprlock.conf.template" "$HOME/.config/hypr/hyprlock.conf"

# Hardware-specific include (monitor scaling, workspace-per-monitor hints, etc.)
mkdir -p "$HOME/.config/hypr"
{
    echo "# Auto-generated hardware tuning — regenerated by apply-theme.sh"
    case "${RESOLUTION_CLASS:-1080p}" in
        4k) echo "monitor=,preferred,auto,1.5" ;;
        1440p) echo "monitor=,preferred,auto,1.2" ;;
        *) echo "monitor=,preferred,auto,1" ;;
    esac
    if [[ "${RAM_TIER:-medium}" == "low" ]]; then
        echo "# Low-RAM system: animations trimmed for performance"
        echo "animations { enabled = true }"
        echo "decoration { blur { enabled = false } }"
    fi
} > "$HOME/.config/hypr/hardware.conf"

# ---- Render Kitty -------------------------------------------------------
render_template "$REPO_DIR/configs/kitty/kitty.conf.template" "$HOME/.config/kitty/kitty.conf"
mkdir -p "$HOME/.config/kitty"
cp "$REPO_DIR/configs/kitty/startup.session" "$HOME/.config/kitty/startup.session"

# ---- Render Rofi ----------------------------------------------------------
render_template "$REPO_DIR/configs/rofi/theme.rasi.template" "$HOME/.config/rofi/theme.rasi"

# ---- Render Waybar (chosen style) -----------------------------------------
STYLE_DIR="$REPO_DIR/configs/waybar/styles/$WAYBAR_STYLE"
if [[ ! -d "$STYLE_DIR" ]]; then
    log_warn "Unknown waybar style '$WAYBAR_STYLE' — falling back to 'modern'"
    WAYBAR_STYLE="modern"
    STYLE_DIR="$REPO_DIR/configs/waybar/styles/modern"
fi
mkdir -p "$HOME/.config/waybar"
cp "$STYLE_DIR/config.jsonc" "$HOME/.config/waybar/config.jsonc"
render_template "$STYLE_DIR/style.css.template" "$HOME/.config/waybar/style.css"

# ---- Render Mako (notifications) and EWW widgets --------------------------
render_template "$REPO_DIR/configs/mako/mako.template" "$HOME/.config/mako/config"
mkdir -p "$HOME/.config/eww"
cp "$REPO_DIR/configs/eww/eww.yuck" "$HOME/.config/eww/eww.yuck"
cp "$REPO_DIR/configs/eww/launch.sh" "$HOME/.config/eww/launch.sh"
render_template "$REPO_DIR/configs/eww/eww.scss.template" "$HOME/.config/eww/eww.scss"
chmod +x "$HOME/.config/eww/launch.sh"
if pgrep -x mako >/dev/null 2>&1; then makoctl reload >/dev/null 2>&1 || true; fi

# ---- Render wlogout (logout menu) ------------------------------------------
mkdir -p "$HOME/.config/wlogout"
render_template "$REPO_DIR/configs/wlogout/style.css.template" "$HOME/.config/wlogout/style.css"
cp "$REPO_DIR/configs/wlogout/layout.json" "$HOME/.config/wlogout/layout.json"

# ---- GTK / Qt theming (icons + cursor + dark mode) ------------------------
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
ICON_THEME_NAME="$(icon_theme_name "$ICON_CHOICE")"
CURSOR_THEME_NAME="$(cursor_theme_name "$CURSOR_CHOICE")"
render_template "$REPO_DIR/configs/gtk-3.0/gtk.css.template" "$HOME/.config/gtk-3.0/gtk.css"
render_template "$REPO_DIR/configs/dolphin/dolphinrc.template" "$HOME/.config/dolphinrc"

for gtkver in gtk-3.0 gtk-4.0; do
cat > "$HOME/.config/$gtkver/settings.ini" <<EOF
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=$CURSOR_THEME_NAME
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF
done

cat > "$HOME/.icons/default/index.theme" 2>/dev/null <<EOF || mkdir -p "$HOME/.icons/default" && cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_THEME_NAME
EOF

# ---- Persist selection state --------------------------------------------
cat > "$DEBRICE_STATE_DIR/selection.env" <<EOF
SELECTED_THEME="$THEME_SLUG"
SELECTED_ICONS="$ICON_CHOICE"
SELECTED_CURSOR="$CURSOR_CHOICE"
SELECTED_WAYBAR_STYLE="$WAYBAR_STYLE"
EOF

# ---- Live reload running apps (safe no-ops if not running) -----------------
if command_exists hyprctl && pgrep -x Hyprland >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 waybar 2>/dev/null || killall waybar 2>/dev/null; (setsid waybar >/dev/null 2>&1 &) 2>/dev/null || true
fi

log_ok "Theme '$THEME_NAME' applied successfully (waybar: $WAYBAR_STYLE, icons: $ICON_THEME_NAME, cursor: $CURSOR_THEME_NAME)"
