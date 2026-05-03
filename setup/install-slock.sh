#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing slock from source..."

SLOCK_REPO="https://github.com/syaofox/slock.git"
SLOCK_SRC="/tmp/slock"

if [[ -d "$SLOCK_SRC/.git" ]]; then
    log_info "slock source exists, pulling updates..."
    git -C "$SLOCK_SRC" pull
else
    log_info "Cloning slock repository (arch branch)..."
    git clone --branch arch "$SLOCK_REPO" "$SLOCK_SRC"
fi

cd "$SLOCK_SRC" || { log_error "Failed to enter $SLOCK_SRC"; exit 1; }

log_info "Building and installing slock..."
if ! sudo make clean install; then
    log_error "slock build/install failed"
    exit 1
fi

log_info "slock installation complete"
exit 0
