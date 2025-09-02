#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing dependencies (Arch/CachyOS)..."
sudo pacman -S --needed --noconfirm conky fish jq plasma-workspace

echo "==> Creating directories..."
mkdir -p "$HOME/.local/share/konsole" \
         "$HOME/.local/share/color-schemes" \
         "$HOME/.config/conky" \
         "$HOME/.config/fish/functions" \
         "$HOME/Pictures/wallpapers" \
         "$HOME/.config/systemd/user" \
         "$HOME/.local/bin"

echo "==> Copying files..."
cp -fv konsole/TimeBased.profile "$HOME/.local/share/konsole/"
cp -fv konsole/colorschemes/*.colorscheme "$HOME/.local/share/konsole/"
cp -fv plasma-color-schemes/*.colors "$HOME/.local/share/color-schemes/"
cp -fv conky/conky.conf "$HOME/.config/conky/"
cp -fv conky/theme_colors.lua "$HOME/.config/conky/"
cp -fv fish/config.fish "$HOME/.config/fish/"
cp -fv fish/set_terminal_theme.fish "$HOME/.config/fish/functions/"
cp -fv wallpapers/* "$HOME/Pictures/wallpapers/"
cp -fv scripts/rotate-wallpaper.sh "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/rotate-wallpaper.sh"

echo "==> Installing systemd user units..."
cp -fv systemd-user/theme-sync.service "$HOME/.config/systemd/user/"
cp -fv systemd-user/theme-sync.timer "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now theme-sync.timer

echo "==> Done. You can test immediately with:"
echo "    bash $HOME/.local/bin/rotate-wallpaper.sh"