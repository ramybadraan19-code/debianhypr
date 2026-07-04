#!/usr/bin/env bash
# ==============================================================================
# DebRice package installer. Installs Hyprland + full rice stack, with
# hardware-conditional packages (GPU drivers, laptop tools).
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
[[ -f "$DEBRICE_STATE_DIR/hardware.env" ]] && source "$DEBRICE_STATE_DIR/hardware.env"

log_step "Updating Debian package lists"
sudo apt-get update -y || log_warn "apt update reported issues, continuing"

log_step "Enabling Trixie (testing) sources check"
if ! grep -rq "trixie" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    log_warn "Trixie not detected in apt sources — assuming system is already on Trixie/testing."
fi

log_step "Installing core system + build tools"
apt_install build-essential git curl wget unzip zip jq pciutils usbutils \
    software-properties-common ca-certificates gnupg apt-transport-https \
    fontconfig fonts-noto fonts-noto-color-emoji

log_step "Installing Hyprland and Wayland ecosystem"
apt_install hyprland xdg-desktop-portal-hyprland waybar wofi rofi \
    hyprpaper hyprlock hypridle wl-clipboard cliphist grim slurp \
    swappy mako wlogout polkit-kde-agent-1 qt6-wayland qt5-wayland \
    xwayland xdg-utils xdg-user-dirs

log_step "Installing audio (PipeWire) stack"
apt_install pipewire pipewire-audio wireplumber pipewire-pulse pipewire-alsa \
    pavucontrol playerctl

log_step "Installing terminal, shell and CLI utilities"
apt_install kitty fish zsh fastfetch btop htop unzip p7zip-full ripgrep fd-find \
    eza bat tmux

log_step "Installing file manager and viewers"
apt_install dolphin ark okular gwenview kio kio-extras ffmpegthumbs

log_step "Installing network / bluetooth managers"
apt_install network-manager network-manager-gnome blueman bluez

log_step "Installing screenshot / recording tools"
apt_install grim slurp wf-recorder

log_step "Installing theming tools"
apt_install papirus-icon-theme gtk2-engines-murrine gtk2-engines-pixbuf \
    sassc qt6ct qt5ct kvantum kvantum-qt5 lxappearance

log_step "Installing fonts (Nerd Fonts + Fira Code)"
mkdir -p "$HOME/.local/share/fonts/NerdFonts"
if [[ ! -f "$HOME/.local/share/fonts/NerdFonts/.installed" ]]; then
    tmp="$(mktemp -d)"
    for font in "JetBrainsMono" "FiraCode" "Hack"; do
        log_info "Fetching Nerd Font: $font"
        curl -fsSL -o "$tmp/$font.zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip" \
            && unzip -oq "$tmp/$font.zip" -d "$HOME/.local/share/fonts/NerdFonts" "*.ttf" 2>/dev/null \
            || log_warn "Could not fetch $font (offline or rate-limited) — skipping"
    done
    touch "$HOME/.local/share/fonts/NerdFonts/.installed"
    fc-cache -f >/dev/null 2>&1 || true
    rm -rf "$tmp"
else
    log_ok "Nerd Fonts already installed"
fi

log_step "Installing SDDM display manager"
apt_install sddm qtdeclarative6-dev qml6-module-qtquick qml6-module-qtquick-controls2 \
    qml6-module-qtquick-layouts qml6-module-qtgraphicaleffects

log_step "Installing Python + Qt6 (for DebRice Dashboard)"
apt_install python3 python3-pip python3-venv python3-pyqt6 python3-requests

log_step "Installing pywal / colorscheme engine"
if ! command_exists wal; then
    pip3 install --break-system-packages --quiet pywal16 2>/dev/null \
        || pip3 install --user --quiet pywal16 2>/dev/null \
        || log_warn "pywal install failed via pip — theme auto-recolor will be limited"
fi

log_step "Installing EWW (widgets) and Cava (audio visualizer)"
apt_install cava
if ! command_exists eww; then
    log_warn "EWW is not packaged in Debian repos; attempting prebuilt binary install"
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/eww" \
        "https://github.com/elkowar/eww/releases/latest/download/eww-x86_64-linux"; then
        chmod +x "$tmp/eww"
        sudo mv "$tmp/eww" /usr/local/bin/eww
        log_ok "EWW installed to /usr/local/bin/eww"
    else
        log_warn "Could not fetch EWW binary (offline?). Install manually later: cargo install eww"
    fi
    rm -rf "$tmp"
fi

# ---- GPU-conditional packages -------------------------------------------
case "${GPU_VENDOR:-unknown}" in
    nvidia)
        log_step "NVIDIA GPU detected — installing proprietary driver + Wayland fixes"
        apt_install nvidia-driver firmware-misc-nonfree nvidia-vaapi-driver \
            libnvidia-egl-wayland1
        ;;
    amd)
        log_step "AMD GPU detected — installing Mesa/RADV stack"
        apt_install mesa-vulkan-drivers libgl1-mesa-dri firmware-amd-graphics
        ;;
    intel)
        log_step "Intel GPU detected — installing Mesa/Intel media driver"
        apt_install mesa-vulkan-drivers intel-media-va-driver-non-free libgl1-mesa-dri
        ;;
    *)
        log_warn "Unknown GPU vendor — installing generic Mesa drivers"
        apt_install mesa-vulkan-drivers libgl1-mesa-dri
        ;;
esac

# ---- Laptop-conditional packages ------------------------------------------
if [[ "${CHASSIS_TYPE:-desktop}" == "laptop" ]]; then
    log_step "Laptop detected — installing power management + brightness tools"
    apt_install tlp tlp-rdw brightnessctl acpi upower
    sudo systemctl enable --now tlp.service 2>/dev/null || true
fi

log_ok "Package installation stage complete"
