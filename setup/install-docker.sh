#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing docker..."

PACMAN_packages=(
    docker
    lazydocker 
)

log_info "Installing official packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some official packages"
    exit 1
fi
log_info "Enabling  Docker service..."
if ! sudo systemctl enable docker; then
    log_error "Failed to Docker service"
    exit 1
fi

log_info "Adding current user to docker group..."
if ! sudo usermod -aG docker "$USER"; then
    log_error "Failed to add user to docker group"
    exit 1
fi

log_info "docker installation complete, please log out and log back in to apply group changes"
exit 0