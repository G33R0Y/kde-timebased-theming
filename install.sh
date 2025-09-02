#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing dependencies (Arch/CachyOS)..."
sudo pacman -S --needed --noconfirm \
    conky fish jq plasma-workspace qt6-tools \
    extra-cmake-modules qt6-base qt6-declarative \
    qt6-multimedia qt6-multimedia-ffmpeg git cmake make

echo "==> Creating directories..."
mkdir -p "$HOME/.local/share/konsole" \
         "$HOME/.local/share/color-schemes" \
         "$HOME/.config/conky" \
         "$HOME/.config/fish/functions" \
         "$HOME/Pictures/wallpapers" \
         "$HOME/Videos/lockscreen" \
         "$HOME/.config/systemd/user" \
         "$HOME/.local/bin"

echo "==> Copying configs..."
# Konsole
cp -fv konsole/TimeBased.profile "$HOME/.local/share/konsole/" || true
cp -fv konsole/colorschemes/*.colorscheme "$HOME/.local/share/konsole/" || true

# Plasma color schemes
cp -fv plasma-color-schemes/*.colors "$HOME/.local/share/color-schemes/" || true

# Conky
cp -fv conky/conky.conf "$HOME/.config/conky/" || true
cp -fv conky/theme_colors.lua "$HOME/.config/conky/" || true

# Fish
cp -fv fish/config.fish "$HOME/.config/fish/" || true
cp -fv fish/set_terminal_theme.fish "$HOME/.config/fish/functions/" || true

# Wallpapers
cp -fv wallpapers/* "$HOME/Pictures/wallpapers/" || true

# Lockscreen videos
cp -fv lockscreen/*.mp4 "$HOME/Videos/lockscreen/" || true

# Rotation script
cp -fv scripts/rotate-wallpaper.sh "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/rotate-wallpaper.sh"

echo "==> Installing systemd user units..."
cp -fv systemd-user/theme-sync.service "$HOME/.config/systemd/user/"
cp -fv systemd-user/theme-sync.timer "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now theme-sync.timer

# --- Smart Video Wallpaper Reborn ---
if ! plasmapkg2 --list | grep -q "org.kde.plasma.smartvideo"; then
    echo "==> Installing Smart Video Wallpaper Reborn (for lockscreen videos)..."
    TMPDIR=$(mktemp -d)
    git clone https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn.git "$TMPDIR"
    pushd "$TMPDIR"
    mkdir build && cd build
    cmake ..
    make -j"$(nproc)"
    sudo make install
    popd
    rm -rf "$TMPDIR"
else
    echo "Smart Video Wallpaper Reborn already installed."
fi

echo "==> Done!"
echo "    Test with: $HOME/.local/bin/rotate-wallpaper.sh"
echo "    Logs:      ~/.local/share/wallpaper-sync.log"
