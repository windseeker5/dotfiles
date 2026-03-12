#!/usr/bin/env bash
# bootstrap.sh — Full dotfiles + Sway desktop setup on Ubuntu Server (iMac 2008)
# Mirrors the Arch Linux Pi4 setup (minimal.sh + desktop.sh) but for Ubuntu/apt.
# Run ON THE IMAC as your user: bash scripts/imac2008/bootstrap.sh
set -euo pipefail

DOTFILES_REPO="git@github.com:windseeker5/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

# ── Inline helpers ───────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
_STEP_NUM=0
print_step()   { _STEP_NUM=$((_STEP_NUM+1)); printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"; }
print_success(){ printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"; }
print_error()  { printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2; exit 1; }
confirm()      { printf "${YELLOW}${BOLD}[?]${NC} %s [y/N] " "${1:-Continue?}"; read -r r; [[ "$r" =~ ^[yY] ]]; }

if [[ $EUID -eq 0 ]]; then
    print_error "Run this script as your regular user, not root."
fi

# =============================================================================
#  PART 1: BASE SYSTEM (mirrors minimal.sh)
# =============================================================================

# ── Step: Update apt ─────────────────────────────────────────────────────────
print_step "Updating package lists"
sudo apt update -y && sudo apt upgrade -y
print_success "System updated"

# ── Step: Install base packages ──────────────────────────────────────────────
print_step "Installing base packages"
sudo apt install -y \
    git curl wget unzip man-db \
    zsh tmux \
    fzf ripgrep bat nnn btop \
    fd-find \
    build-essential \
    openssh-server software-properties-common
print_success "Base packages installed"

# ── Step: Install Neovim (latest from PPA — lazy.nvim requires >= 0.8) ──────
print_step "Installing Neovim (PPA)"
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update -y
sudo apt install -y neovim
print_success "Neovim installed ($(nvim --version | head -1))"

# ── Step: Create symlinks for renamed Ubuntu binaries ────────────────────────
print_step "Creating compatibility symlinks (bat, fd)"
mkdir -p "${HOME}/.local/bin"

# Ubuntu ships 'bat' as 'batcat'
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    printf "  linked: bat → batcat\n"
fi

# Ubuntu ships 'fd' as 'fdfind'
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    printf "  linked: fd → fdfind\n"
fi
print_success "Compatibility symlinks created"

# ── Step: Install lsd (ls replacement) ───────────────────────────────────────
print_step "Installing lsd"
if command -v lsd &>/dev/null; then
    print_success "lsd already installed"
else
    LSD_VERSION="1.1.5"
    LSD_DEB="/tmp/lsd_${LSD_VERSION}_amd64.deb"
    wget -q "https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd_${LSD_VERSION}_amd64.deb" -O "$LSD_DEB"
    sudo dpkg -i "$LSD_DEB"
    rm -f "$LSD_DEB"
    print_success "lsd installed"
fi

# ── Step: Install lazygit ────────────────────────────────────────────────────
print_step "Installing lazygit"
if command -v lazygit &>/dev/null; then
    print_success "lazygit already installed"
else
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/lazygit
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    print_success "lazygit installed"
fi

# ── Step: Install fastfetch ──────────────────────────────────────────────────
print_step "Installing fastfetch"
if command -v fastfetch &>/dev/null; then
    print_success "fastfetch already installed"
else
    FASTFETCH_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    FASTFETCH_DEB="/tmp/fastfetch-linux-amd64.deb"
    curl -Lo "$FASTFETCH_DEB" "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
    sudo dpkg -i "$FASTFETCH_DEB"
    rm -f "$FASTFETCH_DEB"
    print_success "fastfetch installed"
fi

# ── Step: Set up SSH key for GitHub ──────────────────────────────────────────
print_step "Checking SSH key for GitHub"
if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
    printf "${YELLOW}No SSH key found. Generating one...${NC}\n"
    printf "${YELLOW}Enter your email for the SSH key: ${NC}"
    read -r SSH_EMAIL
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "${HOME}/.ssh/id_ed25519" -N ""
    print_success "SSH key generated"
    printf "\n${YELLOW}${BOLD}Add this public key to your GitHub account:${NC}\n"
    printf "${BOLD}https://github.com/settings/ssh/new${NC}\n\n"
    cat "${HOME}/.ssh/id_ed25519.pub"
    printf "\n${YELLOW}Press Enter once you have added the key to GitHub...${NC}"
    read -r
else
    print_success "SSH key already exists"
fi

# ── Step: Test GitHub SSH connection ─────────────────────────────────────────
print_step "Testing GitHub SSH connection"
SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
if ! echo "$SSH_OUTPUT" | grep -qi "successfully authenticated"; then
    printf "${YELLOW}Could not authenticate with GitHub via SSH.\n"
    printf "Make sure your key is added to https://github.com/settings/ssh/new${NC}\n"
    print_error "GitHub SSH auth failed. Re-run after adding your key."
fi
print_success "GitHub SSH connection OK"

# ── Step: Clone dotfiles ────────────────────────────────────────────────────
print_step "Cloning dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
    print_success "Dotfiles already cloned at $DOTFILES_DIR, skipping"
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    print_success "Dotfiles cloned to $DOTFILES_DIR"
fi

# ── Step: Deploy terminal dotfiles ───────────────────────────────────────────
print_step "Deploying terminal dotfiles (zsh, nvim, starship)"
CONFIG_DIR="${HOME}/.config"
mkdir -p "$CONFIG_DIR"

_link() {
    local src="$1" dst="$2"
    if [[ -e "$src" ]]; then
        ln -sfn "$src" "$dst"
        printf "  linked: %s → %s\n" "$dst" "$src"
    else
        printf "${YELLOW}  skipped (not found): %s${NC}\n" "$src"
    fi
}

_link "${DOTFILES_DIR}/.zshrc"                "${HOME}/.zshrc"
_link "${DOTFILES_DIR}/.config/nvim"          "${CONFIG_DIR}/nvim"
_link "${DOTFILES_DIR}/.config/starship.toml" "${CONFIG_DIR}/starship.toml"
print_success "Terminal dotfiles deployed"

# ── Step: Install pkg-install and pkg-remove commands ────────────────────────
print_step "Installing package management scripts"
for script in pkg-install pkg-remove; do
    src="${DOTFILES_DIR}/scripts/${script}.sh"
    dst="${HOME}/.local/bin/${script}"
    if [[ -f "$src" ]]; then
        chmod +x "$src"
        ln -sfn "$src" "$dst"
        printf "  installed: %s\n" "$dst"
    else
        printf "${YELLOW}  skipped (not found): %s${NC}\n" "$src"
    fi
done
print_success "Package scripts installed"

# ── Step: Set zsh as default shell ───────────────────────────────────────────
print_step "Setting zsh as default shell"
if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
    print_success "Default shell set to zsh (takes effect on next login)"
else
    print_success "zsh is already the default shell"
fi

# =============================================================================
#  PART 2: SWAY DESKTOP (mirrors desktop.sh)
# =============================================================================

printf "\n${BOLD}── Desktop Environment ────────────────────────────────────────${NC}\n\n"

# ── Step: Install Sway and Wayland stack ─────────────────────────────────────
print_step "Installing Sway and Wayland compositor stack"
sudo apt install -y \
    sway swaybg waybar wofi \
    grim slurp swayidle swaylock \
    dunst \
    pipewire pipewire-pulse wireplumber \
    wl-clipboard brightnessctl pavucontrol \
    xwayland \
    bluez bluez-tools
print_success "Sway stack installed"

# ── Step: Install alacritty ──────────────────────────────────────────────────
print_step "Installing alacritty"
if command -v alacritty &>/dev/null; then
    print_success "alacritty already installed"
else
    sudo add-apt-repository -y ppa:aslatter/ppa
    sudo apt update -y
    sudo apt install -y alacritty
    print_success "alacritty installed"
fi

# ── Step: Enable Bluetooth service ───────────────────────────────────────────
print_step "Enabling bluetooth service"
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service 2>/dev/null || true
print_success "Bluetooth service enabled"

# ── Step: Install fonts ──────────────────────────────────────────────────────
print_step "Installing JetBrainsMono Nerd Font"
if fc-list | grep -qi "JetBrainsMono Nerd"; then
    print_success "JetBrainsMono Nerd Font already installed"
else
    FONT_DIR="${HOME}/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    FONT_ZIP="/tmp/JetBrainsMono.zip"
    curl -Lo "$FONT_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o "$FONT_ZIP" -d "$FONT_DIR" '*.ttf'
    rm -f "$FONT_ZIP"
    fc-cache -fv
    print_success "JetBrainsMono Nerd Font installed"
fi

# Also install Noto fonts from repos
sudo apt install -y fonts-noto 2>/dev/null || true
print_success "Noto fonts installed"

# ── Step: Deploy desktop dotfiles ────────────────────────────────────────────
print_step "Deploying desktop dotfiles (sway, waybar, wofi, alacritty)"
_link "${DOTFILES_DIR}/.config/sway"      "${CONFIG_DIR}/sway"
_link "${DOTFILES_DIR}/.config/waybar"    "${CONFIG_DIR}/waybar"
_link "${DOTFILES_DIR}/.config/wofi"      "${CONFIG_DIR}/wofi"
_link "${DOTFILES_DIR}/.config/alacritty" "${CONFIG_DIR}/alacritty"
print_success "Desktop dotfiles deployed"

# ── Step: Enable pipewire user services ──────────────────────────────────────
print_step "Enabling pipewire user services"
systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || true
print_success "Pipewire services enabled"

# Sway is started manually by typing `sway` from the TTY

# =============================================================================
#  PART 3: RUST TUI EXTRAS (optional — built from source via cargo)
# =============================================================================

printf "\n${BOLD}── Rust TUI Extras ────────────────────────────────────────────${NC}\n\n"

if confirm "Install Rust TUI tools (wiremix, bluetui, impala)? This will install Rust and build from source — takes a while"; then

    # ── Step: Install Rust via rustup ────────────────────────────────────────
    print_step "Installing Rust toolchain"
    if command -v cargo &>/dev/null; then
        print_success "Rust already installed"
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "${HOME}/.cargo/env"
        print_success "Rust installed"
    fi

    # ── Step: Install build dependencies for Rust TUI tools ────────────────
    print_step "Installing build dependencies for Rust TUI tools"
    sudo apt install -y pkg-config libpipewire-0.3-dev libdbus-1-dev libclang-dev
    print_success "Build dependencies installed"

    # ── Step: Install wiremix (PipeWire TUI mixer) ───────────────────────────
    print_step "Building wiremix (PipeWire TUI mixer)"
    if command -v wiremix &>/dev/null; then
        print_success "wiremix already installed"
    else
        if cargo install wiremix 2>&1; then
            print_success "wiremix installed"
        else
            printf "${YELLOW}  wiremix failed to build (PipeWire version mismatch).${NC}\n"
            printf "${YELLOW}  Installing pulsemixer as fallback audio mixer...${NC}\n"
            sudo apt install -y pulsemixer
            print_success "pulsemixer installed as fallback (wiremix skipped)"
        fi
    fi

    # ── Step: Install bluetui (Bluetooth TUI manager) ────────────────────────
    print_step "Building bluetui (Bluetooth TUI manager)"
    if command -v bluetui &>/dev/null; then
        print_success "bluetui already installed"
    else
        cargo install bluetui
        print_success "bluetui installed"
    fi

    # ── Step: Install impala (Wi-Fi TUI manager) ─────────────────────────────
    print_step "Building impala (Wi-Fi TUI manager)"
    if command -v impala &>/dev/null; then
        print_success "impala already installed"
    else
        # impala needs iwd for Wi-Fi management
        sudo apt install -y iwd 2>/dev/null || true
        cargo install impala
        print_success "impala installed"
    fi

    printf "${GREEN}${BOLD}Rust TUI extras installed!${NC}\n"
else
    printf "${YELLOW}Skipping Rust TUI extras.${NC}\n"
    printf "  You can install them later with:\n"
    printf "    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\n"
    printf "    cargo install wiremix bluetui impala\n\n"
fi

# =============================================================================
#  DONE
# =============================================================================
printf "\n${GREEN}${BOLD}Full setup complete!${NC}\n\n"
printf "${BOLD}What was installed:${NC}\n"
printf "  Terminal: zsh, neovim, tmux, fzf, ripgrep, bat, fd, nnn, btop, lsd, lazygit, fastfetch\n"
printf "  Desktop:  sway, waybar, wofi, alacritty, pipewire, dunst, grim/slurp\n"
printf "  Fonts:    JetBrainsMono Nerd Font, Noto\n"
printf "  Extras:   wiremix, bluetui, impala (if selected)\n"
printf "  Dotfiles: zsh, nvim, starship, sway, waybar, wofi, alacritty\n\n"
printf "${BOLD}Next steps:${NC}\n"
printf "  1. Reboot: sudo reboot\n"
printf "  2. Log in on tty1 as your user\n"
printf "  3. Start Sway manually: type 'sway'\n"
printf "  4. App launcher: Mod+d (Wofi)\n"
printf "  5. Terminal:     Mod+Return (Alacritty)\n"
printf "  6. Your dotfiles are at: %s\n\n" "$DOTFILES_DIR"
