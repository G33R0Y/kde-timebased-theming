function set_terminal_theme
    set hour (date +%H)
    set profile_path ~/.local/share/konsole/TimeBased.profile
    set border_color
    set kwin_titlebar_color
    set color_scheme
    set aurorae_theme

    # Determine theme based on hour
    if test $hour -ge 6 -a $hour -lt 12
        # Sunrise
        set border_color "255,179,102" # #FFB366
        set kwin_titlebar_color "0xFFB366" # Warm golden
        set color_scheme "Sunrise"
        set aurorae_theme "kwin4_decoration_qml_plastik_sunrise"
    else if test $hour -ge 12 -a $hour -lt 18
        # Noon
        set border_color "74,158,255" # #4A9EFF
        set kwin_titlebar_color "0x4A9EFF" # Bright blue
        set color_scheme "Noon"
        set aurorae_theme "kwin4_decoration_qml_plastik_noon"
    else if test $hour -ge 18 -a $hour -lt 24
        # Sunset
        set border_color "255,107,71" # #FF6B47
        set kwin_titlebar_color "0xFF6B47" # Warm orange
        set color_scheme "Sunset"
        set aurorae_theme "kwin4_decoration_qml_plastik_sunset"
    else
        # Night
        set border_color "107,140,255" # #6B8CFF
        set kwin_titlebar_color "0x6B8CFF" # Moonlight blue
        set color_scheme "Night"
        set aurorae_theme "kwin4_decoration_qml_plastik_night"
    end

    # Update Konsole profile
    if test -f $profile_path
        sed -i "s/BorderColor=.*/BorderColor=$border_color/" $profile_path
        sed -i "s/ColorScheme=.*/ColorScheme=$color_scheme/" $profile_path
    else
        mkdir -p ~/.local/share/konsole
        echo "[Appearance]" > $profile_path
        echo "BorderColor=$border_color" >> $profile_path
        echo "ColorScheme=$color_scheme" >> $profile_path
        echo "[General]" >> $profile_path
        echo "Name=TimeBased" >> $profile_path
        echo "Parent=FALLBACK/" >> $profile_path
    end

    # Update KWin title bar (menu bar) color
    if type -q kwriteconfig6
        # Try Breeze theme first to ensure color changes apply
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ActiveTitleBar $kwin_titlebar_color
        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key InactiveTitleBar $kwin_titlebar_color
        qdbus org.kde.KWin /KWin reconfigure
        echo "Applied $kwin_titlebar_color to KWin title bar (menu bar) with Breeze theme."
    else
        echo "kwriteconfig6 not found. Install plasma-desktop or kconfig to update KWin title bar colors."
    end

    # Apply Konsole profile
    if type -q qdbus
        if pgrep -x konsole > /dev/null
            set konsole_pid (pgrep -x konsole | head -n 1)
            set konsole_service "org.kde.konsole-$konsole_pid"
            set session (qdbus $konsole_service 2>/dev/null | grep -o '/Sessions/[0-9]*' | head -n 1)
            if test -n "$session"
                qdbus $konsole_service $session org.kde.konsole.Session.setProfile TimeBased
                echo "Applied TimeBased profile with $color_scheme theme to $session."
            else
                echo "No Konsole sessions found for $konsole_service. Profile updated but not applied."
                echo "Try manually setting the profile in Konsole: Edit Profile > TimeBased."
            end
        else
            echo "Konsole is not running. Profile updated but not applied."
        end
    else
        echo "qdbus not installed. Please install qt6-base to apply profile changes dynamically."
    end
end