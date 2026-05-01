#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing oxwm from source..."

log_info "Installing dependencies..."
if ! sudo pacman -S --needed --noconfirm zig libx11 libxft freetype2 fontconfig libxinerama; then
    log_error "Failed to install dependencies"
    exit 1
fi

OXWM_REPO="https://github.com/syaofox/oxwm.git"
OXWM_SRC="/tmp/oxwm"

if [[ -d "$OXWM_SRC/.git" ]]; then
    log_info "OXWM source exists, pulling updates..."
    if ! git -C "$OXWM_SRC" pull; then
        log_error "OXWM git pull failed"
        exit 1
    fi
else
    log_info "Cloning OXWM repository..."
    if ! git clone "$OXWM_REPO" "$OXWM_SRC"; then
        log_error "OXWM clone failed"
        exit 1
    fi
fi

cd "$OXWM_SRC" || { log_error "Failed to enter $OXWM_SRC"; exit 1; }

log_info "Building OXWM (ReleaseSmall)..."
if ! zig build -Doptimize=ReleaseSmall; then
    log_error "OXWM build failed"
    exit 1
fi

log_info "Installing OXWM to /usr..."
if ! sudo zig build -Doptimize=ReleaseSmall --prefix /usr install; then
    log_error "OXWM installation failed"
    exit 1
fi

log_info "OXWM installation complete"
exit 0