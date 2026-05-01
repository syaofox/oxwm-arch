#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing fonts..."

FONT_packages=(
    noto-fonts-cjk wqy-zenhei ttf-jetbrains-mono-nerd terminus-font noto-fonts-emoji
)

if ! sudo pacman -S --needed --noconfirm "${FONT_packages[@]}"; then
    log_error "Failed to install fonts"
    exit 1
fi

log_info "Refreshing font cache..."
fc-cache -fv 2>/dev/null || true

log_info "Fonts installation complete"
exit 0