# Time‑Based KDE/Conky/Konsole Theming (CachyOS)

Automates wallpaper + Plasma color scheme + Conky + Konsole profile based on time of day:
- **Sunrise** (06:00–11:59)
- **Noon** (12:00–17:59)
- **Sunset** (18:00–23:59)
- **Night** (00:00–05:59)

Includes a systemd user timer that runs at 00:00, 06:00, 12:00, 18:00.

## Themes Preview

Here are previews of the wallpapers used for each time-based theme (already uploaded to the repo):

### Sunrise
![Sunrise Wallpaper](wallpapers/sunrise.png)

### Noon
![Noon Wallpaper](wallpapers/noon.png)

### Sunset
![Sunset Wallpaper](wallpapers/sunset.png)

### Night
![Night Wallpaper](wallpapers/night.png)

## Quick start (Arch/CachyOS, KDE Plasma 6)

```bash
# 1) Clone and install
git clone https://github.com/G33R0Y/kde-timebased-theming.git
cd kde-timebased-theming
./install.sh

# 2) Test once
bash ~/scripts/rotate-wallpaper.sh
```

> Logs: `~/.local/share/wallpaper-sync.log`

## What the installer does

- Installs deps: `conky`, `qt6-tools` (for qdbus), `plasma-workspace` (for `plasma-apply-colorscheme`).
- Copies:
  - Konsole profile → `~/.local/share/konsole/TimeBased.profile`
  - Konsole color schemes → `~/.local/share/konsole/*.colorscheme`
  - Plasma color schemes → `~/.local/share/color-schemes/*.colors`
  - Conky config & Lua theme → `~/.config/conky/`
  - Fish config & helper → `~/.config/fish/`
  - Wallpapers (placeholders) → `~/Pictures/wallpapers/`
  - Theme sync script → `~/scripts/rotate-wallpaper.sh`
- Enables the systemd user **timer** `theme-sync.timer` (runs 4×/day).

## Files

```
scripts/rotate-wallpaper.sh          # applies wallpaper + Plasma scheme + Konsole + Conky
systemd-user/theme-sync.service
systemd-user/theme-sync.timer
konsole/TimeBased.profile
konsole/colorschemes/{Sunrise,Noon,Sunset,Night}.colorscheme
plasma-color-schemes/{Sunrise,Noon,Sunset,Night}.colors
conky/conky.conf
conky/theme_colors.lua
fish/config.fish
fish/set_terminal_theme.fish
wallpapers/{sunrise,noon,sunset,night}.png    # solid-color placeholders
```

## Notes & tips

- **Missing color schemes?** The script gracefully falls back to KDE’s built‑ins:
  - `Noon → BreezeLight`, `Sunrise → Breeze`, `Sunset → BreezeLight`, `Night → BreezeDark`.
- **Konsole**: Default profile is set to `TimeBased.profile`. If Konsole is open, the fish function tries to apply it live via `qdbus`.
- **Lock screen**: Updated only when the screen locker is not running to avoid flicker.
- **Placeholders**: Replace the wallpapers in `~/Pictures/wallpapers/` with your own (keep filenames). You can also tweak all `.colors` and `.colorscheme` files.

## Manual systemd commands

```bash
systemctl --user daemon-reload
systemctl --user enable --now theme-sync.timer
systemctl --user list-timers | grep theme-sync
systemctl --user start theme-sync.service  # run immediately
journalctl --user -u theme-sync.service -e --no-pager
```

## Uninstall

```bash
systemctl --user disable --now theme-sync.timer
rm -f ~/.config/systemd/user/theme-sync.{service,timer}
systemctl --user daemon-reload

rm -f ~/.local/share/konsole/TimeBased.profile
rm -f ~/.local/share/konsole/{Sunrise,Noon,Sunset,Night}.colorscheme
rm -f ~/.local/share/color-schemes/{Sunrise,Noon,Sunset,Night}.colors
rm -f ~/scripts/rotate-wallpaper.sh
rm -f ~/.config/conky/conky.conf ~/.config/conky/theme_colors.lua
rm -f ~/.config/fish/set_terminal_theme.fish
# (optionally) edit ~/.config/fish/config.fish to remove the call to set_terminal_theme
```

Happy theming ✨
