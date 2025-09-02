# 🌅 Time-Based KDE / Conky / Konsole / VSCode Theming (CachyOS)

Automates **wallpaper**, **Plasma color scheme**, **Conky**, **Konsole profile**, **VSCode theme**, and **lockscreen video** based on the time of day:

- **🌅 Sunrise** (06:00–11:59) → VSCode: *Palenight (Mild Contrast)*
- **☀️ Noon** (12:00–17:59) → VSCode: *Material Theme High Contrast*
- **🌇 Sunset** (18:00–23:59) → VSCode: *Kimbie Dark*
- **🌙 Night** (00:00–05:59) → VSCode: *Night Owl*

A `systemd --user` timer applies changes **4× per day** (00:00, 06:00, 12:00, 18:00).

---

## 🗓️ Schedule at a glance

| Time Window | Wallpaper | Plasma Scheme | Konsole Scheme | VSCode Theme | Lockscreen Video |
|---|---|---|---|---|---|
| 06:00–11:59 (Sunrise) | `wallpapers/sunrise.png` | `Sunrise.colors` | `Sunrise.colorscheme` | Palenight (Mild Contrast) | `lockscreen/sunrise.mp4` |
| 12:00–17:59 (Noon) | `wallpapers/noon.png` | `Noon.colors` | `Noon.colorscheme` | Material Theme High Contrast | `lockscreen/noon.mp4` |
| 18:00–23:59 (Sunset) | `wallpapers/sunset.png` | `Sunset.colors` | `Sunset.colorscheme` | Kimbie Dark | `lockscreen/sunset.mp4` |
| 00:00–05:59 (Night) | `wallpapers/night.png` | `Night.colors` | `Night.colorscheme` | Night Owl | `lockscreen/night.mp4` |

> ⏱️ The timer units `theme-sync.service` / `theme-sync.timer` handle automatic switching.

---

## 🎨 Themes & Conky Preview

### Sunrise  
![Sunrise Wallpaper](wallpapers/sunrise.png)

### Noon  
![Noon Wallpaper](wallpapers/noon_example.png)

### Sunset  
![Sunset Wallpaper](wallpapers/sunset_example.png)

### Night  
![Night Wallpaper](wallpapers/night_example.png)

---

## ⚡ Quick Start (Arch / CachyOS, KDE Plasma 6)

```bash
# 1) Clone and install
git clone https://github.com/G33R0Y/kde-timebased-theming.git
cd kde-timebased-theming
./install.sh

# 2) Test once
~/.local/bin/rotate-wallpaper.sh
```

📜 Logs are stored in:  
`~/.local/share/wallpaper-sync.log`

---

## 🔧 What the installer does

- Installs dependencies:  
  `conky`, `fish`, `jq`, `qt6-tools`, `plasma-workspace`,  
  plus build dependencies for **Smart Video Wallpaper Reborn** (`extra-cmake-modules`, `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-multimedia-ffmpeg`, `git`, `cmake`, `make`).
- Builds and installs **Smart Video Wallpaper Reborn** (KDE plugin for animated wallpapers/lockscreen videos).
- Copies configs:
  - Konsole profile → `~/.local/share/konsole/TimeBased.profile`
  - Konsole color schemes → `~/.local/share/konsole/*.colorscheme`
  - Plasma color schemes → `~/.local/share/color-schemes/*.colors`
  - Conky config + Lua theme → `~/.config/conky/`
  - Fish config + helper → `~/.config/fish/`
  - Wallpapers → `~/Pictures/wallpapers/`
  - Lockscreen videos → `~/Videos/lockscreen/`
  - Theme sync script → `~/.local/bin/rotate-wallpaper.sh`
- Enables the **systemd user timer**:  
  `theme-sync.timer` (runs 4×/day).

---

## 📂 File Overview

```
scripts/rotate-wallpaper.sh          # applies wallpaper + Plasma scheme + Konsole + Conky + VSCode + lockscreen video
systemd-user/theme-sync.service
systemd-user/theme-sync.timer
konsole/TimeBased.profile
konsole/colorschemes/{Sunrise,Noon,Sunset,Night}.colorscheme
plasma-color-schemes/{Sunrise,Noon,Sunset,Night}.colors
conky/conky.conf
conky/theme_colors.lua
fish/config.fish
fish/set_terminal_theme.fish
wallpapers/{sunrise,noon,sunset,night}.png
lockscreen/{sunrise,noon,sunset,night}.mp4
```

---

## 💡 Notes & Tips

- **Fallback color schemes** if custom ones are missing:
  - Noon → BreezeLight  
  - Sunrise → Breeze  
  - Sunset → BreezeLight  
  - Night → BreezeDark  
- **Konsole**: Default profile is `TimeBased.profile`. If Konsole is already open, the Fish function applies the theme live via `qdbus`.  
- **Lock screen videos**: Managed by Smart Video Wallpaper Reborn. The timer switches them automatically (`~/Videos/lockscreen/`).  
- **VSCode**:  
  - Themes automatically applied per time of day.  
  - Required extensions are installed if missing:  
    - `whizkydee.material-palenight-theme`  
    - `equinusocio.vsc-material-theme`  
    - `sdras.night-owl`  
  - Works with both **VS Code** and **VSCodium**.  
  - Updates `settings.json` in:  
    - `~/.config/Code/User/` (VSCode)  
    - `~/.config/VSCodium/User/` (VSCodium)  
- **Wallpapers & videos**: Replace the placeholders in `~/Pictures/wallpapers/` and `~/Videos/lockscreen/` with your own (keep filenames).  
- **Placeholders safe to tweak**: Edit any `.colors`, `.colorscheme`, or video files to match your palette.

---

## ⚙️ Manual systemd commands

```bash
systemctl --user daemon-reload
systemctl --user enable --now theme-sync.timer
systemctl --user list-timers | grep theme-sync
systemctl --user start theme-sync.service  # run immediately
journalctl --user -u theme-sync.service -e --no-pager
```

### Explanation

* **`systemctl --user daemon-reload`** → Reloads the user-level systemd manager so it picks up new/changed units (needed after `install.sh` places them).
* **`systemctl --user enable --now theme-sync.timer`** → Enables the timer persistently (autostart at login) and starts it immediately.
* **`systemctl --user list-timers | grep theme-sync`** → Shows whether your timer is scheduled correctly (you should see the next activation time).
* **`systemctl --user start theme-sync.service`** → Runs the service immediately once, without waiting for the timer. Good for testing.
* **`journalctl --user -u theme-sync.service -e --no-pager`** → Lets you check logs for the service specifically (your `rotate-wallpaper.sh` output + errors).

---

## ❌ Uninstall

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
rm -f ~/Videos/lockscreen/{sunrise,noon,sunset,night}.mp4
# (optionally) edit ~/.config/fish/config.fish to remove the call to set_terminal_theme
# (optionally) remove VSCode theme settings from ~/.config/Code/User/settings.json or ~/.config/VSCodium/User/settings.json
```

---

✨ **Happy theming!**
