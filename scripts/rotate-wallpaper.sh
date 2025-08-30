#!/bin/bash
# KDE Plasma wallpaper, Conky, Konsole, and Plasma color scheme synchronization script
# Time-based desktop and terminal theming for CachyOS

# Simple environment setup - use the same environment as when run manually
export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# If DBUS_SESSION_BUS_ADDRESS is not set, use the standard location
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    if [ -S "$XDG_RUNTIME_DIR/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi
fi

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONKY_CONFIG="$HOME/.config/conky/conky.conf"
KONSOLE_PROFILE_DIR="$HOME/.local/share/konsole"
PLASMA_COLOR_SCHEME_DIR="$HOME/.local/share/color-schemes"
LOCK_SCREEN_CONFIG="$HOME/.config/kscreenlockerrc"
KWRITECONFIG="/usr/bin/kwriteconfig6"

# Ensure directories exist
mkdir -p "$WALLPAPER_DIR" "$KONSOLE_PROFILE_DIR" "$PLASMA_COLOR_SCHEME_DIR" "$HOME/.config"

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
echo "$(date): Switching to $THEME theme (Wallpaper: $WALLPAPER, ColorScheme: $COLOR_SCHEME)" >> "$HOME/.local/share/wallpaper-sync.log"

# Check if files exist
if [ ! -f "$WALLPAPER" ]; then
    echo "Warning: Wallpaper $WALLPAPER not found" >> "$HOME/.local/share/wallpaper-sync.log"
    exit 1
fi

if [ ! -f "$PLASMA_COLOR_SCHEME_DIR/$COLOR_SCHEME.colors" ]; then
    echo "Warning: Plasma color scheme $COLOR_SCHEME.colors not found" >> "$HOME/.local/share/wallpaper-sync.log"
    exit 1
fi

# Update lock screen wallpaper
if command -v "$KWRITECONFIG" >/dev/null && [ -f "$WALLPAPER" ] && ! pgrep -x "kscreenlocker" > /dev/null; then
    "$KWRITECONFIG" --file "$LOCK_SCREEN_CONFIG" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALLPAPER" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Updated lock screen wallpaper: $WALLPAPER" >> "$HOME/.local/share/wallpaper-sync.log"
    fi
fi

# Apply wallpaper
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var desktops = desktops();
for (var i=0; i<desktops.length; i++) {
    var d = desktops[i];
    d.wallpaperPlugin = 'org.kde.image';
    d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
    d.writeConfig('Image','file://$WALLPAPER');
    d.writeConfig('FillMode', 2);
}
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Applied wallpaper: $WALLPAPER" >> "$HOME/.local/share/wallpaper-sync.log"
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
    echo "Created profile $PROFILE_FILE with ColorScheme=$COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"
else
    sed -i "s/ColorScheme=.*/ColorScheme=$COLOR_SCHEME/" "$PROFILE_FILE"
    echo "Updated profile $PROFILE_FILE with ColorScheme=$COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"
fi

# Update konsolerc
if grep -q "\\[DesktopEntry\\]" "$KONSOLERC" 2>/dev/null; then
    sed -i "/\\[DesktopEntry\\]/,/^\\[/ s/DefaultProfile=.*/DefaultProfile=TimeBased.profile/" "$KONSOLERC"
else
    echo -e "\n[DesktopEntry]\nDefaultProfile=TimeBased.profile" >> "$KONSOLERC"
fi

# Apply Plasma color scheme - the SIMPLE way
echo "Applying Plasma color scheme: $COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"

# Use the exact same command that works manually
PLASMA_OUTPUT=$(plasma-apply-colorscheme "$COLOR_SCHEME" 2>&1)
PLASMA_EXIT_CODE=$?

echo "plasma-apply-colorscheme output: $PLASMA_OUTPUT" >> "$HOME/.local/share/wallpaper-sync.log"
echo "plasma-apply-colorscheme exit code: $PLASMA_EXIT_CODE" >> "$HOME/.local/share/wallpaper-sync.log"

if [ $PLASMA_EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Applied Plasma color scheme: $COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"
    SCHEME_APPLIED=true
else
    echo "FAILED: Could not apply Plasma color scheme: $COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"
    SCHEME_APPLIED=false
    
    # Simple fallback: try once more after a short delay
    sleep 2
    echo "Retrying plasma-apply-colorscheme..." >> "$HOME/.local/share/wallpaper-sync.log"
    PLASMA_OUTPUT2=$(plasma-apply-colorscheme "$COLOR_SCHEME" 2>&1)
    PLASMA_EXIT_CODE2=$?
    echo "Retry output: $PLASMA_OUTPUT2" >> "$HOME/.local/share/wallpaper-sync.log"
    
    if [ $PLASMA_EXIT_CODE2 -eq 0 ]; then
        echo "SUCCESS on retry: Applied Plasma color scheme: $COLOR_SCHEME" >> "$HOME/.local/share/wallpaper-sync.log"
        SCHEME_APPLIED=true
    fi
fi

# Handle Conky theme update
if pgrep -x "conky" > /dev/null; then
    echo "Conky is running, sending reload signal..." >> "$HOME/.local/share/wallpaper-sync.log"
    
    # Try to reload Conky configuration without killing it
    pkill -SIGUSR1 conky 2>/dev/null
    
    # If that doesn't work, restart it
    if [ $? -ne 0 ]; then
        echo "Restarting Conky for theme change..." >> "$HOME/.local/share/wallpaper-sync.log"
        pkill -x conky
        sleep 1
        
        if [ -f "$CONKY_CONFIG" ]; then
            nohup conky -c "$CONKY_CONFIG" >/dev/null 2>&1 &
            sleep 2  # Give it time to start
            
            if pgrep -x "conky" > /dev/null; then
                echo "Conky restarted successfully with $THEME theme" >> "$HOME/.local/share/wallpaper-sync.log"
            else
                echo "ERROR: Conky failed to restart" >> "$HOME/.local/share/wallpaper-sync.log"
                # Try to start it again
                nohup conky -c "$CONKY_CONFIG" >/dev/null 2>&1 &
            fi
        else
            echo "Warning: Conky config not found at $CONKY_CONFIG" >> "$HOME/.local/share/wallpaper-sync.log"
        fi
    else
        echo "Conky configuration reloaded with $THEME theme" >> "$HOME/.local/share/wallpaper-sync.log"
    fi
else
    # Conky is not running, start it
    echo "Starting Conky with $THEME theme..." >> "$HOME/.local/share/wallpaper-sync.log"
    if [ -f "$CONKY_CONFIG" ]; then
        nohup conky -c "$CONKY_CONFIG" >/dev/null 2>&1 &
        sleep 2
        
        if pgrep -x "conky" > /dev/null; then
            echo "Conky started successfully with $THEME theme" >> "$HOME/.local/share/wallpaper-sync.log"
        else
            echo "ERROR: Failed to start Conky" >> "$HOME/.local/share/wallpaper-sync.log"
        fi
    else
        echo "Warning: Conky config not found at $CONKY_CONFIG" >> "$HOME/.local/share/wallpaper-sync.log"
    fi
fi

# ================= VSCode theme handling =================
# Supports Code (Microsoft) and VSCodium. Installs needed themes, writes settings.json safely.

# Paths (Microsoft VS Code + VSCodium)
VSCODE_SETTINGS_MS="$HOME/.config/Code/User/settings.json"
VSCODE_SETTINGS_OSS="$HOME/.config/VSCodium/User/settings.json"

# Pick settings file that exists (prefer MS Code). If none, default to MS path.
if [ -f "$VSCODE_SETTINGS_MS" ]; then
  VSCODE_SETTINGS="$VSCODE_SETTINGS_MS"
elif [ -f "$VSCODE_SETTINGS_OSS" ]; then
  VSCODE_SETTINGS="$VSCODE_SETTINGS_OSS"
else
  VSCODE_SETTINGS="$VSCODE_SETTINGS_MS"
  mkdir -p "$(dirname "$VSCODE_SETTINGS")"
  echo '{}' > "$VSCODE_SETTINGS"
fi

# Find CLI (Code or Codium)
VSCODE_CLI="$(command -v code || command -v codium || true)"

# Map your 4 times of day to EXACT theme labels
case "$COLOR_SCHEME" in
  Sunrise) VSCODE_THEME="Palenight (Mild Contrast)";;
  Noon)    VSCODE_THEME="Material Theme High Contrast";;
  Sunset)  VSCODE_THEME="Kimbie Dark";;
  Night)   VSCODE_THEME="Night Owl";;
