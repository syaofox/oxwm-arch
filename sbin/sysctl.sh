#!/bin/bash
# System Kernel Parameter Optimization Script (Arch Linux / Generic)
# Version: 1.0
# Description:
#   - Increase inotify watcher limit (for IDEs, file watchers)
# Usage:
#   ./sysctl.sh                    # Apply optimizations
#   ./sysctl.sh --chroot           # Write files only, skip runtime apply

[[ "$(id -u)" -ne 0 ]] && exec sudo "$0" "$@"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

is_chroot() {
    [[ "${1:-}" == "--chroot" ]] && return 0
    [[ ! -d /run/systemd/system ]] && return 0
    return 1
}

run_sysctl_optimization() {
    local CHROOT_MODE=false
    for arg in "$@"; do
        [[ "$arg" == "--chroot" ]] && CHROOT_MODE=true
    done
    $CHROOT_MODE || { is_chroot "$@" && CHROOT_MODE=true || CHROOT_MODE=false; }

    log_step "Applying system kernel parameter optimization..."

    BACKUP_DIR="/root/sysctl_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_info "Backing up existing configs to $BACKUP_DIR"
    cp -a /etc/sysctl.d/ "$BACKUP_DIR/" 2>/dev/null || true

    cat << 'EOF' > /etc/sysctl.d/99-inotify.conf
# Increase inotify watcher limit (IDEs, file watchers, Neovim)
fs.inotify.max_user_watches=524288
EOF

    log_info "Configuration file written: /etc/sysctl.d/99-inotify.conf"

    if ! $CHROOT_MODE; then
        log_info "Applying sysctl parameter..."
        sysctl -p /etc/sysctl.d/99-inotify.conf 2>&1 | sed 's/^/  /' || log_warn "Failed to apply inotify limit"
        log_info "Parameter applied to running kernel"
    else
        log_info "Chroot mode: parameter will be applied after reboot"
    fi

    log_info "=========================================="
    log_info "System optimization completed!"
    log_info "=========================================="
    log_info "Verify with: sysctl fs.inotify.max_user_watches"
}

log_step()  { echo -e "\n${CYAN}==> $1${NC}"; }
CYAN='\033[0;36m'

run_sysctl_optimization "$@"
