#!/bin/bash
log() { echo "[$(date +'%H:%M:%S')] $*"; }
err() { echo "[$(date +'%H:%M:%S')] ERROR: $*" >&2; }

LOGDIR="$HOME/.local/share/oxwm"
LOGFILE="$LOGDIR/oxwm.log"
mkdir -p "$LOGDIR"
[ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE")" -gt 1048576 ] && mv "$LOGFILE" "$LOGFILE.old"
exec > >(tee -a "$LOGFILE") 2>&1

log "=== oxwm session starting (PID: $$) ==="

command -v dbus-update-activation-environment >/dev/null &&
    dbus-update-activation-environment --systemd --all

# 5. 启动 GNOME 认证代理 (替换掉 lxqt)
if [ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fi



# nm-applet &
# blueman-applet &
# pasystray &

xsettingsd &
dunst &
clipster -d &

fcitx5 -d &
# picom -b &

if command -v xwallpaper >/dev/null; then
    WALLPAPER_CONF="$HOME/.config/wallpaper.conf"
    if [[ -f "$WALLPAPER_CONF" ]] && [[ -s "$WALLPAPER_CONF" ]]; then
        WALLPAPER=$(head -1 "$WALLPAPER_CONF")
    else
        WALLPAPER="$HOME/.config/walls/tokyonight.png"
    fi
    log "Setting wallpaper: $WALLPAPER"
    xwallpaper --zoom "$WALLPAPER" &
else
    err "xwallpaper not found, wallpaper not set"
fi

systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
