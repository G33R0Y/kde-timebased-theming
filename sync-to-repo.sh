#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/Downloads/kde-timebased-theming"

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

# Wallpapers
cp -fv ~/Pictures/wallpapers/*.png "$REPO_DIR/wallpapers/" || true

echo "==> Git add + commit + push"
cd "$REPO_DIR"
git add .
git commit -m "Sync: $(date '+%Y-%m-%d %H:%M:%S')" || echo "Nothing to commit"
git push

echo "==> Done."