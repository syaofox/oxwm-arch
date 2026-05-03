#!/bin/sh

# 1. 环境变量 (建议最先加载)
export XDG_CURRENT_DESKTOP=oxwm
export XDG_SESSION_DESKTOP=oxwm
export XDG_SESSION_TYPE=x11
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export QT_QPA_PLATFORMTHEME=qt5ct

# 2. 加载 X 资源 (修复原脚本错误)
# 请确保 ~/.Xresources 文件存在，或者使用下面这种合并方式
if [ -f ~/.Xresources ]; then
    xrdb -merge ~/.Xresources
else
    # 如果不想单独建文件，可以用 printf 管道给 xrdb
    printf "Xft.dpi: 96\nXft.antialias: 1\nXft.hinting: 1\nXft.hintstyle: hintslight\nXft.rgba: rgb" | xrdb -merge
fi
if [ -f ~/.Xresources.d/slock ]; then
    xrdb -merge ~/.Xresources.d/slock
fi

# 3. X 基础设置
xset dpms 0 0 900
xset s 600 s noblank
xrandr --output Virtual-1 --mode 1440x900 &

# 4. 自动锁屏 (10分钟无操作)
xss-lock -- slock &

# 5. 启动 Gnome Keyring
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK
    export GNOME_KEYRING_CONTROL
fi


# 6. 确保 systemd --user 在运行 (pam_systemd 通常在登录时已启动)
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if ! systemctl --user is-system-running --quiet 2>/dev/null; then
    /usr/lib/systemd/systemd --user &
    for i in $(seq 1 10); do
        systemctl --user is-system-running --quiet 2>/dev/null && break
        sleep 0.2
    done
fi

# 导入关键环境变量到 systemd user 实例
systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GTK_IM_MODULE QT_IM_MODULE XMODIFIERS SDL_IM_MODULE GLFW_IM_MODULE

exec oxwm