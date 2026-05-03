#!/bin/bash
set -euo pipefail

THEMES_DIR="$HOME/.config/themes"
CURRENT_THEME_FILE="$HOME/.config/current_theme"
RENDER_SCRIPT="$THEMES_DIR/render-theme.py"

log() { echo "[$(date +'%H:%M:%S')] $*"; }

usage() {
    echo "Usage: switch-theme.sh [theme-name|list]"
    echo "  (no args)   Interactive rofi picker"
    echo "  list        List available themes"
    echo "  <theme>     Switch to theme"
    exit 0
}

list_themes() {
    for d in "$THEMES_DIR"/*/; do
        name=$(basename "$d")
        [ "$name" = "templates" ] && continue
        echo "$name"
    done
}

theme=""
if [ $# -eq 0 ]; then
    if command -v rofi &>/dev/null; then
        theme=$(list_themes | rofi -dmenu -p "Switch Theme" -i)
    else
        echo "Available themes:"
        list_themes
        echo -n "Theme: "
        read -r theme
    fi
    [ -z "$theme" ] && exit 0
elif [ "$1" = "list" ]; then
    list_themes
    exit 0
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
else
    theme="$1"
fi

if [ ! -d "$THEMES_DIR/$theme" ]; then
    log "ERROR: Theme '$theme' not found"
    exit 1
fi

log "Switching to theme: $theme"

# Render all templates via Python
python3 "$RENDER_SCRIPT" "$theme"

# Restart dunst
pkill dunst 2>/dev/null || true
sleep 0.3
dunst &
log "  dunst restart ✓"

# Restart xsettingsd
pkill xsettingsd 2>/dev/null || true
sleep 0.3
xsettingsd &
log "  xsettingsd  ✓"

# Save current theme
echo "$theme" > "$CURRENT_THEME_FILE"

# Reload oxwm (Mod+Shift+R)
sleep 0.3
xdotool key --clearmodifiers Super+Shift+R
log "  oxwm reload ✓"

log "Done — switched to $theme"
