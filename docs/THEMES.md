# Adding a new DebRice theme

1. Create `themes/<slug>/colors.sh` with these variables (see
   `themes/catppuccin/colors.sh` for a full example):
   `THEME_NAME, BG, BG_ALT, FG, FG_ALT, ACCENT, ACCENT2, RED, GREEN, YELLOW,
   BLUE, MAGENTA, CYAN, BORDER_ACTIVE, BORDER_INACTIVE, BLUR, TRANSPARENCY,
   ROUNDING`.
2. Add a `wallpapers/<slug>/default.jpg` (and any extras for the wallpaper
   engine to pick from).
3. Run `debrice theme <slug>` or select it from the Dashboard/installer menu.

No other file needs to change — every app config is generated from these
variables via the templates in `configs/`.
