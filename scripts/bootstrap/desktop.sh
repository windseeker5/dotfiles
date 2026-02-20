#!/usr/bin/env bash
# desktop.sh — Install the Sway/Wayland desktop stack on a Pi4 running Arch Linux ARM
# Run ON THE PI as the regular user (NOT root) after minimal.sh has completed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/colors.sh" ]]; then
    source "$SCRIPT_DIR/../lib/colors.sh"
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
    _STEP_NUM=0
    print_step()   { _STEP_NUM=$((_STEP_NUM+1)); printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"; }
    print_success(){ printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"; }
    print_error()  { printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2; exit 1; }
fi

if [[ $EUID -eq 0 ]]; then
    print_error "Run this script as your regular user, not root."
fi

DOTFILES_DIR="${HOME}/.dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
    print_error "Dotfiles not found at $DOTFILES_DIR. Run minimal.sh first."
fi

# ── Step 1: Install Sway stack ────────────────────────────────────────────────
print_step "Installing Sway and Wayland compositor stack"
sudo pacman -S --noconfirm \
    sway waybar wofi alacritty \
    grim slurp swayidle swaylock \
    dunst pipewire pipewire-pulse wireplumber \
    wl-clipboard pamixer brightnessctl \
    xorg-xwayland
print_success "Sway stack installed"

# ── Step 2: Install fonts ─────────────────────────────────────────────────────
print_step "Installing fonts"
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts
print_success "Fonts installed"

# ── Step 3: Deploy desktop dotfiles via symlinks ──────────────────────────────
print_step "Deploying desktop dotfiles (sway, waybar, wofi, alacritty)"
CONFIG_DIR="${HOME}/.config"
mkdir -p "$CONFIG_DIR"

_link() {
    local src="$1" dst="$2"
    if [[ -e "$src" ]]; then
        ln -sf "$src" "$dst"
        printf "  linked: %s → %s\n" "$dst" "$src"
    else
        printf "${YELLOW}  skipped (not found): %s${NC}\n" "$src"
    fi
}

_link "${DOTFILES_DIR}/.config/sway"      "${CONFIG_DIR}/sway"
_link "${DOTFILES_DIR}/.config/waybar"    "${CONFIG_DIR}/waybar"
_link "${DOTFILES_DIR}/.config/wofi"      "${CONFIG_DIR}/wofi"
_link "${DOTFILES_DIR}/.config/alacritty" "${CONFIG_DIR}/alacritty"

print_success "Desktop dotfiles deployed"

# ── Step 4: Enable pipewire via systemd user ──────────────────────────────────
print_step "Enabling pipewire user services"
systemctl --user enable pipewire pipewire-pulse wireplumber
print_success "Pipewire services enabled"

# ── Step 5: Auto-start Sway on tty1 login ────────────────────────────────────
print_step "Configuring Sway auto-start on tty1"
ZPROFILE="${HOME}/.zprofile"
AUTOSTART_LINE='[ "$(tty)" = "/dev/tty1" ] && exec sway'

if [[ -f "$ZPROFILE" ]] && grep -qF 'exec sway' "$ZPROFILE"; then
    print_success "Auto-start already present in $ZPROFILE"
else
    printf '\n# Auto-start Sway on tty1\n%s\n' "$AUTOSTART_LINE" >> "$ZPROFILE"
    print_success "Auto-start added to $ZPROFILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}Desktop setup complete!${NC}\n\n"
printf "${BOLD}To start the desktop:${NC}\n"
printf "  1. Reboot: sudo reboot\n"
printf "  2. Log in on tty1 as your user\n"
printf "  3. Sway will launch automatically\n"
printf "  4. App launcher: Mod+d (Wofi)\n"
printf "  5. Terminal:     Mod+Return (Alacritty)\n\n"
