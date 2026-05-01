#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Configure Flathub..."

if ! command -v flatpak >/dev/null; then
    log_info "Installing flatpak..."
    sudo pacman -S --needed --noconfirm flatpak || exit 1
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || log_warn "Flathub configuration failed (may already exist)"

log_info "Setting flatpak theme access..."
flatpak override --user --filesystem=~/.themes:ro
flatpak override --user --filesystem=~/.icons:ro
flatpak override --user --env=GTK_THEME=Mint-Y-Teal

log_info "Flathub configuration complete"
exit 0
