#!/usr/bin/env bash
# bootstrap.sh — Bootstrap dotfiles on a fresh Ubuntu Server (iMac 2008)
# Run ON THE IMAC as your user: bash bootstrap.sh
set -euo pipefail

DOTFILES_REPO="git@github.com:windseeker5/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

# Inline helpers (no lib available yet)
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
_STEP_NUM=0
print_step()   { _STEP_NUM=$((_STEP_NUM+1)); printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"; }
print_success(){ printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"; }
print_error()  { printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2; exit 1; }

# ── Step 1: Update apt ───────────────────────────────────────────────────────
print_step "Updating package lists"
sudo apt update -y
print_success "Package lists updated"

# ── Step 2: Install minimum required packages ────────────────────────────────
print_step "Installing minimum packages"
sudo apt install -y \
    git curl wget unzip \
    zsh neovim tmux \
    fzf ripgrep bat \
    openssh-server
print_success "Packages installed"

# ── Step 3: Set up SSH key for GitHub ───────────────────────────────────────
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

# ── Step 4: Test GitHub SSH connection ──────────────────────────────────────
print_step "Testing GitHub SSH connection"
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    printf "${YELLOW}Could not authenticate with GitHub via SSH.\n"
    printf "Make sure your key is added to https://github.com/settings/ssh/new${NC}\n"
    print_error "GitHub SSH auth failed. Re-run after adding your key."
fi
print_success "GitHub SSH connection OK"

# ── Step 5: Clone dotfiles ───────────────────────────────────────────────────
print_step "Cloning dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
    print_success "Dotfiles already cloned at $DOTFILES_DIR, skipping"
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    print_success "Dotfiles cloned to $DOTFILES_DIR"
fi

# ── Step 6: Deploy config symlinks ──────────────────────────────────────────
print_step "Deploying dotfiles (zsh, nvim, starship)"
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

_link "${DOTFILES_DIR}/.zshrc"                "${HOME}/.zshrc"
_link "${DOTFILES_DIR}/.config/nvim"          "${CONFIG_DIR}/nvim"
_link "${DOTFILES_DIR}/.config/starship.toml" "${CONFIG_DIR}/starship.toml"
print_success "Dotfiles deployed"

# ── Step 7: Set zsh as default shell ────────────────────────────────────────
print_step "Setting zsh as default shell"
if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
    print_success "Default shell set to zsh (takes effect on next login)"
else
    print_success "zsh is already the default shell"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}Bootstrap complete!${NC}\n\n"
printf "${BOLD}Next steps:${NC}\n"
printf "  1. Log out and back in for zsh to take effect\n"
printf "  2. Your dotfiles are at: %s\n" "$DOTFILES_DIR"\n
printf "  3. To update dotfiles later: cd %s && git pull\n\n" "$DOTFILES_DIR"
