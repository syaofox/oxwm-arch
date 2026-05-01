#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing KVM/QEMU virtualization tools..."

log_info "Checking CPU virtualization support..."
if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
    log_info "CPU supports virtualization (VT-x/AMD-V detected)"
else
    log_warn "CPU virtualization support not detected in /proc/cpuinfo"
    log_warn "Please ensure virtualization is enabled in BIOS/UEFI"
fi

PACMAN_packages=(
    qemu-desktop
    libvirt
    virt-manager
    virt-viewer
    dnsmasq
    edk2-ovmf
    swtpm
    iptables-nft
    openbsd-netcat
    vde2
)

log_info "Installing KVM/QEMU packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install KVM/QEMU packages"
    exit 1
fi

log_info "Starting and enabling libvirtd service..."
sudo systemctl enable --now libvirtd

log_info "Configuring libvirt firewall backend for UFW compatibility..."
if command -v ufw >/dev/null 2>&1; then
    log_info "UFW detected, configuring libvirt to use iptables backend..."
    if [ ! -f /etc/libvirt/network.conf ] || ! grep -q "firewall_backend" /etc/libvirt/network.conf 2>/dev/null; then
        echo 'firewall_backend = "iptables"' | sudo tee /etc/libvirt/network.conf >/dev/null
    fi
fi

log_info "Configuring user access..."
for group in libvirt kvm; do
    if ! groups | grep -qw "$group"; then
        sudo usermod -aG "$group" "$USER"
        log_info "Added $USER to $group group (relogin required)"
    fi
done

log_info "Starting default libvirt network..."
sudo virsh net-start default 2>/dev/null || log_info "Default network already active"
sudo virsh net-autostart default

log_info "Configuring UFW for KVM NAT forwarding..."
if command -v ufw >/dev/null 2>&1; then
    default_iface="$(ip route | awk '/default/ {print $5; exit}')"
    log_info "Adding UFW rules for libvirt network virbr0 (host: $default_iface)..."
    sudo ufw allow in on virbr0 2>/dev/null || true
    sudo ufw allow out on virbr0 2>/dev/null || true
    sudo ufw route allow in on virbr0 out on "$default_iface" from 192.168.122.0/24 2>/dev/null || true
    log_info "UFW rules added for KVM"
fi

log_info "Restarting libvirtd to apply network changes..."
sudo systemctl restart libvirtd

log_info "KVM/QEMU installation complete"
log_info "Please logout and login again for group changes to take effect"
exit 0
