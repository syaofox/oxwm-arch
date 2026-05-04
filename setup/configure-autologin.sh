#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

CURRENT_USER=$(whoami)
AUTOLOGIN_DIR="/etc/systemd/system/getty@tty1.service.d"
AUTOLOGIN_CONF="$AUTOLOGIN_DIR/autologin.conf"

log_step "Configure TTY auto-login..."

log_info "Configuring TTY1 auto-login..."
if [[ ! -f "$AUTOLOGIN_CONF" ]]; then
    sudo mkdir -p "$AUTOLOGIN_DIR"
    sudo tee "$AUTOLOGIN_CONF" > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF
    log_info "TTY1 auto-login configured"
else
    log_info "Auto-login already configured, skipping"
fi

log_info "Creating password verification script..."
BIN_DIR="$HOME/.local/bin"
SCRIPT_PATH="$BIN_DIR/tty-lock-and-startx.sh"
mkdir -p "$BIN_DIR"

cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
MAX_ATTEMPTS=3
ATTEMPT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

get_password_hash() {
    sudo cat /etc/shadow 2>/dev/null | grep "^$USER:" | cut -d: -f2
}

echo -e "${CYAN}----------------------------------------${NC}"
echo -e "${CYAN}  Welcome, $USER${NC}"
echo -e "${CYAN}  Please enter your password to start OXWM${NC}"
echo -e "${CYAN}----------------------------------------${NC}"

PASSWD_HASH=$(get_password_hash)

if [ -z "$PASSWD_HASH" ]; then
    echo -e "${YELLOW}WARNING: Cannot read password hash. Proceeding without verification.${NC}"
    exec startx
fi

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    read -s -p "Password: " INPUT_PW
    echo
    if echo "$INPUT_PW" | su - "$USER" -c "exit" 2>/dev/null; then
        echo -e "${GREEN}Login successful. Starting OXWM...${NC}"
        exec startx
    else
        echo -e "${RED}Login incorrect.${NC}"
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            echo -e "${YELLOW}Attempts left: $((MAX_ATTEMPTS - ATTEMPT))${NC}"
        fi
    fi
done

echo -e "${RED}Too many failed attempts. Returning to shell.${NC}"
exit 1
EOF
chmod +x "$SCRIPT_PATH"
log_info "Password verification script created: $SCRIPT_PATH"

log_info "Configuring shell profile for auto-start..."
BASH_PROFILE="$HOME/.bash_profile"
FISH_CONFIG_DIR="$HOME/.config/fish"

# Configure for bash
if ! grep -q "tty-lock-and-startx.sh" "$BASH_PROFILE" 2>/dev/null; then
    cat >> "$BASH_PROFILE" << 'EOF'

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
if [ -f "$HOME/.local/bin/tty-lock-and-startx.sh" ]; then
            exec "$HOME/.local/bin/tty-lock-and-startx.sh"
    fi
fi
EOF
    log_info "Added startup entry to ~/.bash_profile"
else
    log_info "~/.bash_profile already configured"
fi

# Configure for fish
FISH_CONF_D="$FISH_CONFIG_DIR/conf.d"
mkdir -p "$FISH_CONF_D"
FISH_AUTOLOGIN_CONF="$FISH_CONF_D/autologin.fish"
if [[ ! -f "$FISH_AUTOLOGIN_CONF" ]]; then
    cat > "$FISH_AUTOLOGIN_CONF" << 'EOF'
# Auto-start X on tty1
if test -z "$DISPLAY" -a "$XDG_VTNR" = "1"
    if test -f "$HOME/.local/bin/tty-lock-and-startx.sh"
        exec "$HOME/.local/bin/tty-lock-and-startx.sh"
    end
end
EOF
    log_info "Added startup entry to fish conf.d"
else
    log_info "Fish autologin config already exists"
fi

SUDOERS_FILE="/etc/sudoers.d/tty-lock-startx-$CURRENT_USER"
SUDOERS_ENTRY="$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/cat /etc/shadow"

if [[ ! -f "$SUDOERS_FILE" ]]; then
    echo "$SUDOERS_ENTRY" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    log_info "Passwordless sudo rule added"
else
    log_info "sudoers file already exists, skipping"
fi

log_info "Auto-login configuration complete"
exit 0