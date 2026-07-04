# Adding a new Waybar style

1. Create `configs/waybar/styles/<name>/config.jsonc` (module layout —
   copy `configs/waybar/base-config.jsonc` and adjust `modules-left` /
   `modules-center` / `modules-right`, position, height, margin).
2. Create `configs/waybar/styles/<name>/style.css.template` using the same
   `{{PLACEHOLDER}}` tokens as the other 8 styles (see any existing style for
   the full token list: `{{BG_HEX_A}}`, `{{ACCENT_HEX}}`, `{{ROUNDING}}`, etc).
3. Run `debrice theme <theme> <name>` to preview it instantly.
