#!/bin/bash
set -euo pipefail

THEMES_DIR="$HOME/.config/themes"
CURRENT_THEME_FILE="$HOME/.config/current_theme"

log() { echo "[$(date +'%H:%M:%S')] $*"; }

usage() {
    echo "Usage: switch-theme.sh [theme-name|list]"
    echo "  (no args)   Interactive rofi picker"
    echo "  list        List available themes"
    echo "  <theme>     Switch to theme"
    exit 0
}

# No args → rofi picker
if [ $# -eq 0 ]; then
    if ! command -v rofi &>/dev/null; then
        log "rofi not found, falling back to read"
        echo "Available themes:"
        ls -1 "$THEMES_DIR"
        echo -n "Theme: "
        read -r theme
    else
        theme=$(ls -1 "$THEMES_DIR" | rofi -dmenu -p "Switch Theme" -i)
    fi
    [ -z "$theme" ] && exit 0
    set -- "$theme"
fi

case "${1:-}" in
    -h|--help) usage ;;
    list)
        ls -1 "$THEMES_DIR"
        exit 0
        ;;
esac

theme="$1"
THEME_DIR="$THEMES_DIR/$theme"

if [ ! -d "$THEME_DIR" ]; then
    log "ERROR: Theme '$theme' not found in $THEMES_DIR"
    exit 1
fi

log "Switching to theme: $theme"

# 1. OXWM colors
cp "$THEME_DIR/oxwm-colors.lua" "$HOME/.config/oxwm/colors/custom.lua"
log "  oxwm colors  ✓"

# 2. Rofi theme
cp "$THEME_DIR/rofi.rasi" "$HOME/.config/rofi/theme.rasi"
log "  rofi theme   ✓"

# 3. Dunst
cp "$THEME_DIR/dunst.conf" "$HOME/.config/dunst/dunstrc"
pkill dunst 2>/dev/null || true
sleep 0.3
dunst &
log "  dunst        ✓"

# 4. Wezterm
cp "$THEME_DIR/wezterm.lua" "$HOME/.config/wezterm/theme.lua"
log "  wezterm      ✓"

# 5. Yazi flavor
if [ -f "$THEME_DIR/yazi-flavor" ]; then
    flavor=$(cat "$THEME_DIR/yazi-flavor")
    sed -i "s/dark = \".*\"/dark = \"$flavor\"/" "$HOME/.config/yazi/theme.toml"
    sed -i "s/light = \".*\"/light = \"$flavor\"/" "$HOME/.config/yazi/theme.toml"
    log "  yazi flavor  ✓ ($flavor)"
fi

# 6. GTK theme + xsettingsd
if [ -f "$THEME_DIR/gtk-theme-name" ]; then
    gtk_theme=$(cat "$THEME_DIR/gtk-theme-name")
    gtk_icons=$(cat "$THEME_DIR/gtk-icon-theme-name")

    sed -i "s/gtk-theme-name = \".*\"/gtk-theme-name = \"$gtk_theme\"/" "$HOME/.gtkrc-2.0"
    sed -i "s/gtk-icon-theme-name = \".*\"/gtk-icon-theme-name = \"$gtk_icons\"/" "$HOME/.gtkrc-2.0"

    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$HOME/.config/gtk-3.0/settings.ini"
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$gtk_icons/" "$HOME/.config/gtk-3.0/settings.ini"

    sed -i "s/gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$HOME/.config/gtk-4.0/settings.ini"
    sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$gtk_icons/" "$HOME/.config/gtk-4.0/settings.ini"

    sed -i "s/Net\/ThemeName \".*\"/Net\/ThemeName \"$gtk_theme\"/" "$HOME/.config/xsettingsd/xsettingsd.conf"
    sed -i "s/Net\/IconThemeName \".*\"/Net\/IconThemeName \"$gtk_icons\"/" "$HOME/.config/xsettingsd/xsettingsd.conf"

    pkill xsettingsd 2>/dev/null || true
    sleep 0.3
    xsettingsd &
    log "  gtk/xsettingsd ✓ ($gtk_theme)"
fi

# 7. Save current theme
echo "$theme" > "$CURRENT_THEME_FILE"
log "  saved        ✓"

# 8. Reload oxwm config (Mod+Shift+R)
sleep 0.5
xdotool key --clearmodifiers Super+Shift+R
log "  oxwm reload  ✓ (Mod+Shift+R)"

log "Done — switched to $theme"
