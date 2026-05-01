#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing nemo file manager..."

PACMAN_packages=(
    nemo
    nemo-fileroller
    ffmpegthumbnailer
    tumbler
    bulky
)

log_info "Installing official packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some official packages"
    exit 1
fi

log_info "nemo installation complete"
exit 0