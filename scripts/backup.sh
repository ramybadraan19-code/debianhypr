#!/usr/bin/env bash
# DebRice — full config backup (used by installer, CLI `debrice backup`, and dashboard)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TARGET="$DEBRICE_BACKUP_DIR/manual-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TARGET"

log_step "Backing up DebRice-managed configs to $TARGET"
PATHS=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/kitty"
    "$HOME/.config/rofi"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/gtk-4.0"
    "$HOME/.config/mako"
    "$HOME/.config/eww"
    "$DEBRICE_STATE_DIR/selection.env"
)
for p in "${PATHS[@]}"; do
    [[ -e "$p" ]] || continue
    dest="$TARGET/$(basename "$p")"
    cp -a "$p" "$dest" 2>/dev/null && log_ok "Backed up $(basename "$p")"
done

echo "$TARGET" > "$DEBRICE_STATE_DIR/last-backup"
log_ok "Backup complete: $TARGET"
