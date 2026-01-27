#!/bin/bash
#
# Theme Picker - Walker integration for theme switching
#

THEME_DIR="$HOME/.config/themes/themes"

# List themes with their display names
themes=""
for dir in "$THEME_DIR"/*/; do
    if [[ -d "$dir" ]]; then
        theme_name=$(basename "$dir")
        if [[ -f "$dir/colors.conf" ]]; then
            source "$dir/colors.conf"
            themes+="${theme_name}\n"
        fi
    fi
done

# Show picker
selected=$(echo -e "$themes" | walker --dmenu --placeholder "Select Theme")

# Apply theme if selected
if [[ -n "$selected" ]]; then
    qs -c noctalia-shell ipc call colorScheme set "$selected"
    ~/.config/themes/theme-switch.sh "$selected"
fi
