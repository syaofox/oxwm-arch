#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Updating system package database..."

sudo pacman -Syu --noconfirm || exit 1