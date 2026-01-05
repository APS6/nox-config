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

# Show usage
if [[ -z "$THEME_NAME" ]]; then
    echo "Usage: theme-switch <theme-name>"
    echo ""
    echo "Available themes:"
    ls -1 "$THEME_DIR/themes" 2>/dev/null | sed 's/^/  /'
    exit 1
fi

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
# GHOSTTY
# ─────────────────────────────────────────────────────────────
info "Applying Ghostty theme..."

if [[ -n "${ghostty_theme:-}" ]]; then
    ghostty_colors="theme = $ghostty_theme"
else
    ghostty_colors="background = $bg
foreground = $fg
cursor-color = $cursor
selection-background = $selection
selection-foreground = $fg

palette = 0=${palette_0:-$bg_lighter}
palette = 1=${palette_1:-$red}
palette = 2=${palette_2:-$green}
palette = 3=${palette_3:-$yellow}
palette = 4=${palette_4:-$blue}
palette = 5=${palette_5:-$magenta}
palette = 6=${palette_6:-$cyan}
palette = 7=${palette_7:-$fg}
palette = 8=${palette_8:-$fg_dim}
palette = 9=${palette_9:-$red}
palette = 10=${palette_10:-$green}
palette = 11=${palette_11:-$yellow}
palette = 12=${palette_12:-$blue}
palette = 13=${palette_13:-$magenta}
palette = 14=${palette_14:-$cyan}
palette = 15=${palette_15:-$fg}"
fi
export ghostty_colors

envsubst < "$THEME_DIR/templates/ghostty.conf" > "$HOME/.config/ghostty/config"
success "Ghostty"

# ─────────────────────────────────────────────────────────────
# WALKER
# ─────────────────────────────────────────────────────────────
info "Applying Walker theme..."
mkdir -p "$HOME/.config/walker/themes/default"
envsubst < "$THEME_DIR/templates/walker.css" > "$HOME/.config/walker/themes/default/style.css"
success "Walker"

# ─────────────────────────────────────────────────────────────
# WAYBAR
# ─────────────────────────────────────────────────────────────
info "Applying Waybar theme..."
envsubst < "$THEME_DIR/templates/waybar.css" > "$HOME/.config/waybar/style.css"
success "Waybar"

# ─────────────────────────────────────────────────────────────
# SWAYOSD
# ─────────────────────────────────────────────────────────────
info "Applying SwayOSD theme..."
mkdir -p "$HOME/.config/swayosd"
envsubst < "$THEME_DIR/templates/swayosd.css" > "$HOME/.config/swayosd/style.css"
success "SwayOSD"

# ─────────────────────────────────────────────────────────────
# MAKO
# ─────────────────────────────────────────────────────────────
info "Applying Mako theme..."
mkdir -p "$HOME/.config/mako"
envsubst < "$THEME_DIR/templates/mako.conf" > "$HOME/.config/mako/config"
success "Mako"

# ─────────────────────────────────────────────────────────────
# STARSHIP
# ─────────────────────────────────────────────────────────────
info "Applying Starship theme..."
# Only substitute ${accent} to avoid breaking starship's $variable syntax
sed "s/\${accent}/$accent/g" "$THEME_DIR/templates/starship.toml" > "$HOME/.config/starship.toml"
success "Starship"

# ─────────────────────────────────────────────────────────────
# BTOP
# ─────────────────────────────────────────────────────────────
info "Applying btop theme..."
mkdir -p "$HOME/.config/btop/themes"
if [[ -f "$THEME_DIR/themes/$THEME_NAME/btop.theme" ]]; then
    cp "$THEME_DIR/themes/$THEME_NAME/btop.theme" "$HOME/.config/btop/themes/current.theme"
    # Update btop.conf to use the theme
    if [[ -f "$HOME/.config/btop/btop.conf" ]]; then
        sed -i 's|^color_theme = .*|color_theme = "current"|' "$HOME/.config/btop/btop.conf"
    fi
    success "btop"
else
    info "No btop theme for $THEME_NAME"
fi

# ─────────────────────────────────────────────────────────────
# GTKLOCK
# ─────────────────────────────────────────────────────────────
info "Applying gtklock theme..."
mkdir -p "$HOME/.config/gtklock"
envsubst < "$THEME_DIR/templates/gtklock.css" > "$HOME/.config/gtklock/style.css"