esac

echo "VSCode target theme for $COLOR_SCHEME: $VSCODE_THEME" >> "$HOME/.local/share/wallpaper-sync.log"

# Ensure required extensions are present (no-ops if already installed)
# Palenight (whizkydee), Material Theme (equinusocio), Night Owl (sdras)
if [ -n "$VSCODE_CLI" ]; then
  "$VSCODE_CLI" --install-extension whizkydee.material-palenight-theme >/dev/null 2>&1 || true
  "$VSCODE_CLI" --install-extension equinusocio.vsc-material-theme >/dev/null 2>&1 || true
  "$VSCODE_CLI" --install-extension sdras.night-owl >/dev/null 2>&1 || true
fi

# Safely update settings.json (prefer jq if available)
if command -v jq >/dev/null 2>&1; then
  tmpfile="$(mktemp)"
  jq --arg theme "$VSCODE_THEME" '
      .["window.autoDetectColorScheme"]=false
      | .["workbench.colorTheme"]=$theme
    ' "$VSCODE_SETTINGS" > "$tmpfile" && mv "$tmpfile" "$VSCODE_SETTINGS"
else
  # jq not available – do careful in-place edit
  if grep -q '"workbench.colorTheme"' "$VSCODE_SETTINGS"; then
    sed -i "s/\"workbench.colorTheme\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"workbench.colorTheme\": \"$VSCODE_THEME\"/" "$VSCODE_SETTINGS"
  else
    # insert before final } with a leading comma if needed
    # ensure autoDetectColorScheme=false too
    if grep -q '"window.autoDetectColorScheme"' "$VSCODE_SETTINGS"; then
      sed -i "s/\"window.autoDetectColorScheme\"[[:space:]]*:[[:space:]]*[a-z]*/\"window.autoDetectColorScheme\": false/" "$VSCODE_SETTINGS"
    else
      sed -i "s/}$/,\n  \"window.autoDetectColorScheme\": false\n}/" "$VSCODE_SETTINGS"
    fi
    sed -i "s/}$/,\n  \"workbench.colorTheme\": \"$VSCODE_THEME\"\n}/" "$VSCODE_SETTINGS"
  fi
