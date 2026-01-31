#!/bin/bash
#
# Theme Picker - Walker integration for theme switching
# Lists themes from directory names and sets wallpaper
#

THEME_DIR="$HOME/.config/themes"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }

# List themes from directory names
themes=$(find "$THEME_DIR/themes" -maxdepth 1 -type d -printf '%f\n' | sort | grep -v '^$')

# Show picker
selected=$(echo "$themes" | walker --dmenu --placeholder "Select Theme")

# Apply theme if selected
if [[ -n "$selected" ]]; then
    # Set Noctalia color scheme (this triggers template regeneration including starship)
    qs -c noctalia-shell ipc call colorScheme set "$selected"
    
    # Set wallpaper from theme directory
    info "Setting wallpaper..."
    WALLPAPER_DIR="$THEME_DIR/themes/$selected/wallpapers"
    if [[ -d "$WALLPAPER_DIR" ]]; then
        WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | sort | head -1)
        if [[ -n "$WALLPAPER" ]]; then
            qs -c noctalia-shell ipc call wallpaper set "$WALLPAPER" "HDMI-A-1" 2>/dev/null || true
            qs -c noctalia-shell ipc call wallpaper set "$WALLPAPER" "eDP-1" 2>/dev/null || true
            success "Wallpaper: $(basename "$WALLPAPER")"
        else
            info "No wallpapers found for theme"
        fi
    else
        info "No wallpapers directory for theme"
    fi
    
    # Save current theme
    echo "$selected" > "$THEME_DIR/current"
    
    success "Theme switched to: $selected"
fi
