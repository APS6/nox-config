---
name: system-config
description: Configure CachyOS Niri desktop with Noctalia shell
license: MIT
compatibility: opencode
metadata:
  system: cachyos
  compositor: niri
  shell: fish
  desktop_shell: noctalia
---

# Niri Desktop Configuration Skill

**User**: aps  
**OS**: CachyOS (Arch-based)  
**Compositor**: Niri (scrolling tiling Wayland)  
**Desktop Shell**: Noctalia (quickshell-based)  

## Architecture Overview

Noctalia is a quickshell-based desktop shell that replaces multiple components:
- **Status Bar** - Built-in (replaces Waybar)
- **Notifications** - Built-in (replaces Mako/dunst)  
- **Lock Screen** - Built-in with PAM auth (replaces gtklock/swaylock)
- **OSD** - Built-in (replaces SwayOSD)
- **App Launcher** - Built-in with clipboard history
- **Control Center** - Built-in system menu
- **Wallpaper** - Built-in with transitions (replaces swww)
- **Theme System** - Auto-applies to 13 apps via templates + user templates

**Other tools**:
- **Launcher (fallback)**: Walker (only used for theme picker)
- **Terminals**: Ghostty (primary), Alacritty (floating)
- **Editor**: Zed
- **Browser**: Zen Browser + Brave
- **Shell**: Fish with Starship prompt
- **Clipboard**: cliphist + wl-clipboard

## Key Config Locations

| Component | Config Path |
|-----------|-------------|
| Niri | `~/.config/niri/` (modular: `config.kdl` + `cfg/*.kdl`) |
| Noctalia | `~/.config/noctalia/settings.json` |
| Noctalia Colors | `~/.config/noctalia/colors.json` |
| Noctalia Templates | `~/.config/noctalia/user-templates.toml` |
| Noctalia User Templates | `~/.config/noctalia/templates/` |
| Ghostty | `~/.config/ghostty/config` (generated) |
| Alacritty | `~/.config/alacritty/` |
| Walker | `~/.config/walker/config.toml` |
| Fish | `~/.config/fish/config.fish` |
| Starship | `~/.config/starship.toml` (auto-generated) |
| Themes | `~/.config/themes/` |
| GTK | `~/.config/gtk-3.0/` + `~/.config/gtk-4.0/` |
| Swayidle | `~/.config/swayidle/config` |

## Important: How to Make Changes

**Noctalia settings**: Edit `~/.config/noctalia/settings.json` (single 600+ line file)
- Keybinds, widgets, colors, behaviors all in one place
- Changes apply via IPC or restart Noctalia

**Niri keybinds**: Edit `~/.config/niri/cfg/keybinds.kdl` (not main config.kdl)

**Theme switching**: Use `~/.config/themes/theme-picker.sh` (GUI) or manually call Noctalia IPC

**Window rules**: Edit `~/.config/niri/cfg/rules.kdl`

## Noctalia Shell (quickshell-based)

### What Noctalia Provides
- **Status Bar** - Floating bar with widgets (replaces Waybar)
- **Notifications** - Built-in notification daemon (replaces Mako)
- **Lock Screen** - Integrated lock screen with PAM auth (replaces gtklock)
- **OSD** - Volume/brightness on-screen display (replaces SwayOSD)
- **App Launcher** - Built-in launcher with clipboard history
- **Control Center** - System menu (network, bluetooth, power, etc.)
- **Wallpaper** - Built-in wallpaper management (replaces swww)

### Noctalia Config Files

**Main Settings**: `~/.config/noctalia/settings.json`
- All UI configuration in one file (600+ lines)
- Bar widgets, keybinds, colors, behaviors all configured here

**Current Colors**: `~/.config/noctalia/colors.json`
- Material You style color scheme
- Auto-generated based on wallpaper/theme

### Noctalia Theming

Noctalia auto-generates themed configs for: ghostty, alacritty, walker, niri, zed, gtk3/4, btop, cava, zenBrowser, mangoHud, qt, foot, and KDE apps. See the `templates.activeTemplates` section in `settings.json`.

