# DebRice

A fully automated, production-grade Hyprland rice for **Debian Trixie (Testing)** —
one command turns a fresh Debian install into a beautiful, modern, tiling
Wayland desktop with a smart hardware-aware installer, 8 curated themes, 8
Waybar styles, a live theme engine, desktop widgets, a custom SDDM login
screen, and a graphical dashboard.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ramybadraan19-code/debianhypr/main/install.sh)
```

Run as your normal user (not root) on a fresh or existing Debian Trixie
system. The installer will ask for `sudo` once and cache it for the session.

The installer will:

1. Update Debian.
2. Detect your CPU, GPU, RAM, chassis type (laptop/desktop), screen
   resolution, existing desktop environment, and Wayland readiness — and tune
   Hyprland's blur/animations/scaling accordingly.
3. Back up any existing Hyprland/Waybar/Kitty/Rofi/GTK configs.
4. Install Hyprland and the entire rice stack (~60 packages), with
   GPU-vendor-conditional drivers (NVIDIA/AMD/Intel) and laptop-only power
   tools (TLP, brightness control).
5. Let you interactively choose a theme, Waybar style, icon pack, and cursor.
6. Install a custom SDDM login theme and set up the wallpaper engine.
7. Install the `debrice` CLI.
8. Offer to reboot.

Re-running the installer is safe — it's idempotent and will not duplicate
work or break an existing setup.

## What you get

| Category | Options |
|---|---|
| **Themes** | Catppuccin, Tokyo Night, Nord, Dracula, Gruvbox, AMOLED Black, Glassmorphism, Cyberpunk Neon |
| **Waybar styles** | Modern, Minimal, Floating, Glass, macOS-inspired, Windows 11-inspired, Cyberpunk, Rounded |
| **Icon packs** | Papirus, Tela, Colloid, WhiteSur |
| **Cursors** | Bibata Modern Ice, Bibata Modern Classic, Nordzy |

Every theme drives Hyprland's colors/blur/rounding, Waybar, Kitty, Rofi, GTK,
Dolphin, Mako notifications, and EWW desktop widgets from **one** file
(`themes/<slug>/colors.sh`) — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

Also included: Cava audio visualizer embedded in Waybar (auto-hides when
audio stops), animated EWW desktop widgets (clock, weather, music, system
stats), a Hyprlock lock screen matching your theme, English/Arabic keyboard
switching (Alt+Shift, with notification + Waybar indicator), a themed Rofi
with app launcher / power menu / clipboard manager / emoji picker / calculator
/ Wi-Fi menu / Bluetooth menu / live theme switcher, a wallpaper engine with
chooser/random/slideshow/hourly modes and full Pywal auto-recoloring, and a
floating PyQt6 **DebRice Dashboard** for managing all of it graphically.

## The `debrice` CLI

```
debrice update              # pull latest release, re-apply your config
debrice theme [name]        # interactive picker, or apply directly
debrice wallpaper [opts]    # --choose | --random | --slideshow | --hourly
debrice doctor              # health check
debrice repair              # attempt automatic fixes
debrice backup              # snapshot current configs
debrice restore [snapshot]  # roll back
debrice reset               # restore defaults (Catppuccin/Papirus/Bibata Ice)
debrice dashboard           # launch the graphical control panel
debrice version / info      # version and current system/theme info
```

## Project structure

```
debianhypr/
├── install.sh          # single entrypoint (curl | bash)
├── update.sh / uninstall.sh / repair.sh
├── VERSION
├── .gitignore
├── configs/            # *.template configs for every app (theme-agnostic)
│   ├── hypr/           #   Hyprland, hypridle
│   ├── hyprlock/       #   lock screen
│   ├── kitty/          #   terminal
│   ├── rofi/           #   app launcher + scripts (wifi, bt, clipboard, etc.)
│   ├── waybar/         #   8 waybar styles + base config
│   ├── mako/           #   notification daemon
│   ├── eww/            #   desktop widgets
│   ├── wlogout/        #   logout menu
│   ├── gtk-3.0/        #   GTK CSS
│   └── dolphin/        #   KDE file manager
├── themes/             # 8 theme color definitions (single source of truth)
├── wallpapers/         # per-theme wallpaper sets + wallpaper engine assets
├── scripts/            # all bash logic: detection, install, theme engine,
│                         wallpaper engine, keyboard layout, cava, weather,
│                         backup/restore/reset/doctor
├── dashboard/          # PyQt6 floating dashboard app
├── bin/debrice         # the CLI tool
├── sddm-theme/         # custom QML SDDM login theme
├── assets/             # fonts/icons shipped with the repo
└── docs/               # architecture, theming guide, troubleshooting
```

## Requirements

- A fresh or existing **Debian Trixie (testing)** installation.
- A regular user account with `sudo` access.
- Internet access during install (package downloads, Nerd Fonts, EWW binary,
  git clone).

## Uninstalling

```bash
~/.local/share/debrice/repo/uninstall.sh
```

Removes DebRice's own configs, the CLI, and the SDDM theme. Does not remove
Hyprland or other packages, since they may be used independently.

## Contributing

See [`docs/THEMES.md`](docs/THEMES.md) and
[`docs/WAYBAR_STYLES.md`](docs/WAYBAR_STYLES.md) for how to add a new theme or
Waybar style — both are single-file additions, no core code changes needed.

## License

MIT — see [`LICENSE`](LICENSE).