# Update gtklock config to use current wallpaper
WALLPAPER_DIR="$THEME_DIR/themes/$THEME_NAME/wallpapers"
if [[ -d "$WALLPAPER_DIR" ]] && [[ -n "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]]; then
    LOCK_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | sort | head -1)
    if [[ -n "$LOCK_WALLPAPER" ]] && [[ -f "$HOME/.config/gtklock/config.ini" ]]; then
        sed -i "s|^background=.*|background=$LOCK_WALLPAPER|" "$HOME/.config/gtklock/config.ini"
    fi
fi
success "gtklock"

# ─────────────────────────────────────────────────────────────
# NIRI (focus ring colors + overview backdrop)
# ─────────────────────────────────────────────────────────────
info "Applying Niri theme..."
sed -i "s/active-color \"#[a-fA-F0-9]\{6\}\"/active-color \"$accent\"/" "$HOME/.config/niri/config.kdl"
sed -i "s/inactive-color \"#[a-fA-F0-9]\{6\}\"/inactive-color \"$bg_lighter\"/" "$HOME/.config/niri/config.kdl"
sed -i "s/backdrop-color \"#[a-fA-F0-9]\{6\}\"/backdrop-color \"$bg\"/" "$HOME/.config/niri/config.kdl"
success "Niri"

# ─────────────────────────────────────────────────────────────
# ZED
# ─────────────────────────────────────────────────────────────
info "Applying Zed theme..."
mkdir -p "$HOME/.config/zed/themes"

# Copy theme file
if [[ -f "$THEME_DIR/themes/$THEME_NAME/zed.json" ]]; then
    cp "$THEME_DIR/themes/$THEME_NAME/zed.json" "$HOME/.config/zed/themes/"
fi

# Update settings.json
ZED_SETTINGS="$HOME/.config/zed/settings.json"
if [[ -f "$ZED_SETTINGS" ]]; then
    # Update theme in settings
    if grep -q '"theme"' "$ZED_SETTINGS"; then
        # Handle both string and object theme formats
        tmp=$(mktemp)
        awk -v theme="$name" '
        BEGIN { in_theme_obj = 0; brace_count = 0 }
        /"theme"[[:space:]]*:[[:space:]]*\{/ {
            in_theme_obj = 1
            brace_count = 1
            gsub(/"theme"[[:space:]]*:[[:space:]]*\{.*/, "\"theme\": \"" theme "\",")
            print
            next
        }
        /"theme"[[:space:]]*:[[:space:]]*"[^"]*"/ {
            gsub(/"theme"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"theme\": \"" theme "\"")
            print
            next
        }
        in_theme_obj == 1 {
            brace_count += gsub(/\{/, "{")
            brace_count -= gsub(/\}/, "}")
            if (brace_count <= 0) in_theme_obj = 0
            next
        }
        { print }
        ' "$ZED_SETTINGS" > "$tmp"
        mv "$tmp" "$ZED_SETTINGS"
    else
        # Add theme before last closing brace
        sed -i '$s/}/,\n  "theme": "'"$name"'"\n}/' "$ZED_SETTINGS"
    fi
else
    echo '{ "theme": "'"$name"'" }' > "$ZED_SETTINGS"
fi
success "Zed"

# ─────────────────────────────────────────────────────────────
# WALLPAPER
# ─────────────────────────────────────────────────────────────
info "Setting wallpaper..."
WALLPAPER_DIR="$THEME_DIR/themes/$THEME_NAME/wallpapers"
if [[ -d "$WALLPAPER_DIR" ]] && [[ -n "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | sort | head -1)
    if [[ -n "$WALLPAPER" ]]; then
        # Create/update symlink for startup
        ln -sf "$WALLPAPER" "$THEME_DIR/wallpaper"
        # Set wallpaper now
        swww img "$WALLPAPER" --transition-type fade --transition-pos 0.9,0.1 --transition-duration 0.8 2>/dev/null || \
        swww img "$WALLPAPER" 2>/dev/null || \
        info "swww not running, skipping wallpaper"
        success "Wallpaper: $(basename "$WALLPAPER")"
    fi
else
    info "No wallpapers found for theme"
fi

# ─────────────────────────────────────────────────────────────
# RELOAD SERVICES
# ─────────────────────────────────────────────────────────────
info "Reloading services..."

# Waybar
pkill -x waybar 2>/dev/null || true
sleep 0.2
waybar &>/dev/null &
disown
success "Waybar reloaded"

# Walker
pkill -x walker 2>/dev/null || true
sleep 0.2
walker --gapplication-service &>/dev/null &
disown
success "Walker reloaded"

# SwayOSD
pkill -x swayosd-server 2>/dev/null || true
sleep 0.2
swayosd-server &>/dev/null &
disown
success "SwayOSD reloaded"

# Mako
makoctl reload 2>/dev/null && success "Mako reloaded" || info "Mako not running"

# ─────────────────────────────────────────────────────────────
# SAVE CURRENT THEME
# ─────────────────────────────────────────────────────────────
echo "$THEME_NAME" > "$THEME_DIR/current"

echo ""
success "Theme switched to: $name"
echo ""
echo "Note: Open a new Ghostty window or press Ctrl+Shift+, to reload terminal theme"
