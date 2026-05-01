#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing system dependencies..."


PACMAN_packages=(
    neovim # 终端文本编辑器
    fastfetch # 系统信息工具
    htop # 交互式系统监视器
    nvtop # GPU 监视器  
    mpv # 视频播放器
    gpicview # 图片查看器
    wezterm # 终端模拟器
    timeshift # 备份工具
    
    yazi # 文件管理器
    rofi # 应用启动器
    fzf # 模糊查找工具
    fd # 文件查找工具
    ripgrep # 文本搜索工具
    zoxide # 目录导航工具
    bat # 代码查看工具
    thefuck # 纠正命令行错误
    trash-cli # 垃圾桶命令行工具
    neovim # 终端文本编辑器
    wezterm # 终端模拟器
    timeshift # 备份工具
    unzip # 归档工具
    7zip # 归档工具
    nodejs npm # Node.js 和 npm
    uv # Python 包管理器
    maim # 截图工具
    xwallpaper # 壁纸设置工具
    
)

log_info "Installing official packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some official packages"
    exit 1
fi

log_info "Installing AUR packages via yay..."
AUR_PACKAGES=(
    clipster
    opencode-bin
    visual-studio-code-bin
    brave-bin
    mint-y-icons mint-themes 
)
if command -v yay >/dev/null; then
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || log_warn "Some AUR packages failed to install"
fi


log_info "System dependencies installation complete"
exit 0