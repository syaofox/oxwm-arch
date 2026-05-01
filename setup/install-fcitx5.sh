#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing fcitx5..."

PACMAN_packages=(
    fcitx5
    fcitx5-chinese-addons
    fcitx5-gtk
    fcitx5-qt
    fcitx5-configtool
    fcitx5-pinyin-zhwiki
    hunspell
    nuspell
    aspell
    enchant
    hunspell-en_US
)

AUR_PACKAGES=(
    fcitx5-material-color
    fcitx5-nord
)

log_info "Installing official packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some official packages"
    exit 1
fi

log_info "Installing AUR packages via yay..."
if command -v yay >/dev/null; then
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || log_warn "Some AUR packages failed to install"
fi

log_info "fcitx5 installation complete"
exit 0