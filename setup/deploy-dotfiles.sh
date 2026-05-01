#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$PROJECT_ROOT/dotfiles"
USER_HOME="$HOME"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

BACKUP_DONE=0

backup_and_copy() {
    local src="$1"
    local target="$2"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ $BACKUP_DONE -eq 0 ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUP_DONE=1
        fi
        local backup_path="$BACKUP_DIR/${target#$USER_HOME/}"
        local backup_dir="$(dirname "$backup_path")"
        mkdir -p "$backup_dir"
        mv "$target" "$backup_path"
        log_info "Backed up: $target -> $backup_path"
    fi

    local target_dir="$(dirname "$target")"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    cp -f "$src" "$target"
    log_info "Copied: $target"
}

log_step "Deploying dotfiles..."

if [ ! -d "$DOTFILES_DIR" ]; then
    log_error "Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
fi

while IFS= read -r rel_path; do
    rel_path="${rel_path#./}"
    [ -z "$rel_path" ] && continue

    src="$DOTFILES_DIR/$rel_path"
    target="$USER_HOME/$rel_path"

    backup_and_copy "$src" "$target"
done < <(cd "$DOTFILES_DIR" && find . \( -type f -o -type l \) 2>/dev/null | grep -v '^./\.git$' | grep -v '^./\.svn$')

log_info "Dotfiles deployed successfully"
