# Dashboard Modules

This directory is reserved for future modular extensions to the DebRice Dashboard.
Each module would be a separate Python file imported by `main.py`.

Current tabs are defined inline in `main.py`:
- `ThemesTab` — theme and waybar style picker
- `WallpaperTab` — wallpaper engine controls
- `AppearanceTab` — icons, cursor, blur, transparency settings
- `SystemTab` — info, update, backup, restore, doctor

To add a new module, create a `.py` file here and import it in `main.py`.
