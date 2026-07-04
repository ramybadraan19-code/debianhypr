#!/usr/bin/env bash
# ==============================================================================
# DebRice installer — one-command Hyprland rice for Debian Trixie.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/ramybadraan19-code/debianhypr/main/install.sh)
#
# This script is safe to re-run (idempotent): it backs up existing configs
# before touching them, skips already-installed packages, and can recover
# from a partial/failed run.
# ==============================================================================
set -uo pipefail

REPO_URL="https://github.com/ramybadraan19-code/debianhypr.git"
REPO_RAW="https://raw.githubusercontent.com/ramybadraan19-code/debianhypr/main"
INSTALL_HOME="$HOME/.local/share/debrice"
REPO_DIR="$INSTALL_HOME/repo"

# ---- Bootstrap: if this script is running standalone (curl | bash), clone
#      the full repo first so we have every script/config/theme available.
#      If it's already running from inside a cloned repo, just use that.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || true)"

bootstrap_repo() {
    mkdir -p "$INSTALL_HOME"
    if [[ -n "$SELF_DIR" && -f "$SELF_DIR/scripts/lib.sh" ]]; then
        echo "[INFO] Running from a local checkout ($SELF_DIR) — using it directly."
        REPO_DIR="$SELF_DIR"
        return
    fi

    echo "[INFO] Fetching DebRice repository..."
    if command -v git >/dev/null 2>&1; then
        if [[ -d "$REPO_DIR/.git" ]]; then
            git -C "$REPO_DIR" pull --ff-only || echo "[WARN] git pull failed, continuing with existing checkout"
        else
            rm -rf "$REPO_DIR"
            git clone --depth 1 "$REPO_URL" "$REPO_DIR" || {
                echo "[ERROR] Failed to clone $REPO_URL. Check your network/DNS and try again." >&2
                exit 1
            }
        fi
    else
        echo "[ERROR] git is required to bootstrap the installer. Installing git first..."
        sudo apt-get update -y && sudo apt-get install -y git
        bootstrap_repo
        return
    fi
}

# Ensure sudo is available and cache credentials early (installer needs root
# for apt operations; we ask once up front rather than repeatedly).
ensure_sudo() {
    if [[ $EUID -eq 0 ]]; then
        echo "[ERROR] Do not run DebRice's installer as root. Run as your normal user; it will call sudo when needed." >&2
        exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[ERROR] sudo is required. Install it as root first: apt install sudo" >&2
        exit 1
    fi
    echo "[INFO] Requesting sudo access (needed for package installation)..."
    sudo -v || { echo "[ERROR] sudo authentication failed."; exit 1; }
    # Keep sudo alive for the duration of the install
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
}

bootstrap_repo
ensure_sudo

# shellcheck disable=SC1091
source "$REPO_DIR/scripts/lib.sh"
enable_strict_error_trap

banner
log_info "Repo: $REPO_DIR"
log_info "Full install log: $DEBRICE_LOG_FILE"

# ---- Pre-flight checks ----------------------------------------------------
log_step "Pre-flight checks"
if [[ ! -f /etc/debian_version ]]; then
    log_warn "This does not look like a Debian system. Continuing anyway (DEBRICE_FORCE=1 assumed)."
fi
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    log_warn "You appear to already be in a Wayland session. Hyprland will still be installed for next login."
fi
push_rollback "log_warn 'Installer aborted — see log for details: $DEBRICE_LOG_FILE'"

# ---- 1. Update Debian -------------------------------------------------
log_step "Step 1/8 — Updating Debian"
sudo apt-get update -y
if confirm "Run a full 'apt-get upgrade' now? (recommended, can take a while)" "y"; then
    sudo apt-get upgrade -y
fi

# ---- 2. Hardware detection -----------------------------------------------
log_step "Step 2/8 — Detecting hardware"
bash "$REPO_DIR/scripts/detect-hardware.sh"
# shellcheck disable=SC1090
source "$DEBRICE_STATE_DIR/hardware.env"

# ---- 3. Backup existing configs -------------------------------------------
log_step "Step 3/8 — Backing up existing configs"
for cfg in hypr waybar kitty rofi mako eww gtk-3.0 gtk-4.0 dolphinrc; do
    backup_path "$HOME/.config/$cfg"
done
log_ok "Existing configs (if any) backed up to $DEBRICE_BACKUP_DIR/$DEBRICE_SESSION"

# ---- 4. Install packages ---------------------------------------------------
log_step "Step 4/8 — Installing Hyprland and full package set"
bash "$REPO_DIR/scripts/install-packages.sh"

# ---- 5. Theme / icon / cursor selection ------------------------------------
log_step "Step 5/8 — Theme selection"
if [[ "${DEBRICE_NONINTERACTIVE:-0}" != "1" ]]; then
    echo
    echo "Which Waybar style would you like? (you can change this anytime with 'debrice theme')"
    select style in modern minimal floating glass macos windows11 cyberpunk rounded; do
        [[ -n "$style" ]] && export DEBRICE_WAYBAR_STYLE="$style" && break
    done
fi
bash "$REPO_DIR/scripts/theme-select.sh"

# ---- 6. Configure keyboard layout, SDDM, wallpaper --------------------------
log_step "Step 6/8 — Configuring keyboard layout, SDDM, wallpapers"
mkdir -p "$HOME/.config"
if [[ -d /usr/share/sddm/themes ]]; then
    sudo cp -r "$REPO_DIR/sddm-theme/debrice" /usr/share/sddm/themes/debrice
    sudo mkdir -p /etc/sddm.conf.d
    printf "[Theme]\nCurrent=debrice\n" | sudo tee /etc/sddm.conf.d/debrice.conf >/dev/null
    sudo systemctl enable sddm >/dev/null 2>&1 || true
    log_ok "SDDM theme installed and enabled"
else
    log_warn "SDDM theme directory not found — is sddm installed? Skipping SDDM theming."
fi
bash "$REPO_DIR/scripts/wallpaper-engine.sh" --random || log_warn "No wallpapers found yet; add images under wallpapers/<theme>/ and re-run 'debrice wallpaper --random'"

# ---- 7. Install the debrice CLI --------------------------------------------
log_step "Step 7/8 — Installing the 'debrice' CLI"
sudo install -m 755 "$REPO_DIR/bin/debrice" /usr/local/bin/debrice
log_ok "Installed: $(command -v debrice)"

# Desktop entry so DebRice Dashboard shows up in the app launcher
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/debrice-dashboard.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DebRice Dashboard
Comment=Manage your DebRice Hyprland rice
Exec=debrice dashboard
Icon=preferences-desktop-theme
Categories=Settings;
EOF

# ---- 8. Final checks + reboot prompt --------------------------------------
log_step "Step 8/8 — Final verification"
bash "$REPO_DIR/scripts/doctor.sh" || true

echo
log_ok "DebRice installation complete!"
echo -e "${C_BOLD}What's next:${C_RESET}"
echo "  • Log out and select 'Hyprland' at the SDDM login screen."
echo "  • Run 'debrice dashboard' for the graphical control panel."
echo "  • Run 'debrice --help' to see all CLI commands."
echo "  • Full install log saved to: $DEBRICE_LOG_FILE"
echo

kill "${SUDO_KEEPALIVE_PID:-0}" 2>/dev/null || true

if confirm "Reboot now to finish setup?" "y"; then
    log_info "Rebooting..."
    sudo reboot
else
    log_info "Remember to reboot (or at least fully log out) before using Hyprland."
fi
