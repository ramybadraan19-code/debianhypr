# DebRice Architecture

## Design principle: one source of truth per concern

- **Hardware facts** live in `$DEBRICE_STATE_DIR/hardware.env`, written once by
  `scripts/detect-hardware.sh` and read by everything else (installer, theme
  engine, dashboard).
- **User selections** (theme, waybar style, icons, cursor) live in
  `$DEBRICE_STATE_DIR/selection.env`, written by `scripts/theme-select.sh` /
  the dashboard / the CLI, and read by `scripts/apply-theme.sh`.
- **Theme colors** live in `themes/<slug>/colors.sh` — a flat set of shell
  variables (`BG`, `FG`, `ACCENT`, ...). Nothing else defines colors.
- **All rendered app configs** (`hyprland.conf`, `waybar/style.css`,
  `kitty.conf`, `rofi/theme.rasi`, `mako/config`, `eww/eww.scss`, GTK CSS,
  Dolphin's `dolphinrc`) are generated from `*.template` files under
  `configs/` by `scripts/apply-theme.sh`, which substitutes `{{PLACEHOLDER}}`
  tokens. This is the only script that writes into `~/.config`.

This means: to add a 9th theme, you only add `themes/my-theme/colors.sh` — no
template needs to change. To add a 9th Waybar style, you only add
`configs/waybar/styles/my-style/{config.jsonc,style.css.template}`.

## Execution flow

```
install.sh
 ├─ scripts/detect-hardware.sh      → hardware.env
 ├─ scripts/install-packages.sh     → apt packages (hardware-conditional)
 ├─ scripts/theme-select.sh         → selection.env
 │   └─ scripts/apply-theme.sh      → renders every template into ~/.config
 ├─ SDDM theme install
 ├─ scripts/wallpaper-engine.sh     → sets wallpaper + pywal recolor
 └─ bin/debrice → /usr/local/bin/debrice
```

After install, `debrice <command>` and the Dashboard both call the exact same
scripts, so there is only one code path to maintain per feature.

## Idempotency & rollback

- `apt_install()` in `scripts/lib.sh` only installs packages that are missing.
- `backup_path()` snapshots any existing file/dir before DebRice overwrites
  it, once per install session, skipping paths that are already DebRice's own
  symlinks.
- `push_rollback` / `run_rollback` in `scripts/lib.sh` record undo actions as
  the installer progresses; `enable_strict_error_trap` triggers a rollback and
  clean exit on any unexpected command failure.
