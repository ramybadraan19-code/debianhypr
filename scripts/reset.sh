#!/usr/bin/env bash
# DebRice — reset to default theme/config (Catppuccin, Papirus, Bibata Ice, modern waybar)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

confirm "Reset DebRice to default theme and settings?" "n" || { log_info "Cancelled"; exit 0; }
"$SCRIPT_DIR/backup.sh"
cat > "$DEBRICE_STATE_DIR/selection.env" <<EOF
SELECTED_THEME="catppuccin"
SELECTED_ICONS="papirus"
SELECTED_CURSOR="bibata-ice"
SELECTED_WAYBAR_STYLE="modern"
EOF
"$SCRIPT_DIR/apply-theme.sh" catppuccin modern
log_ok "DebRice reset to defaults (previous config backed up automatically)"
