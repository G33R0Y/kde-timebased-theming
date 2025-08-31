source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx PATH $PATH /usr/bin

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
fish_add_path /home/geeroy/Android/Sdk/platform-tools
fish_add_path ~/flutter/bin
fish_add_path ~/Android/Sdk/cmdline-tools/latest/bin
fish_add_path ~/Android/Sdk/platform-tools
set -x ANDROID_HOME ~/Android/Sdk
set -x JAVA_HOME /usr/lib/jvm/java-21-openjdk
if status is-interactive
    set_terminal_theme
end
