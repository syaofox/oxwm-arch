#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"


log_step "Installing yay AUR helper..."

# Check if yay is already installed
if command -v yay &> /dev/null; then
    log_info "yay is already installed, skipping installation"
    exit 0
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Error: Do not run this script as root. Please run it as a regular user with sudo privileges."
    exit 1
fi

# Install required dependencies
log_info "Installing dependencies..."
if ! pacman -Qi base-devel &> /dev/null; then
    log_info "Installing base-devel..."
    sudo pacman -S --noconfirm base-devel || exit 1
fi

if ! pacman -Qi git &> /dev/null; then
    log_info "Installing git..."
    sudo pacman -S --noconfirm git || exit 1
fi

# Create temporary directory for building
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$TEMP_DIR" || exit 1

# Clone yay repository
log_info "Cloning yay repository..."
git clone https://aur.archlinux.org/yay.git || exit 1
cd yay || exit 1

# Build and install yay
log_info "Building yay..."
makepkg -si --noconfirm || exit 1

log_info "yay has been successfully installed!"
log_info "You can now use 'yay' to install packages from AUR"
exit 0