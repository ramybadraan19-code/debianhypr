#!/usr/bin/env bash
# ==============================================================================
# DebRice uninstaller — removes DebRice-managed configs and restores the most
# recent pre-install backup if one exists. Does NOT remove Hyprland or other
# packages by default (they may be used by other tools), only DebRice's own
# config layer, CLI, and dashboard.
# ==============================================================================
set -uo pipefail
INSTALL_HOME="$HOME/.local/share/debrice"
REPO_DIR="$INSTALL_HOME/repo"
source "$REPO_DIR/scripts/lib.sh" 2>/dev/null || { echo "DebRice not found, nothing to uninstall."; exit 0; }

log_step "Uninstalling DebRice"
confirm "This removes DebRice configs and the debrice CLI. Continue?" "n" || { log_info "Cancelled"; exit 0; }

"$REPO_DIR/scripts/backup.sh"

for cfg in hypr waybar kitty rofi mako eww dolphinrc; do
    rm -rf "${HOME:?}/.config/$cfg"
done
sudo rm -f /usr/local/bin/debrice
sudo rm -rf /usr/share/sddm/themes/debrice
sudo rm -f /etc/sddm.conf.d/debrice.conf
rm -f "$HOME/.local/share/applications/debrice-dashboard.desktop"

if confirm "Remove the DebRice repo and all backups too? (irreversible)" "n"; then
    rm -rf "$INSTALL_HOME"
fi

log_ok "DebRice uninstalled. Your previous configs (if backed up) are in $DEBRICE_BACKUP_DIR"
echo "You may also want to: sudo apt-get remove hyprland waybar (only if not used elsewhere)."
