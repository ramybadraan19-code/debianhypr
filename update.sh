#!/usr/bin/env bash
# ==============================================================================
# DebRice updater — pulls the latest release from GitHub and re-applies the
# current theme/settings on top of it. Safe/idempotent; backs up first.
# ==============================================================================
set -uo pipefail
INSTALL_HOME="$HOME/.local/share/debrice"
REPO_DIR="$INSTALL_HOME/repo"
source "$REPO_DIR/scripts/lib.sh"

log_step "Checking for DebRice updates"
[[ -d "$REPO_DIR/.git" ]] || { log_error "No git checkout found at $REPO_DIR"; exit 1; }

CURRENT_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"
"$REPO_DIR/scripts/backup.sh"

git -C "$REPO_DIR" fetch --depth 1 origin main
git -C "$REPO_DIR" reset --hard origin/main

NEW_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"
log_ok "Updated: $CURRENT_VERSION -> $NEW_VERSION"

# Re-run package install (idempotent — only installs missing/new deps)
bash "$REPO_DIR/scripts/install-packages.sh"

# Re-apply current theme/waybar style/icons/cursor on top of the new configs
sel="$DEBRICE_STATE_DIR/selection.env"
if [[ -f "$sel" ]]; then
    source "$sel"
    bash "$REPO_DIR/scripts/apply-theme.sh" "${SELECTED_THEME:-catppuccin}" "${SELECTED_WAYBAR_STYLE:-modern}"
fi

sudo install -m 755 "$REPO_DIR/bin/debrice" /usr/local/bin/debrice

log_ok "DebRice is up to date (v$NEW_VERSION)"
