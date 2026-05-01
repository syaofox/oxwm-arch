#!/bin/bash

WALLPAPER_DIR="$HOME/.config/walls"
WALLPAPER_CONF="$HOME/.config/wallpaper.conf"

notify() { notify-send "switch-wallpaper" "$1"; }

set_wallpaper() {
    local wallpaper="$1"
    [[ ! -f "$wallpaper" ]] && { notify "File not found: $wallpaper"; return 1; }
    if xwallpaper --zoom "$wallpaper"; then
        echo "$wallpaper" > "$WALLPAPER_CONF"
    else
        notify "Failed to set wallpaper"
        return 1
    fi
}

[[ -d "$WALLPAPER_DIR" ]] || { notify "Directory not found: $WALLPAPER_DIR"; exit 1; }

mapfile -t wallpapers < <(
    find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | sort
)

(( ${#wallpapers[@]} )) || { notify "No wallpapers found"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PICKER="$SCRIPT_DIR/wallpaper-picker.py"

if [[ -x "$PICKER" ]]; then
    exec "$PICKER"
fi



[[ -z "$selected" ]] && exit 1

set_wallpaper "$selected"
