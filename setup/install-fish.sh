#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing fish shell..."

log_info "Installing fish and fisher..."
if ! sudo pacman -S --needed --noconfirm fish fisher; then
    log_error "Failed to install fish/fisher"
    exit 1
fi

log_info "Changing default shell to fish..."
if ! sudo chsh -s /usr/bin/fish "$(whoami)"; then
    log_error "Failed to change shell"
    exit 1
fi

log_info "Installing fisher plugins..."
if ! fish -c "fisher update"; then
    log_error "Failed to install fisher plugins"
    exit 1
fi

log_info "fish installed successfully"

exit 0