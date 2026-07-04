# DebRice Assets

This directory holds binary/visual assets that ship with the rice:

- `fonts/` — bundled fallback fonts (Nerd Fonts are downloaded by the installer
  at install time to keep the repo lightweight; drop any custom `.ttf`/`.otf`
  files here to have them auto-installed too).
- `icons/` — DebRice's own logo/icon set, used by the dashboard and Rofi.
- Wallpapers live in `/wallpapers/<theme-slug>/` at the repo root, one folder
  per theme, so `debrice wallpaper` and the wallpaper engine can offer
  theme-matched sets. Each theme folder needs at least one image named
  `default.jpg`.
