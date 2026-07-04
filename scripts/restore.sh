#!/usr/bin/env bash
# DebRice — restore configs from a backup snapshot (defaults to the most recent one)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SNAPSHOT="${1:-}"
if [[ -z "$SNAPSHOT" ]]; then
    [[ -f "$DEBRICE_STATE_DIR/last-backup" ]] && SNAPSHOT="$(cat "$DEBRICE_STATE_DIR/last-backup")"
fi
if [[ -z "$SNAPSHOT" || ! -d "$SNAPSHOT" ]]; then
    log_error "No backup snapshot found. Available snapshots:"
    ls -1 "$DEBRICE_BACKUP_DIR" 2>/dev/null
    exit 1
fi

confirm "Restore configs from $SNAPSHOT? This overwrites current configs." || { log_info "Cancelled"; exit 0; }

log_step "Restoring from $SNAPSHOT"
for item in "$SNAPSHOT"/*; do
    name="$(basename "$item")"
    case "$name" in
        selection.env) cp -a "$item" "$DEBRICE_STATE_DIR/selection.env" ;;
        *) cp -a "$item" "$HOME/.config/$name" && log_ok "Restored $name" ;;
    esac
done

log_ok "Restore complete. Run 'hyprctl reload' or re-login for changes to take effect."
