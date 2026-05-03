#!/bin/bash
# Btrfs Subvolume Optimization Script (Arch Linux / Generic)
# Version: 4.0
# Description:
#   - Creates separate subvolumes for /var/cache/pacman/pkg, /var/log, /var/lib/docker, /var/lib/libvirt
#   - Applies recommended mount options (noatime, compress=zstd, etc.)
#   - Sets NoCoW on directories that benefit from it (e.g., Docker, VM images)
#   - Updates /etc/fstab and kernel parameters
#   - Timeshift compatibility: ensures @ and @home are snapshots-compatible
# Usage:
#   ./btrfs.sh [username]          # Run normally (auto-detect chroot)
#   ./btrfs.sh [username] --chroot # Force chroot mode
# 验证脚本执行结果的方法
# 1. 检查 btrfs 子卷
# btrfs subvolume list /
# 应看到新增: @pkg, @log, @docker, @libvirt
# 2. 检查挂载情况
# mount | grep btrfs
# 应显示每个目标目录对应独立子卷挂载
# 3. 检查 fstab 条目
# grep btrfs /etc/fstab
# 确认新增条目包含正确的挂载选项和 pass=0
# 4. 检查 NoCoW 属性
# lsattr /var/lib/docker
# 应有 C 标志 (NoCoW)
# 5. 检查目录权限
# ls -la /var/log /var/cache/pacman/pkg
# 确认权限正确
# 6. 验证数据完整性
# ls /var/log /var/cache/pacman/pkg /var/lib/docker /var/lib/libvirt
# 确认数据完整

[[ "$(id -u)" -ne 0 ]] && exec sudo "$0" "$@"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

is_chroot() {
    [[ "${1:-}" == "--chroot" ]] && return 0
    [[ ! -d /run/systemd/system ]] && return 0
    return 1
}

detect_user() {
    local specified="$1"
    if [[ -n "$specified" ]]; then
        echo "$specified"
        return
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
        return
    fi
    local who
    who=$(logname 2>/dev/null) && [[ -n "$who" ]] && echo "$who" && return
    echo ""
}

