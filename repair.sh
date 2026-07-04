#!/usr/bin/env bash
# ==============================================================================
# DebRice repair tool — attempts to automatically fix issues found by
# `debrice doctor`: missing packages, missing configs, broken symlinks.
# ==============================================================================
set -uo pipefail
INSTALL_HOME="$HOME/.local/share/debrice"
REPO_DIR="$INSTALL_HOME/repo"
source "$REPO_DIR/scripts/lib.sh"

log_step "DebRice Repair — attempting automatic fixes"

log_info "Re-running package installer (fixes missing packages)"
bash "$REPO_DIR/scripts/install-packages.sh" || log_warn "Package repair had issues, see log"

log_info "Re-detecting hardware"
bash "$REPO_DIR/scripts/detect-hardware.sh"

log_info "Re-applying current theme (fixes missing/corrupt configs)"
sel="$DEBRICE_STATE_DIR/selection.env"
if [[ -f "$sel" ]]; then
    source "$sel"
else
    SELECTED_THEME="catppuccin"; SELECTED_WAYBAR_STYLE="modern"
fi
bash "$REPO_DIR/scripts/apply-theme.sh" "${SELECTED_THEME:-catppuccin}" "${SELECTED_WAYBAR_STYLE:-modern}"

log_info "Re-installing CLI tool"
sudo install -m 755 "$REPO_DIR/bin/debrice" /usr/local/bin/debrice

log_info "Restarting user services (waybar, mako)"
pkill waybar 2>/dev/null; (setsid waybar >/dev/null 2>&1 &) 2>/dev/null || true
pkill mako 2>/dev/null; (setsid mako >/dev/null 2>&1 &) 2>/dev/null || true

log_ok "Repair pass complete. Run 'debrice doctor' to verify."
