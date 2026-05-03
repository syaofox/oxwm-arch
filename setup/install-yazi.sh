#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing yazi..."

log_info "Installing yazi from official repos..."
if ! sudo pacman -S --needed --noconfirm yazi; then
    log_error "Failed to install yazi"
    exit 1
fi

log_info "Installing compress.yazi plugin..."
ya pkg add KKV9/compress

log_info "yazi installation complete"
exit 0