run_btrfs_optimization() {
    local CHROOT_MODE=false
    local USERNAME=""

    for arg in "$@"; do
        case "$arg" in
            --chroot) CHROOT_MODE=true ;;
            *) [[ -z "$USERNAME" ]] && USERNAME="$arg" ;;
        esac
    done

    if ! $CHROOT_MODE; then
        is_chroot "$@" && CHROOT_MODE=true || CHROOT_MODE=false
    fi

    if [[ -z "$USERNAME" ]]; then
        USERNAME=$(detect_user "")
    fi

    if [[ -z "$USERNAME" ]]; then
        if $CHROOT_MODE; then
            log_warn "No username specified in chroot mode. User directory operations will be skipped."
            log_warn "Pass a username as argument: $0 <username>"
        else
            log_error "Cannot determine regular username. Please run with: $0 <username>"
        fi
    fi

    local USER_HOME=""
    if [[ -n "$USERNAME" ]]; then
        USER_HOME=$(eval echo "~$USERNAME" 2>/dev/null || echo "/home/$USERNAME")
    fi

    ROOT_FSTYPE=$(findmnt -n -o FSTYPE /)
    if [[ "$ROOT_FSTYPE" != "btrfs" ]]; then
        log_error "Root filesystem is not btrfs, cannot execute this script"
    fi
    UUID=$(findmnt -n -o UUID /)
    [[ -z "$UUID" ]] && log_error "Cannot get root partition UUID"

    log_info "Root partition UUID: $UUID"
    [[ -n "$USERNAME" ]] && log_info "Target user: $USERNAME (home: $USER_HOME)"
    $CHROOT_MODE && log_info "Running in chroot mode (systemctl operations skipped)"

    log_info "Checking subvolume prerequisites..."

    local HAS_AT=false HAS_ATHOME=false
    grep -qE "subvol=(/@|@)([[:space:],]|$)" /etc/fstab && HAS_AT=true
    grep -qE "subvol=(/@home|@home)([[:space:],]|$)" /etc/fstab && HAS_ATHOME=true

    if grep -q "^[^#]*${UUID}.*subvol=/0" /etc/fstab; then
        log_info "Detected legacy /0 style subvolumes, checking structure..."
        local mnt=$(mktemp -d /tmp/btrfs_check_XXXXX)
        if mount -U "$UUID" "$mnt" -o subvolid=5 2>/dev/null; then
            local subvols=$(btrfs subvolume list "$mnt" 2>/dev/null | sed -n 's/.*path //p' || true)
            if echo "$subvols" | grep -q "^0$"; then
                if echo "$subvols" | grep -q "^0/home$"; then
                    log_info "Subvolume 0/home detected - normalizing to @ and @home"
                    sed -i 's|subvol=0/subvol=|g' /etc/fstab
                    sed -i 's|subvol=0/home|subvol=@home|g' /etc/fstab
                    HAS_AT=true
                    HAS_ATHOME=true
                fi
            fi
            umount "$mnt" 2>/dev/null || true
            rmdir "$mnt" 2>/dev/null || true
        fi
    fi

    $HAS_AT || log_error "Root subvolume @ not found in fstab"
    $HAS_ATHOME || log_error "Home subvolume @home not found in fstab"
    log_info "Subvolume prerequisites verified"

    log_info "Timeshift compatibility: independent subvolumes will be created to EXCLUDE these directories from snapshots:"
    log_info "  - /var/cache/pacman/pkg (package cache)"
    log_info "  - /var/log (system logs)"
    log_info "  - /var/lib/docker (Docker data)"
    log_info "  - /var/lib/libvirt (VM images)"

    local MNT=$(mktemp -d /tmp/btrfs_mnt_XXXXXX)
    trap 'umount -l "$MNT" 2>/dev/null; rmdir "$MNT" 2>/dev/null; exit' INT TERM EXIT
    mount -U "$UUID" "$MNT" -o subvolid=5 || log_error "Cannot mount btrfs root volume"

    log_info "Current subvolumes under $MNT:"
    btrfs subvolume list "$MNT" 2>/dev/null | sed -n 's/.*path //p' | sort || true

    MOUNT_OPTS="noatime,compress=zstd:3,discard=async,space_cache=v2,commit=120,x-gvfs-hide,ssd"
    NOCOW_MOUNT_OPTS="noatime,nodatacow,discard=async,space_cache=v2,commit=120,x-gvfs-hide,ssd"

    TARGETS=(
        "/var/cache/pacman/pkg:/@pkg:false"
        "/var/log:/@log:false"
        "/var/lib/docker:/@docker:true"
        "/var/lib/libvirt:/@libvirt:true"
    )

    BACKUP_DIR="/root/btrfs_optimize_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_info "Backing up original configuration files to $BACKUP_DIR"
    cp -a /etc/fstab "$BACKUP_DIR/fstab"

    log_info "Updating @ and @home subvolume mount options in /etc/fstab..."
    update_subvol_mount_opts() {
        local subvol=$1
        local fstab="/etc/fstab"
        local mnt_point
        case "$subvol" in
            "@"|"/@") mnt_point="/" ;;
            "@home"|"/@home") mnt_point="/home" ;;
            "@"*) local n="${subvol#@}"; mnt_point="/${n#/}" ;;
            "/@"*) local n="${subvol#*/@}"; mnt_point="/${n#/}" ;;
        esac
        if ! grep -q "^[^#]*${UUID}[[:space:]]*${mnt_point}[[:space:]]" "$fstab"; then
            return 1
        fi
        local opts_field="rw,${MOUNT_OPTS},subvol=${subvol}"
        awk -F'\t' -v uuid="$UUID" -v mp="$mnt_point" -v opts="$opts_field" '
        $1 ~ uuid && $2 == mp {
            $4 = opts
            $5 = 0
            $6 = 0
        }
        {OFS="\t"; print}
        ' "$fstab" > "${fstab}.tmp" && mv "${fstab}.tmp" "$fstab"
        return 0
    }

    update_subvol_mount_opts "/@"   || log_error "Root subvolume @ not found in fstab"
    update_subvol_mount_opts "/@home" || log_error "Home subvolume @home not found in fstab"

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ ! "$line" =~ "$UUID" ]] && continue
        if [[ "$line" =~ subvol=(/@|@)([^[:space:],]*) ]]; then
            local SUBVOL
            SUBVOL=$(echo "$line" | sed -n 's/.*subvol=\([^[:space:],]*\).*/\1/p')
            [[ "$SUBVOL" == "@" || "$SUBVOL" == "/@" || "$SUBVOL" == "@home" || "$SUBVOL" == "/@home" ]] && continue
            update_subvol_mount_opts "$SUBVOL" && log_info "Updated subvolume $SUBVOL mount options"
        fi
    done < /etc/fstab

    for t in "${TARGETS[@]}"; do
        IFS=':' read -r DIR SUBVOL_NAME NOCOW <<< "$t"
        [[ -z "$DIR" || -z "$SUBVOL_NAME" ]] && continue

        mkdir -p "$(dirname "$DIR")" 2>/dev/null || true
        mkdir -p "$DIR" 2>/dev/null || true

        if [[ "$DIR" == "/home"* ]] && [[ -n "$USERNAME" ]]; then
            chown -h "$USERNAME":"$USERNAME" "$DIR" 2>/dev/null || true
            chown -h "$USERNAME":"$USERNAME" "$(dirname "$DIR")" 2>/dev/null || true
        fi

        if btrfs subvolume show "$DIR" &>/dev/null; then
            log_info "$DIR is already a subvolume, skipping"
            continue
        fi

        log_info "Processing $DIR"
        [[ "$NOCOW" == "true" ]] && OPTS="$NOCOW_MOUNT_OPTS" || OPTS="$MOUNT_OPTS"

        if ! $CHROOT_MODE; then
            case "$DIR" in
                "/var/lib/docker") systemctl stop docker.socket docker 2>/dev/null || true ;;
                "/var/lib/libvirt") systemctl stop libvirtd 2>/dev/null || true ;;
            esac
        fi

        if command -v lsof &>/dev/null; then
            if lsof +D "$DIR" &>/dev/null; then
                log_warn "Directory $DIR is in use, forcefully terminating processes..."
                fuser -k "$DIR" 2>/dev/null || true
                sleep 1
            fi
        fi

        SV_PATH="$MNT${SUBVOL_NAME}"
        if [[ ! -d "$SV_PATH" ]]; then
            btrfs subvolume create "$SV_PATH" || log_error "Failed to create subvolume $SV_PATH"
            if [[ "$NOCOW" == "true" ]]; then
                chattr +C "$SV_PATH" || log_error "Failed to set NoCoW on new subvolume"
            fi
            log_info "Subvolume $SV_PATH created"
        else
            log_info "Subvolume $SV_PATH already exists, reusing"
            if [[ "$NOCOW" == "true" ]] && lsattr -d "$SV_PATH" 2>/dev/null | grep -qv 'C'; then
                log_warn "$SV_PATH lacks NoCoW, recreating with CoW disabled..."
                SV_NEW="${SV_PATH}_new_$$"
                btrfs subvolume create "$SV_NEW" || log_error "Failed to create temporary subvolume"
                chattr +C "$SV_NEW" || log_error "Failed to set NoCoW on new subvolume"
                btrfs subvolume delete "$SV_PATH" || log_error "Failed to delete old subvolume"
                mv "$SV_NEW" "$SV_PATH" || log_error "Failed to rename new subvolume"
                log_info "Subvolume $SV_PATH recreated with NoCoW"
            fi
        fi

        if [[ "$NOCOW" == "true" ]]; then
            if lsattr -d "$DIR" 2>/dev/null | grep -q 'C'; then
                log_info "NoCoW confirmed on $DIR"
            else
                log_warn "NoCoW attribute not set on $DIR, attempting to apply..."
                chattr +C "$DIR" 2>/dev/null || true
                if lsattr -d "$DIR" 2>/dev/null | grep -q 'C'; then
                    log_info "NoCoW successfully applied on $DIR"
                else
                    log_warn "NoCoW still not reflected on $DIR"
                fi
            fi
        fi

        OLD_DIR="${DIR}_bak_$$"
        mv "$DIR" "$OLD_DIR" || log_error "Cannot move $DIR"
        mkdir -p "$DIR"
        chmod --reference="$OLD_DIR" "$DIR" 2>/dev/null || true
        chown --reference="$OLD_DIR" "$DIR" 2>/dev/null || true

        mount -U "$UUID" "$DIR" -o "subvol=${SUBVOL_NAME},${OPTS}" || {
            rmdir "$DIR"
            mv "$OLD_DIR" "$DIR"
            log_error "Failed to mount subvolume, rolled back"
        }

        if [[ "$NOCOW" == "true" ]]; then
            chattr +C "$DIR" || log_warn "Failed to set NoCoW on $DIR via mount point"
        fi

        if command -v rsync &>/dev/null; then
            rsync -aAX "$OLD_DIR"/ "$DIR"/ || {
                umount "$DIR"
                rmdir "$DIR"
                mv "$OLD_DIR" "$DIR"
                log_error "Data copy failed, rolled back"
            }
        else
            cp -a --reflink=auto "$OLD_DIR"/. "$DIR"/ || {
                umount "$DIR"
                rmdir "$DIR"
                mv "$OLD_DIR" "$DIR"
                log_error "Data copy failed, rolled back"
            }
        fi

        rm -rf "$OLD_DIR" || log_warn "Cannot remove backup directory $OLD_DIR"

        if ! grep -qE "subvol=${SUBVOL_NAME}([[:space:],]|$)" /etc/fstab; then
            echo "UUID=${UUID}  ${DIR}  btrfs  ${OPTS},subvol=${SUBVOL_NAME}  0  0" >> /etc/fstab
            log_info "Added $DIR mount entry to fstab"
        fi

        log_info "$DIR processing complete"
    done

    log_info "Adding manual mount reference to /etc/fstab..."
    cat >> /etc/fstab << 'EOF'

