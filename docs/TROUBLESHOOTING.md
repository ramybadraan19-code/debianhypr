# Troubleshooting

Run `debrice doctor` first — it checks every dependency and config file and
tells you exactly what's missing.

**Hyprland won't start / black screen after login**
- Check `~/.local/share/debrice/logs/` for the install log.
- Verify GPU drivers: `debrice info` shows detected GPU vendor; NVIDIA users
  should confirm `nvidia-smi` works and that `WLR_NO_HARDWARE_CURSORS=1` is
  set (DebRice sets this automatically when NVIDIA is detected).

**Waybar shows no icons**
- A Nerd Font wasn't installed correctly. Re-run:
  `bash ~/.local/share/debrice/repo/scripts/install-packages.sh`

**Theme doesn't seem to change anything**
- Run `debrice theme <slug>` directly rather than through Rofi to see errors.
- Confirm `~/.config/hypr/hyprland.conf` was actually rewritten
  (`grep THEME_NAME` should show nothing — it's replaced at render time).

**Something is broken after an update**
- `debrice restore` rolls back to the most recent automatic backup.
- `debrice repair` re-runs package install + re-applies your current theme.

**Full reset**
- `debrice reset` backs up your current setup and restores Catppuccin /
  Papirus / Bibata Ice / Modern Waybar defaults.
