#!/bin/bash
#
# Theme Switcher for Niri Desktop
# Applies theme to: Ghostty, Walker, Waybar, SwayOSD, Niri, Zed, Starship
#

set -euo pipefail

THEME_DIR="$HOME/.config/themes"
THEME_NAME="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check theme exists
if [[ ! -d "$THEME_DIR/themes/$THEME_NAME" ]]; then
    error "Theme '$THEME_NAME' not found"
    echo "Available themes:"
    ls -1 "$THEME_DIR/themes" 2>/dev/null | sed 's/^/  /'
    exit 1
fi

info "Switching to theme: $THEME_NAME"

# Source theme colors
source "$THEME_DIR/themes/$THEME_NAME/colors.conf"

# Export all variables for envsubst
export name bg bg_light bg_lighter fg fg_dim accent border
export red green yellow blue magenta cyan cursor selection
export ghostty_theme
export palette_0 palette_1 palette_2 palette_3 palette_4 palette_5 palette_6 palette_7
export palette_8 palette_9 palette_10 palette_11 palette_12 palette_13 palette_14 palette_15

# ─────────────────────────────────────────────────────────────
# STARSHIP
# ─────────────────────────────────────────────────────────────
info "Applying Starship theme..."
# Only substitute ${accent} to avoid breaking starship's $variable syntax
sed "s/\${accent}/$accent/g" "$THEME_DIR/templates/starship.toml" > "$HOME/.config/starship.toml"
success "Starship"

# ─────────────────────────────────────────────────────────────
# WALLPAPER
# ─────────────────────────────────────────────────────────────
info "Setting wallpaper..."
WALLPAPER_DIR="$THEME_DIR/themes/$THEME_NAME/wallpapers"
if [[ -d "$WALLPAPER_DIR" ]] && [[ -n "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | sort | head -1)
    if [[ -n "$WALLPAPER" ]]; then
        qs -c noctalia-shell ipc call wallpaper set "$WALLPAPER" "HDMI-A-1"
        qs -c noctalia-shell ipc call wallpaper set "$WALLPAPER" "eDP-1"
        success "Wallpaper: $(basename "$WALLPAPER")"
    fi
else
    info "No wallpapers found for theme"
fi

# ─────────────────────────────────────────────────────────────
# SAVE CURRENT THEME
# ─────────────────────────────────────────────────────────────
echo "$THEME_NAME" > "$THEME_DIR/current"

echo ""
success "Theme switched to: $name"
echo ""
echo "Note: Open a new Ghostty window or press Ctrl+Shift+, to reload terminal theme"
