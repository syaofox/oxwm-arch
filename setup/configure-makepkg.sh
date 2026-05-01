#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Configuring AUR build threads..."

MAKEPKG_CONF="/etc/makepkg.conf"

if [[ ! -f "$MAKEPKG_CONF" ]]; then
    log_error "makepkg.conf not found at $MAKEPKG_CONF"
    exit 1
fi

CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)

log_info "Detected CPU cores: $CPU_CORES"

if grep -q "^MAKEFLAGS=" "$MAKEPKG_CONF"; then
    sudo sed -i "s/^MAKEFLAGS=.*/MAKEFLAGS=\"-j${CPU_CORES}\"/" "$MAKEPKG_CONF"
else
    echo "MAKEFLAGS=\"-j${CPU_CORES}\"" | sudo tee -a "$MAKEPKG_CONF" > /dev/null
fi

log_info "Set AUR build threads to $CPU_CORES (-j${CPU_CORES})"