# ============================================
# Manual Mount Reference (uncomment as needed)
# ============================================

# ssd
#UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/github btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@github 0 0
#UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/data btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@data 0 0

# dnas
#10.10.10.2:/fs/1000/nfs /mnt/dnas nfs noauto,x-systemd.automount,_netdev,addr=10.10.10.2 0 0

# xiaoxin
#10.10.10.6:/fs/1000/nfs /mnt/xiaoxin nfs noauto,x-systemd.automount,_netdev,addr=10.10.10.6 0 0
EOF

    umount "$MNT" && rmdir "$MNT"
    trap - INT TERM EXIT

    if [[ -n "$USERNAME" ]]; then
        if id "$USERNAME" &>/dev/null; then
            log_info "Fixing user directory permissions..."
            [[ -d "$USER_HOME" ]] && chown -R "$USERNAME":"$USERNAME" "$USER_HOME" || log_warn "Cannot fix ownership of $USER_HOME"
        fi
    fi

    log_info "=========================================="
    log_info "Btrfs optimization completed!"
    log_info "Backup files saved in: $BACKUP_DIR"
    log_info "=========================================="
    log_warn "Please reboot the system for all mounts to take effect"
    log_info "Verify mounts with: mount | grep btrfs"
}

run_btrfs_optimization "$@"
