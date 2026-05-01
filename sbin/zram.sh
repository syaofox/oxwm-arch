#!/bin/bash
# ZRAM Swap Optimization Script (Arch Linux / Generic)
# Version: 4.0
# Description:
#   - ZRAM swap configuration via systemd-zram-generator
# Usage:
#   ./zram.sh [percent]              # e.g. ./zram.sh 50 (default: 75)
#   ./zram.sh [percent] --chroot     # Write config only, skip service mgmt
# 验证脚本执行结果的方法
# 1. 检查 ZRAM 设备
# swapon --show
# 应看到 zram0 设备
# 2. 检查 ZRAM 配置
# cat /etc/systemd/zram-generator.conf
# 确认配置正确
# 3. 检查服务状态
# systemctl status systemd-zram-setup@zram0
# 确认服务已启用并运行

[[ "$(id -u)" -ne 0 ]] && exec sudo "$0" "$@"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step()  { echo -e "\n${CYAN}==> $1${NC}"; }

is_chroot() {
    [[ "${1:-}" == "--chroot" ]] && return 0
    [[ ! -d /run/systemd/system ]] && return 0
    return 1
}

run_zram_optimization() {
    local CHROOT_MODE=false
    local ZRAM_PERCENT=""

    for arg in "$@"; do
        case "$arg" in
            --chroot) CHROOT_MODE=true ;;
            *)
                if [[ -z "$ZRAM_PERCENT" ]]; then
                    ZRAM_PERCENT="$arg"
                fi
                ;;
        esac
    done
    $CHROOT_MODE || { is_chroot "$@" && CHROOT_MODE=true || CHROOT_MODE=false; }

    ZRAM_PERCENT=${ZRAM_PERCENT:-75}

    if ! [[ "$ZRAM_PERCENT" =~ ^[0-9]+$ ]] || [ "$ZRAM_PERCENT" -lt 1 ] || [ "$ZRAM_PERCENT" -gt 100 ]; then
        log_error "Invalid percentage. Must be between 1 and 100"
    fi

    log_step "ZRAM Configuration (${ZRAM_PERCENT}% of RAM)"
    $CHROOT_MODE && log_info "Chroot mode: writing config only, service will start after reboot"

    BACKUP_DIR="/root/zram_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    if [[ -f /etc/systemd/zram-generator.conf ]]; then
        log_info "Existing config backed up to ${BACKUP_DIR}/zram-generator.conf.bak"
        cp -a /etc/systemd/zram-generator.conf "${BACKUP_DIR}/zram-generator.conf.bak"
    fi

    cat << EOF > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 100 * ${ZRAM_PERCENT}
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

    log_info "Config written: /etc/systemd/zram-generator.conf"
    log_info "  zram-size = ram / 100 * ${ZRAM_PERCENT}  ($(awk '/MemTotal/ {printf "%.0f MB", $2/1024 * '"$ZRAM_PERCENT"'/100}' /proc/meminfo 2>/dev/null || echo "unknown"))"

    if ! $CHROOT_MODE; then
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable systemd-zram-setup@zram0 2>/dev/null || true
        systemctl start systemd-zram-setup@zram0 2>/dev/null || true
        log_info "Service systemd-zram-setup@zram0 enabled and started"
    else
        log_info "Chroot mode: enable with 'systemctl enable systemd-zram-setup@zram0' after reboot"
    fi

    log_info "=========================================="
    log_info "ZRAM configured via systemd-zram-generator:"
    log_info "  - Size: ${ZRAM_PERCENT}% of RAM"
    log_info "  - Compression: zstd"
    log_info "  - Priority: 100"
    log_info "=========================================="
    log_info "Verify with: swapon --show"
    log_warn "Reboot or start systemd-zram-setup@zram0 to apply"
}

run_zram_optimization "$@"
