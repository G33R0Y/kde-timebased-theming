#!/bin/bash
# KDE Plasma wallpaper, Conky, Konsole, and Plasma color scheme synchronization script
# Time-based desktop and terminal theming for CachyOS
set -euo pipefail

# Simple environment setup - use the same environment as when run manually
export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# If DBUS_SESSION_BUS_ADDRESS is not set, use the standard location
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if [ -S "$XDG_RUNTIME_DIR/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi
fi

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONKY_CONFIG="$HOME/.config/conky/conky.conf"
KONSOLE_PROFILE_DIR="$HOME/.local/share/konsole"
PLASMA_COLOR_SCHEME_DIR="$HOME/.local/share/color-schemes"
LOCK_SCREEN_CONFIG="$HOME/.config/kscreenlockerrc"
KWRITECONFIG="$(command -v kwriteconfig6 || true)"
LOGFILE="$HOME/.local/share/wallpaper-sync.log"

# Ensure directories exist
mkdir -p "$WALLPAPER_DIR" "$KONSOLE_PROFILE_DIR" "$PLASMA_COLOR_SCHEME_DIR" "$HOME/.config" "$(dirname "$LOGFILE")"

# Get current time
HOUR=$(date +%H)
THEME=""
WALLPAPER=""
COLOR_SCHEME=""

# Determine wallpaper, theme, and color scheme based on time
if [ $HOUR -ge 6 ] && [ $HOUR -lt 12 ]; then
    WALLPAPER="$WALLPAPER_DIR/sunrise.png"
    THEME="sunrise"
    COLOR_SCHEME="Sunrise"
elif [ $HOUR -ge 12 ] && [ $HOUR -lt 18 ]; then
    WALLPAPER="$WALLPAPER_DIR/noon.png"
    THEME="noon"
    COLOR_SCHEME="Noon"
elif [ $HOUR -ge 18 ] && [ $HOUR -lt 24 ]; then
    WALLPAPER="$WALLPAPER_DIR/sunset.png"
    THEME="sunset"
    COLOR_SCHEME="Sunset"
else
    WALLPAPER="$WALLPAPER_DIR/night.png"
    THEME="night"
    COLOR_SCHEME="Night"
fi

# Log theme change
echo "$(date): Switching to $THEME theme (Wallpaper: $WALLPAPER, ColorScheme: $COLOR_SCHEME)" >> "$LOGFILE"

# Check wallpapers
if [ ! -f "$WALLPAPER" ]; then
    echo "Warning: Wallpaper $WALLPAPER not found" >> "$LOGFILE"
    # do not exit; continue so at least colors apply
fi

# Graceful fallback for missing Plasma color scheme files
FALLBACK="$COLOR_SCHEME"
if [ ! -f "$PLASMA_COLOR_SCHEME_DIR/$COLOR_SCHEME.colors" ]; then
    case "$COLOR_SCHEME" in
        Noon)    FALLBACK="BreezeLight" ;;
        Sunrise) FALLBACK="Breeze" ;;
        Sunset)  FALLBACK="BreezeLight" ;;
        Night)   FALLBACK="BreezeDark" ;;
    esac
    echo "Info: $COLOR_SCHEME.colors not found; falling back to $FALLBACK" >> "$LOGFILE"
fi

# Update lock screen wallpaper if possible and kscreenlocker isn't active
if [ -n "$KWRITECONFIG" ] && [ -f "$WALLPAPER" ] && ! pgrep -x "kscreenlocker" > /dev/null 2>&1; then
    "$KWRITECONFIG" --file "$LOCK_SCREEN_CONFIG" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALLPAPER" 2>/dev/null || true
    echo "Updated lock screen wallpaper: $WALLPAPER" >> "$LOGFILE"
fi

# Apply wallpaper (Plasma 6 script API)
if command -v qdbus >/dev/null 2>&1 || command -v qdbus6 >/dev/null 2>&1; then
    QDBUS_BIN="$(command -v qdbus || command -v qdbus6)"
    "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var allDesktops = desktops();
for (var i=0; i<allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = 'org.kde.image';
    d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
    d.writeConfig('Image','file://$WALLPAPER');
    d.writeConfig('FillMode', 2);
}
" >/dev/null 2>&1 && echo "Applied wallpaper: $WALLPAPER" >> "$LOGFILE"
fi

# Handle Konsole profile
PROFILE_FILE="$KONSOLE_PROFILE_DIR/TimeBased.profile"
KONSOLERC="$HOME/.config/konsolerc"

if [ ! -f "$PROFILE_FILE" ]; then
    cat > "$PROFILE_FILE" << EOF
[General]
Name=TimeBased
Parent=FALLBACK/

[Appearance]
ColorScheme=$COLOR_SCHEME
EOF
    echo "Created profile $PROFILE_FILE with ColorScheme=$COLOR_SCHEME" >> "$LOGFILE"
else
    sed -i "s/^ColorScheme=.*/ColorScheme=$COLOR_SCHEME/" "$PROFILE_FILE" || true
    echo "Updated profile $PROFILE_FILE with ColorScheme=$COLOR_SCHEME" >> "$LOGFILE"
fi

# Update konsolerc default profile
if [ -f "$KONSOLERC" ] && grep -q "\[DesktopEntry\]" "$KONSOLERC" 2>/dev/null; then
    sed -i "/\[DesktopEntry\]/,/^\[/ s/^DefaultProfile=.*/DefaultProfile=TimeBased.profile/" "$KONSOLERC"
else
    printf "\n[DesktopEntry]\nDefaultProfile=TimeBased.profile\n" >> "$KONSOLERC"
fi

# Apply Plasma color scheme (attempt scheme, else fallback)
APPLY_SCHEME="$COLOR_SCHEME"
if [ ! -f "$PLASMA_COLOR_SCHEME_DIR/$COLOR_SCHEME.colors" ]; then
    APPLY_SCHEME="$FALLBACK"
fi

echo "Applying Plasma color scheme: $APPLY_SCHEME" >> "$LOGFILE"
PLASMA_OUTPUT=$(plasma-apply-colorscheme "$APPLY_SCHEME" 2>&1 || true)
PLASMA_EXIT_CODE=$?
echo "plasma-apply-colorscheme output: $PLASMA_OUTPUT" >> "$LOGFILE"
echo "plasma-apply-colorscheme exit code: $PLASMA_EXIT_CODE" >> "$LOGFILE"

if [ $PLASMA_EXIT_CODE -ne 0 ]; then
    sleep 2
    echo "Retrying plasma-apply-colorscheme..." >> "$LOGFILE"
    PLASMA_OUTPUT2=$(plasma-apply-colorscheme "$APPLY_SCHEME" 2>&1 || true)
    PLASMA_EXIT_CODE2=$?
    echo "Retry output: $PLASMA_OUTPUT2" >> "$LOGFILE"
fi

# Handle Conky theme update
if pgrep -x "conky" > /dev/null 2>&1; then
    echo "Conky is running, sending reload signal..." >> "$LOGFILE"
    pkill -SIGUSR1 conky 2>/dev/null || true
else
    echo "Starting Conky..." >> "$LOGFILE"
    if [ -f "$CONKY_CONFIG" ]; then
        nohup conky -c "$CONKY_CONFIG" >/dev/null 2>&1 &
    else
        echo "Warning: Conky config not found at $CONKY_CONFIG" >> "$LOGFILE"
    fi
fi

echo "Theme sync completed: $THEME" >> "$LOGFILE"
echo "---" >> "$LOGFILE"