**User Templates**: Enable in Settings → Color Scheme → Templates → Advanced → User templates
- Templates defined in `~/.config/noctalia/user-templates.toml`
- Template files in `~/.config/noctalia/templates/`
- Auto-regenerate when theme changes
- Currently used for: **Starship** prompt

### Noctalia IPC Commands

```bash
# Lock screen
qs -c noctalia-shell --lock

# Launch app launcher
qs -c noctalia-shell --launcher

# Open control center
qs -c noctalia-shell --control-center

# Change wallpaper
qs -c noctalia-shell --set-wallpaper /path/to/wallpaper

# Set color scheme (triggers template regeneration)
qs -c noctalia-shell ipc call colorScheme set <ThemeName>
```

## User Templates System

**Config**: `~/.config/noctalia/user-templates.toml`

**Template syntax**: `{{colors.name.mode.format}}`
- Example: `{{colors.primary.default.hex}}`
- Colors: primary, secondary, tertiary, error, surface, on_surface, etc.
- Modes: default, dark, light
- Formats: hex, rgb, rgba, hsl, red, green, blue, etc.

**Starship template**: `~/.config/noctalia/templates/starship.toml`
- Uses `{{colors.primary.default.hex}}` for accent color
- Auto-generated at `~/.config/starship.toml` on theme change

## Niri Configuration

Modular config structure in `~/.config/niri/`:

```
niri/
├── config.kdl           # Main entry point
├── cfg/
│   ├── autostart.kdl    # Startup apps
│   ├── keybinds.kdl     # Keybindings
│   ├── display.kdl      # Monitor outputs
│   ├── input.kdl        # Keyboard/touchpad
│   ├── layout.kdl       # Layout settings
│   ├── rules.kdl        # Window rules
│   ├── misc.kdl         # Environment variables
│   ├── animation.kdl    # Animations
│   └── noctalia.kdl     # Noctalia-specific colors
```

### Startup Applications

Defined in `~/.config/niri/cfg/autostart.kdl`:
- polkit-kde-authentication-agent-1 (authentication dialogs)
- Noctalia shell (`qs -c noctalia-shell`)
- swayidle (auto-lock daemon)

### Keybinds

Keybinds are defined in `~/.config/niri/cfg/keybinds.kdl`. Common binds include terminal, browser, editor, lock screen, and launcher (MOD+Space for Walker theme picker). Check the file for current bindings.

## Theme System

### Structure

```
~/.config/themes/
├── themes/                    # Theme directories (just need wallpapers/)
│   └── <ThemeName>/
│       └── wallpapers/        # Theme wallpapers (png, jpg, jpeg)
├── theme-picker.sh           # Walker-based theme picker (sets scheme + wallpaper)
└── current                   # Active theme name
```

### How Themes Work

**Colors**: Noctalia generates the color scheme and stores in `~/.config/noctalia/colors.json`. All apps (including Starship via user templates) get themed automatically when you change the color scheme.

**Wallpapers**: Each theme only needs a `wallpapers/` directory with image files. The picker selects the first one alphabetically.

**Available Themes**: 12 themes available (Ayu, Catppuccin, Cherry Blossom, Dracula, Eldritch, Everforest, Gruvbox, Kanagawa, Nord, Osaka jade, Rose Pine, Tokyo Night)

### Using the Theme Picker

```bash
# GUI picker (MOD+Shift+T) - sets Noctalia scheme + wallpaper
~/.config/themes/theme-picker.sh

# Manual theme switch via CLI
qs -c noctalia-shell ipc call colorScheme set <ThemeName>
# Then manually set wallpaper if desired
```

### What Happens When You Switch Themes

1. **Noctalia** generates new color scheme and regenerates all themed configs (including Starship via user template)
2. **Picker** sets wallpaper from theme's wallpapers/ directory (if exists)
3. **Picker** saves theme name to `current` file

All apps update automatically - no manual template substitution needed.

## Authentication & PAM

### Screen Lock

Noctalia provides the lock screen with PAM authentication. Uses the "login" PAM service.

