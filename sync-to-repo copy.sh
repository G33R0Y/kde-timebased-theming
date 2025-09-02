#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/Downloads/kde-timebased-theming"
MAIN_SCRIPT="$HOME/.local/bin/rotate-wallpaper.sh"

echo "==> Syncing configs into $REPO_DIR"

# Plasma color schemes
cp -fv ~/.local/share/color-schemes/*.colors "$REPO_DIR/plasma-color-schemes/"

# Konsole
cp -fv ~/.local/share/konsole/*.colorscheme "$REPO_DIR/konsole/colorschemes/" || true
cp -fv ~/.local/share/konsole/TimeBased.profile "$REPO_DIR/konsole/" || true

# Conky
cp -fv ~/.config/conky/conky.conf "$REPO_DIR/conky/" || true
cp -fv ~/.config/conky/theme_colors.lua "$REPO_DIR/conky/" || true

# Fish
cp -fv ~/.config/fish/config.fish "$REPO_DIR/fish/" || true
cp -fv ~/.config/fish/functions/set_terminal_theme.fish "$REPO_DIR/fish/" || true

# Wallpapers (main directory and Examples subdirectory)
cp -fv ~/Pictures/wallpapers/*.png "$REPO_DIR/wallpapers/" || true
cp -fv ~/Pictures/wallpapers/Examples/*.png "$REPO_DIR/wallpapers/" || true

# Main rotation script - sync BOTH ways
echo "==> Syncing main rotation script"
if [ -f "$MAIN_SCRIPT" ]; then
    # Copy current main script to repo
    cp -fv "$MAIN_SCRIPT" "$REPO_DIR/scripts/rotate-wallpaper.sh"
    echo "Copied main script to repo: $MAIN_SCRIPT -> $REPO_DIR/scripts/rotate-wallpaper.sh"
else
    echo "WARNING: Main script not found at $MAIN_SCRIPT"
fi

# Also check if there's an updated version in the repo to sync back
if [ -f "$REPO_DIR/scripts/rotate-wallpaper.sh" ]; then
    # Compare timestamps or let user decide
    if [ "$REPO_DIR/scripts/rotate-wallpaper.sh" -nt "$MAIN_SCRIPT" ] 2>/dev/null; then
        echo "==> Repo version is newer, updating main script"
        mkdir -p "$(dirname "$MAIN_SCRIPT")"
        cp -fv "$REPO_DIR/scripts/rotate-wallpaper.sh" "$MAIN_SCRIPT"
        chmod +x "$MAIN_SCRIPT"
        echo "Updated main script: $REPO_DIR/scripts/rotate-wallpaper.sh -> $MAIN_SCRIPT"
    fi
fi

# Systemd units - add syncing for these
cp -fv ~/.config/systemd/user/theme-sync.service "$REPO_DIR/systemd-user/" || true
cp -fv ~/.config/systemd/user/theme-sync.timer "$REPO_DIR/systemd-user/" || true

# Install script - if changed, sync it too
cp -fv ~/install.sh "$REPO_DIR/" || true  # Assuming install.sh is in ~, adjust if needed

echo "==> Git add + commit + push"
cd "$REPO_DIR"
git add .
git commit -m "Sync: $(date '+%Y-%m-%d %H:%M:%S')" || echo "Nothing to commit"
git push

echo "==> Done. Main script, configs, wallpapers, systemd units, install script, and README are synchronized."