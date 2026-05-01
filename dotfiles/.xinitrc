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

# 3. X 基础设置
xset -dpms
xset s off
xset s noblank
xrandr --output Virtual-1 --mode 1440x900 &

# 4. 启动 Gnome Keyring
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
    eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK
    export GNOME_KEYRING_CONTROL
fi


exec dbus-run-session oxwm