**Auto-lock**: `~/.config/swayidle/config`
```
timeout 120 'qs -c noctalia-shell --lock'
timeout 600 'niri msg action power-off-monitors'
before-sleep 'qs -c noctalia-shell --lock'
```

**Toggle script**: `~/.config/swayidle/toggle.sh` (MOD+Ctrl+I)

### Fingerprint Auth (fprintd)

**Important**: For Noctalia lock screen to use fingerprint, fprintd must be configured in `/etc/pam.d/system-auth`:

```
#%PAM-1.0

auth       required                    pam_faillock.so      preauth
-auth      [success=3 default=ignore]  /usr/lib/security/pam_fprintd.so
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so          try_first_pass nullok
auth       [default=die]               pam_faillock.so      authfail
auth       optional                    pam_permit.so
auth       required                    pam_env.so
auth       required                    pam_faillock.so      authsucc
...
```

**Note**: Use full path `/usr/lib/security/pam_fprintd.so` - Noctalia may not find it otherwise.

**Enroll fingerprints**: `fprintd-enroll`

### Polkit Agent

**Agent**: `/usr/lib/polkit-kde-authentication-agent-1`
- Started automatically with Niri
- Provides authentication dialogs for privileged operations

## Login Manager (greetd + tuigreet)

Uses greetd with tuigreet in a minimal sway session.

**Config files**:
- `/etc/greetd/config.toml` - Main greetd config
- `/etc/greetd/sway-config` - Sway session for greeter

Features: remembers last user/session, shows asterisks for password, displays time, launches niri-session.

## Clipboard

Uses **wl-clipboard** with **cliphist** for history. Clipboard watching is configured in Noctalia `settings.json` - look for clipboard-related settings in the `appLauncher` section.

## Common Tasks

### Change a keybinding

Edit `~/.config/niri/cfg/keybinds.kdl`

### Add a window rule

Edit `~/.config/niri/cfg/rules.kdl`. Example patterns:
```kdl
window-rule {
    match app-id=r#"^firefox$"#
    open-maximized true
}
```

### Adjust gaps or focus ring

Edit `~/.config/niri/cfg/layout.kdl`

### Reload after changes

- **Niri**: Changes auto-reload
- **Noctalia**: Changes apply immediately via IPC
- **Walker**: `pkill walker && walker --gapplication-service &`

### Add custom widget to Noctalia bar

Edit `~/.config/noctalia/settings.json` in the `bar.widgets.right` (or left/center) array. Use `CustomButton` widget type to add custom buttons with icons, click handlers, and dynamic text from shell commands.

### Create a new user template

1. Create template file in `~/.config/noctalia/templates/myapp.conf`
2. Add to `~/.config/noctalia/user-templates.toml`:
```toml
[templates.myapp]
input_path = "~/.config/noctalia/templates/myapp.conf"
output_path = "~/.config/myapp/theme.conf"
post_hook = "pkill -USR1 myapp"  # optional reload command
```
3. Use template syntax like `{{colors.primary.default.hex}}`
4. Trigger regeneration by changing theme

## Auto-Generated Files

These files are managed automatically - edit their sources instead:

| Generated File | Source/Manager |
|----------------|----------------|
| `ghostty/config` | Noctalia template in `settings.json` |
| `alacritty/themes/noctalia.toml` | Noctalia |
| `walker/themes/noctalia/style.css` | Noctalia |
| `gtk-3.0/noctalia.css` | Noctalia |
| `gtk-4.0/noctalia.css` | Noctalia |
| `starship.toml` | Noctalia user template |
| `niri/cfg/noctalia.kdl` | Noctalia |

## Git Repository

Dotfiles tracked at `github.com/APS6/nox-config`.

## User Preferences

- **Font**: JetBrains Mono Nerd Font
- **Location**: Haldwani, Uttarakhand (weather)
- **No emojis** unless requested
- **Prefers AI** to make config changes

---

## Maintenance Note

**Remember**: After making changes to any system components that are documented in this skill (themes, auth, keybinds, Noctalia config, etc.), update this skill file to reflect the current state. This ensures the AI has accurate information for future tasks.
