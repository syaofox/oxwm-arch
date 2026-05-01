#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Updating user groups..."

sudo usermod -aG video,render $USER || exit 1

log_step "Creating user directories..."

mkdir -p ~/Documents ~/Music ~/Pictures ~/Videos ~/Downloads || exit 1


log_info "User groups and directories updated successfully"