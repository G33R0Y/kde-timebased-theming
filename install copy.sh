#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing dependencies (Arch/CachyOS)..."
sudo pacman -S --needed --noconfirm conky qt6-tools plasma-workspace

echo "==> Creating directories..."
mkdir -p "$HOME/.local/share/konsole" \
         "$HOME/.local/share/color-schemes" \
         "$HOME/.config/conky" \
         "$HOME/.config/fish" \
         "$HOME/Pictures/wallpapers" \
         "$HOME/.config/systemd/user"

echo "==> Copying files..."
cp -fv konsole/TimeBased.profile "$HOME/.local/share/konsole/"
cp -fv konsole/colorschemes/*.colorscheme "$HOME/.local/share/konsole/"
cp -fv plasma-color-schemes/*.colors "$HOME/.local/share/color-schemes/"
cp -fv conky/conky.conf "$HOME/.config/conky/"
cp -fv conky/theme_colors.lua "$HOME/.config/conky/"
cp -fv fish/config.fish "$HOME/.config/fish/"
cp -fv fish/set_terminal_theme.fish "$HOME/.config/fish/"
cp -fv wallpapers/* "$HOME/Pictures/wallpapers/"
mkdir -p "$HOME/scripts"
cp -fv scripts/rotate-wallpaper.sh "$HOME/scripts/"
chmod +x "$HOME/scripts/rotate-wallpaper.sh"

echo "==> Installing systemd user units..."
cp -fv systemd-user/theme-sync.service "$HOME/.config/systemd/user/"
cp -fv systemd-user/theme-sync.timer "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now theme-sync.timer

echo "==> Done. You can test immediately with:"
echo "    bash $HOME/scripts/rotate-wallpaper.sh"
