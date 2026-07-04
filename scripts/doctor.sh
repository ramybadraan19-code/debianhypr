#!/usr/bin/env bash
# DebRice — health check. Verifies dependencies, configs, and services.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

log_step "DebRice Doctor — running diagnostics"
ISSUES=0

check() {
    local desc="$1" cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        log_ok "$desc"
    else
        log_error "$desc"
        ISSUES=$((ISSUES+1))
    fi
}

check "Hyprland installed"        "command_exists Hyprland || command_exists hyprland"
check "Waybar installed"          "command_exists waybar"
check "Kitty installed"           "command_exists kitty"
check "Rofi installed"            "command_exists rofi"
check "Hyprlock installed"        "command_exists hyprlock"
check "Hypridle installed"        "command_exists hypridle"
check "wl-clipboard installed"    "command_exists wl-copy"
check "cliphist installed"        "command_exists cliphist"
check "cava installed"            "command_exists cava"
check "pywal installed"           "command_exists wal"
check "NetworkManager running"    "systemctl is-active --quiet NetworkManager"
check "Bluetooth service running" "systemctl is-active --quiet bluetooth"
check "SDDM enabled"              "systemctl is-enabled --quiet sddm"
check "hyprland.conf exists"      "[[ -f $HOME/.config/hypr/hyprland.conf ]]"
check "waybar config exists"      "[[ -f $HOME/.config/waybar/config.jsonc ]]"
check "Theme selection recorded"  "[[ -f $DEBRICE_STATE_DIR/selection.env ]]"
check "Nerd Font installed"       "fc-list | grep -qi 'nerd font'"

echo
if [[ $ISSUES -eq 0 ]]; then
    log_ok "All checks passed. DebRice looks healthy!"
else
    log_warn "$ISSUES issue(s) found. Run 'debrice repair' to attempt automatic fixes."
fi
exit $ISSUES
