#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/Downloads/kde-timebased-theming"
MAIN_SCRIPT="$HOME/.local/bin/rotate-wallpaper.sh"
LOG_FILE="$HOME/.local/share/sync-to-repo.log"
INSTALL_SCRIPT="$REPO_DIR/install.sh"  # Install script is already in repo

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

echo "==> Syncing configs into $REPO_DIR [$(date)]" | tee -a "$LOG_FILE"

# Validate REPO_DIR is a Git repository
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "ERROR: $REPO_DIR is not a valid Git repository" | tee -a "$LOG_FILE"
    exit 1
fi

# Ensure Git remote is configured
if ! git -C "$REPO_DIR" remote get-url origin >/dev/null 2>&1; then
    echo "ERROR: No remote 'origin' configured in $REPO_DIR. Please set up with 'git remote add origin <url>'" | tee -a "$LOG_FILE"
    exit 1
fi

# Plasma color schemes
echo "Copying Plasma color schemes..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/plasma-color-schemes"
cp -fv ~/.local/share/color-schemes/*.colors "$REPO_DIR/plasma-color-schemes/" 2>/dev/null || echo "No Plasma color schemes found" | tee -a "$LOG_FILE"

# Konsole
echo "Copying Konsole configs..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/konsole/colorschemes"
cp -fv ~/.local/share/konsole/*.colorscheme "$REPO_DIR/konsole/colorschemes/" 2>/dev/null || echo "No Konsole colorschemes found" | tee -a "$LOG_FILE"
cp -fv ~/.local/share/konsole/TimeBased.profile "$REPO_DIR/konsole/" 2>/dev/null || echo "No Konsole TimeBased.profile found" | tee -a "$LOG_FILE"

# Check for stray Konsole colorschemes (e.g., Sunrise copy.colorscheme)
if [ -f "$REPO_DIR/konsole/colorschemes/Sunrise copy.colorscheme" ]; then
    echo "WARNING: Found 'Sunrise copy.colorscheme' in $REPO_DIR/konsole/colorschemes. Consider removing if not needed." | tee -a "$LOG_FILE"
fi

# Conky
echo "Copying Conky configs..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/conky"
cp -fv ~/.config/conky/conky.conf "$REPO_DIR/conky/" 2>/dev/null || echo "No Conky config found" | tee -a "$LOG_FILE"
cp -fv ~/.config/conky/theme_colors.lua "$REPO_DIR/conky/" 2>/dev/null || echo "No Conky theme_colors.lua found" | tee -a "$LOG_FILE"

# Fish
echo "Copying Fish configs..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/fish"
cp -fv ~/.config/fish/config.fish "$REPO_DIR/fish/" 2>/dev/null || echo "No Fish config.fish found" | tee -a "$LOG_FILE"
cp -fv ~/.config/fish/functions/set_terminal_theme.fish "$REPO_DIR/fish/" 2>/dev/null || echo "No Fish set_terminal_theme.fish found" | tee -a "$LOG_FILE"

# Wallpapers
echo "Copying wallpapers..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/wallpapers"
cp -fv ~/Pictures/wallpapers/*.png "$REPO_DIR/wallpapers/" 2>/dev/null || echo "No wallpapers found in ~/Pictures/wallpapers" | tee -a "$LOG_FILE"
cp -fv ~/Pictures/wallpapers/Examples/*.png "$REPO_DIR/wallpapers/" 2>/dev/null || echo "No wallpapers found in ~/Pictures/wallpapers/Examples" | tee -a "$LOG_FILE"

# Lockscreen videos
echo "Copying lockscreen videos..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/lockscreen"
cp -fv ~/Videos/lockscreen/*.mp4 "$REPO_DIR/lockscreen/" 2>/dev/null || echo "No lockscreen videos found in ~/Videos/lockscreen" | tee -a "$LOG_FILE"

# Copy the kscreenlockerrc (lock-screen config) so the repo tracks the plugin settings
echo "Copying lockscreen config (kscreenlockerrc)..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/lockscreen"
if [ -f "$HOME/.config/kscreenlockerrc" ]; then
    cp -fv "$HOME/.config/kscreenlockerrc" "$REPO_DIR/lockscreen/kscreenlockerrc" | tee -a "$LOG_FILE"
else
    echo "No ~/.config/kscreenlockerrc found; skipping." | tee -a "$LOG_FILE"
fi

# Main rotation script - sync BOTH ways
echo "==> Syncing main rotation script" | tee -a "$LOG_FILE"
if [ -f "$MAIN_SCRIPT" ]; then
    # Compute checksums for comparison
    local_checksum=$(sha256sum "$MAIN_SCRIPT" 2>/dev/null | awk '{print $1}' || echo "none")
    repo_checksum=$(sha256sum "$REPO_DIR/scripts/rotate-wallpaper.sh" 2>/dev/null | awk '{print $1}' || echo "none")
    
    if [ "$local_checksum" != "$repo_checksum" ]; then
        mkdir -p "$REPO_DIR/scripts"
        cp -fv "$MAIN_SCRIPT" "$REPO_DIR/scripts/rotate-wallpaper.sh" | tee -a "$LOG_FILE"
        echo "Copied main script to repo: $MAIN_SCRIPT -> $REPO_DIR/scripts/rotate-wallpaper.sh" | tee -a "$LOG_FILE"
    else
        echo "Main script unchanged, no copy needed" | tee -a "$LOG_FILE"
    fi
else
    echo "WARNING: Main script not found at $MAIN_SCRIPT" | tee -a "$LOG_FILE"
fi

# Check if there's an updated version in the repo to sync back
if [ -f "$REPO_DIR/scripts/rotate-wallpaper.sh" ]; then
    local_checksum=$(sha256sum "$MAIN_SCRIPT" 2>/dev/null | awk '{print $1}' || echo "none")
    repo_checksum=$(sha256sum "$REPO_DIR/scripts/rotate-wallpaper.sh" 2>/dev/null | awk '{print $1}' || echo "none")
    
    if [ "$local_checksum" != "$repo_checksum" ] && [ "$repo_checksum" != "none" ]; then
        echo "==> Repo version differs, updating main script" | tee -a "$LOG_FILE"
        mkdir -p "$(dirname "$MAIN_SCRIPT")"
        cp -fv "$REPO_DIR/scripts/rotate-wallpaper.sh" "$MAIN_SCRIPT" | tee -a "$LOG_FILE"
        chmod +x "$MAIN_SCRIPT"
        echo "Updated main script: $REPO_DIR/scripts/rotate-wallpaper.sh -> $MAIN_SCRIPT" | tee -a "$LOG_FILE"
    fi
fi

# Systemd units
echo "Copying systemd units..." | tee -a "$LOG_FILE"
mkdir -p "$REPO_DIR/systemd-user"
cp -fv ~/.config/systemd/user/theme-sync.service "$REPO_DIR/systemd-user/" 2>/dev/null || echo "No theme-sync.service found" | tee -a "$LOG_FILE"
cp -fv ~/.config/systemd/user/theme-sync.timer "$REPO_DIR/systemd-user/" 2>/dev/null || echo "No theme-sync.timer found" | tee -a "$LOG_FILE"

# Install script - skip copy since it's already in REPO_DIR
echo "Checking install script..." | tee -a "$LOG_FILE"
if [ -f "$INSTALL_SCRIPT" ]; then
    echo "Install script already in repo at $INSTALL_SCRIPT, no copy needed" | tee -a "$LOG_FILE"
else
    echo "WARNING: Install script not found at $INSTALL_SCRIPT" | tee -a "$LOG_FILE"
fi

# Check for stray files
echo "Checking for unexpected files..." | tee -a "$LOG_FILE"
if [ -f "$REPO_DIR/sync-to-repo copy.sh" ]; then
    echo "WARNING: Found 'sync-to-repo copy.sh' in $REPO_DIR. Consider removing if not needed." | tee -a "$LOG_FILE"
fi

# Git operations
echo "==> Git add + commit + push [$(date)]" | tee -a "$LOG_FILE"
cd "$REPO_DIR"

# Stage changes (including new or removed files)
git add -A >> "$LOG_FILE" 2>&1

# Get staged changed files
CHANGED_FILES=$(git diff --name-only --staged || true)

if [ -n "$CHANGED_FILES" ]; then
    echo "Changed files staged for commit:" | tee -a "$LOG_FILE"
    echo "$CHANGED_FILES" | tee -a "$LOG_FILE"
    git commit -m "Sync: $(date '+%Y-%m-%d %H:%M:%S') - Updated configs: $(echo "$CHANGED_FILES" | tr '\n' ', ' | sed 's/, $//')" >> "$LOG_FILE" 2>&1 || {
        echo "ERROR: Git commit failed. See $LOG_FILE for details." | tee -a "$LOG_FILE"
        exit 1
    }
else
    echo "Nothing to commit" | tee -a "$LOG_FILE"
fi

# Push with error handling
if ! git push >> "$LOG_FILE" 2>&1; then
    echo "ERROR: Failed to push to remote. Check GitHub credentials (SSH key or PAT) and network." | tee -a "$LOG_FILE"
    echo "Run 'git -C $REPO_DIR push' manually to diagnose." | tee -a "$LOG_FILE"
    echo "Note: If using an SSH key with a passphrase, automation (e.g., cron) requires ssh-agent or a key without a passphrase." | tee -a "$LOG_FILE"
    exit 1
else
    echo "Git push successful" | tee -a "$LOG_FILE"
fi

echo "==> Done. All configs, wallpapers, lockscreen videos, systemd units, and scripts are synchronized." | tee -a "$LOG_FILE"
echo "---" >> "$LOG_FILE"