fi

# If VSCode is running, apply theme without bringing it to foreground
if pgrep -x "code" >/dev/null 2>&1 || pgrep -x "codium" >/dev/null 2>&1; then
  if [ -n "$VSCODE_CLI" ]; then
    echo "Applied VSCode theme: $VSCODE_THEME (no reload needed)" >> "$HOME/.local/share/wallpaper-sync.log"
    # Theme will apply automatically when VS Code checks settings
    # No need to reload window which would bring VS Code to foreground
  fi
fi
# =========================================================

# Smart Konsole restart - start new one first, then close old ones
if command -v konsole >/dev/null 2>&1 && pgrep -x konsole >/dev/null 2>&1; then
    echo "Restarting Konsole to apply new theme" >> "$HOME/.local/share/wallpaper-sync.log"
    
    # Get current Konsole PIDs before starting new one
    mapfile -t OLD_PIDS < <(pgrep -x konsole)
    
    # Start new Konsole with updated profile FIRST
    nohup konsole --profile TimeBased >/dev/null 2>&1 &
    NEW_PID=$!
    disown
    
    # Give the new instance time to fully start
    sleep 2
    
    # Now kill only the OLD instances (not the new one we just started)
    if ((${#OLD_PIDS[@]})); then
        echo "Closing old Konsole instances: ${OLD_PIDS[*]}" >> "$HOME/.local/share/wallpaper-sync.log"
        for pid in "${OLD_PIDS[@]}"; do
            # Make sure we don't kill the new process
            if [ "$pid" != "$NEW_PID" ]; then
                kill -TERM "$pid" 2>/dev/null || true
            fi
        done
    fi
    
    echo "Konsole restarted with new theme (PID: $NEW_PID)" >> "$HOME/.local/share/wallpaper-sync.log"
else
    echo "Konsole not running" >> "$HOME/.local/share/wallpaper-sync.log"
fi
# ================================================================

# Final status
echo "Theme sync completed: $THEME (Color scheme applied: ${SCHEME_APPLIED:-false})" >> "$HOME/.local/share/wallpaper-sync.log"
echo "---" >> "$HOME/.local/share/wallpaper-sync.log"