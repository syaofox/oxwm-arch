#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing Nvidia drivers..."

if ! lspci | grep -i nvidia > /dev/null 2>&1; then
    log_info "No Nvidia GPU detected, skipping Nvidia driver installation"
    exit 0
fi

log_info "Nvidia GPU detected, installing drivers..."

# Install Nvidia packages
NVIDIA_PACKAGES=(
    nvidia-open-dkms
    dkms
    libva-nvidia-driver
    nvidia-utils
)

if ! sudo pacman -S --needed --noconfirm "${NVIDIA_PACKAGES[@]}"; then
    log_error "Failed to install Nvidia packages"
    exit 1
fi

# Install matching kernel headers for DKMS
log_info "Installing kernel headers for DKMS..."
DETECTED_HEADERS=()
for kernel_pkg in $(pacman -Q | awk '/^linux-?[0-9a-z]* /{print $1}'); do
    headers_pkg="${kernel_pkg}-headers"
    if pacman -Si "$headers_pkg" &>/dev/null; then
        if ! pacman -Q "$headers_pkg" &>/dev/null; then
            DETECTED_HEADERS+=("$headers_pkg")
        fi
    fi
done

if [[ ${#DETECTED_HEADERS[@]} -gt 0 ]]; then
    sudo pacman -S --needed --noconfirm "${DETECTED_HEADERS[@]}" || log_warn "Failed to install some kernel headers"
    log_info "Installed kernel headers: ${DETECTED_HEADERS[*]}"
else
    log_info "Kernel headers already installed or none needed"
fi

# Configure modprobe.d for Nvidia DRM
log_info "Configuring modprobe for Nvidia DRM..."
MODPROBE_FILE="/etc/modprobe.d/nvidia.conf"
if [ ! -f "$MODPROBE_FILE" ]; then
    cat << 'EOF' | sudo tee "$MODPROBE_FILE" > /dev/null
# Nvidia DRM kernel module settings for Wayland
options nvidia_drm modeset=1
options nvidia_drm fbdev=1
EOF
    log_info "Created $MODPROBE_FILE"
else
    log_info "$MODPROBE_FILE already exists"
fi

# Add kernel parameters to GRUB (if GRUB is used)
if command -v grub-mkconfig &>/dev/null && [ -f /boot/grub/grub.cfg ]; then
    log_info "GRUB detected, adding Nvidia kernel parameters..."
    GRUB_FILE="/etc/default/grub"
    if grep -q "nvidia_drm.modeset=1" "$GRUB_FILE"; then
        log_info "nvidia_drm.modeset=1 already in GRUB_CMDLINE_LINUX_DEFAULT"
    else
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' "$GRUB_FILE"
        log_info "Updated GRUB_CMDLINE_LINUX_DEFAULT with nvidia_drm.modeset=1"
    fi
    log_info "Regenerating GRUB config..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
elif command -v bootctl &>/dev/null && [ -d /boot/loader ]; then
    log_info "systemd-boot detected, add 'nvidia_drm.modeset=1' manually to your boot entry"
    log_info "Alternatively, add to /etc/kernel/cmdline if using unified kernel images"
else
    log_warn "No supported bootloader detected. Add 'nvidia_drm.modeset=1' to your kernel parameters manually."
fi

# # Uncomment Nvidia env vars in hyprland.conf
# log_info "Enabling Nvidia environment variables in hyprland.conf..."
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# HYPRLAND_CONF="$SCRIPT_DIR/../dotfiles/hypr/.config/hypr/hyprland.conf"
# if [ -f "$HYPRLAND_CONF" ]; then
#     sed -i 's/^# env = GBM_BACKEND,nvidia-drm$/env = GBM_BACKEND,nvidia-drm/' "$HYPRLAND_CONF"
#     sed -i 's/^# env = LIBVA_DRIVER_NAME,nvidia$/env = LIBVA_DRIVER_NAME,nvidia/' "$HYPRLAND_CONF"
#     sed -i 's/^# env = __GLX_VENDOR_LIBRARY_NAME,nvidia$/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/' "$HYPRLAND_CONF"
#     log_info "Nvidia env vars enabled in hyprland.conf"
# fi

log_info "Nvidia drivers installation complete"
exit 0
