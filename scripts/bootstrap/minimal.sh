#!/usr/bin/env bash
# minimal.sh — Bootstrap a minimal terminal environment on a fresh Arch Linux ARM Pi4
# Run ON THE PI as root (ssh alarm@<IP>, then: su - / password: root)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Support running the script directly without full dotfiles cloned yet
if [[ -f "$SCRIPT_DIR/../lib/colors.sh" ]]; then
    source "$SCRIPT_DIR/../lib/colors.sh"
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    # Minimal inline fallbacks so the script still runs standalone
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
    _STEP_NUM=0
    print_step()   { _STEP_NUM=$((_STEP_NUM+1)); printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"; }
    print_success(){ printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"; }
    print_error()  { printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2; exit 1; }
    confirm()      { printf "${YELLOW}${BOLD}[?]${NC} %s [y/N] " "${1:-Continue?}"; read -r r; [[ "$r" =~ ^[yY] ]]; }
    require_root() { [[ $EUID -eq 0 ]] || print_error "Must be run as root."; }
fi

# ── Step 1: Require root ─────────────────────────────────────────────────────
print_step "Checking privileges"
require_root
print_success "Running as root"

# ── Step 1b: Set up UTF-8 locale ─────────────────────────────────────────────
print_step "Configuring UTF-8 locale"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
export LANG=en_US.UTF-8
print_success "Locale set to en_US.UTF-8"

# ── Step 2: Initialize pacman keyring ────────────────────────────────────────
print_step "Initializing pacman keyring"
pacman-key --init
pacman-key --populate archlinuxarm
print_success "Keyring initialized"

# ── Step 2b: Switch to reliable mirror ───────────────────────────────────────
print_step "Setting package mirror"
echo 'Server = https://mirrors.ocf.berkeley.edu/archlinuxarm/$arch/$repo' > /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm
print_success "Mirror set to mirrors.ocf.berkeley.edu"

# ── Step 3: System update ─────────────────────────────────────────────────────
print_step "Updating system packages"
pacman -Syu --noconfirm
print_success "System updated"

# ── Step 4: Install base packages ────────────────────────────────────────────
print_step "Installing base packages"
pacman -S --noconfirm \
    zsh neovim git base-devel \
    btop fzf nnn bat lsd wget curl \
    openssh man-db unzip ripgrep \
    fd lazygit
print_success "Base packages installed"

# ── Step 6: Create user ───────────────────────────────────────────────────────
print_step "Creating new user"
printf "${YELLOW}Enter new username: ${NC}"
read -r NEW_USER

if id "$NEW_USER" &>/dev/null; then
    printf "${YELLOW}User '%s' already exists, skipping creation.${NC}\n" "$NEW_USER"
else
    useradd -m -G wheel -s /bin/zsh "$NEW_USER"
    printf "${YELLOW}Set password for %s:${NC}\n" "$NEW_USER"
    passwd "$NEW_USER"
    print_success "User '$NEW_USER' created"
fi

# ── Step 7: Configure sudo ────────────────────────────────────────────────────
print_step "Configuring sudo for wheel group"
# Uncomment %wheel ALL=(ALL:ALL) ALL if not already done
if grep -q '^# %wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    print_success "wheel group granted sudo access"
else
    print_success "wheel sudo rule already active"
fi

# ── Step 8: Set hostname ──────────────────────────────────────────────────────
print_step "Setting hostname"
printf "${YELLOW}Enter hostname for this machine: ${NC}"
read -r HOSTNAME
echo "$HOSTNAME" > /etc/hostname

# Also update /etc/hosts
if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1\t${HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1	${HOSTNAME}" >> /etc/hosts
fi
print_success "Hostname set to '$HOSTNAME'"

# ── Step 9: Clone dotfiles ────────────────────────────────────────────────────
print_step "Cloning dotfiles"
printf "${YELLOW}Enter dotfiles repo URL (e.g. https://github.com/you/dotfiles): ${NC}"
read -r DOTFILES_URL
DOTFILES_DIR="/home/${NEW_USER}/.dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    print_success "Dotfiles directory already exists at $DOTFILES_DIR, skipping clone"
else
    git clone "$DOTFILES_URL" "$DOTFILES_DIR"
    chown -R "${NEW_USER}:${NEW_USER}" "$DOTFILES_DIR"
    print_success "Dotfiles cloned to $DOTFILES_DIR"
fi

# ── Step 10: Deploy terminal dotfiles via symlinks ────────────────────────────
print_step "Deploying dotfiles (zsh, nvim, starship)"
USER_HOME="/home/${NEW_USER}"
CONFIG_DIR="${USER_HOME}/.config"
mkdir -p "$CONFIG_DIR"
chown "${NEW_USER}:${NEW_USER}" "$USER_HOME" "$CONFIG_DIR"

_link() {
    local src="$1" dst="$2"
    if [[ -e "$src" ]]; then
        ln -sf "$src" "$dst"
        printf "  linked: %s → %s\n" "$dst" "$src"
    else
        printf "${YELLOW}  skipped (not found): %s${NC}\n" "$src"
    fi
}

_link "${DOTFILES_DIR}/.zshrc"                    "${USER_HOME}/.zshrc"
_link "${DOTFILES_DIR}/.config/nvim"              "${CONFIG_DIR}/nvim"
_link "${DOTFILES_DIR}/.config/starship.toml"     "${CONFIG_DIR}/starship.toml"

chown -h "${NEW_USER}:${NEW_USER}" \
    "${USER_HOME}/.zshrc" \
    "${CONFIG_DIR}/nvim" \
    "${CONFIG_DIR}/starship.toml" \
    2>/dev/null || true

print_success "Dotfiles deployed"

# ── Step 11: Install pkg-install and pkg-remove commands ─────────────────────
print_step "Installing package management scripts"
for script in pkg-install pkg-remove; do
    src="${DOTFILES_DIR}/scripts/${script}.sh"
    dst="/usr/local/bin/${script}"
    if [[ -f "$src" ]]; then
        chmod +x "$src"
        ln -sf "$src" "$dst"
        printf "  installed: %s\n" "$dst"
    else
        printf "${YELLOW}  skipped (not found): %s${NC}\n" "$src"
    fi
done
print_success "Package scripts installed"

# ── Step 13: Fix resolv.conf (Arch ARM DNS bug) ───────────────────────────────
print_step "Fixing resolv.conf for systemd-resolved"
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved
print_success "resolv.conf fixed and systemd-resolved enabled"

# ── Step 14: Enable SSH ───────────────────────────────────────────────────────
print_step "Enabling SSH daemon"
systemctl enable --now sshd
print_success "sshd enabled and started"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}Bootstrap complete!${NC}\n\n"
printf "${BOLD}Next steps:${NC}\n"
printf "  1. Log out and SSH back in as: ssh %s@<IP>\n" "$NEW_USER"
printf "  2. Verify zsh launches with your config\n"
printf "  3. (Optional) Install the Sway desktop:\n"
printf "     bash ~/.dotfiles/scripts/bootstrap/desktop.sh\n\n"
