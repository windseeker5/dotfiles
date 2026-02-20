#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Dotfiles installer for Arch Linux (Sway + Catppuccin Mocha)
# Usage (after cloning):  bash install.sh
# Usage (curl, no clone): bash <(curl -fsSL https://raw.githubusercontent.com/windseekers/dotfiles/main/install.sh)
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Source lib helpers — with inline fallbacks for the curl-before-clone case
# ---------------------------------------------------------------------------
LIB_COLORS="$SCRIPT_DIR/scripts/lib/colors.sh"
LIB_UTILS="$SCRIPT_DIR/scripts/lib/utils.sh"

if [[ -f "$LIB_COLORS" ]]; then
    # shellcheck source=scripts/lib/colors.sh
    source "$LIB_COLORS"
else
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
fi

if [[ -f "$LIB_UTILS" ]]; then
    # shellcheck source=scripts/lib/utils.sh
    source "$LIB_UTILS"
else
    _STEP_NUM=0
    print_step()   { _STEP_NUM=$(( _STEP_NUM + 1 )); printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"; }
    print_success(){ printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"; }
    print_error()  { printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2; exit 1; }
    confirm() {
        local prompt="${1:-Continue?}"
        printf "${YELLOW}${BOLD}[?]${NC} %s [y/N] " "$prompt"
        read -r reply
        case "$reply" in [yY][eE][sS]|[yY]) return 0 ;; *) return 1 ;; esac
    }
fi

# ---------------------------------------------------------------------------
# Step 1 – Must NOT be root
# ---------------------------------------------------------------------------
print_step "Checking user"
if [[ $EUID -eq 0 ]]; then
    print_error "Do not run this script as root. Run it as your regular user."
fi
print_success "Running as $(whoami)"

# ---------------------------------------------------------------------------
# Step 2 – Detect or clone dotfiles
# ---------------------------------------------------------------------------
print_step "Locating dotfiles"

_looks_like_dotfiles() {
    [[ -f "$1/.zshrc" && -d "$1/.config/sway" ]]
}

if _looks_like_dotfiles "$SCRIPT_DIR"; then
    DOTFILES_DIR="$SCRIPT_DIR"
    print_success "Using dotfiles at $DOTFILES_DIR"
else
    printf "${YELLOW}${BOLD}[?]${NC} Dotfiles repo URL [https://github.com/windseekers/dotfiles.git]: "
    read -r REPO_URL
    REPO_URL="${REPO_URL:-https://github.com/windseekers/dotfiles.git}"
    DOTFILES_DIR="$HOME/.dotfiles"
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        print_success "Repo already cloned at $DOTFILES_DIR — pulling latest"
        git -C "$DOTFILES_DIR" pull --ff-only
    else
        printf "${BLUE}${BOLD}[→]${NC} Cloning %s → %s\n" "$REPO_URL" "$DOTFILES_DIR"
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    # Re-source lib from the freshly cloned repo
    [[ -f "$DOTFILES_DIR/scripts/lib/colors.sh" ]] && source "$DOTFILES_DIR/scripts/lib/colors.sh"
    [[ -f "$DOTFILES_DIR/scripts/lib/utils.sh" ]]  && source "$DOTFILES_DIR/scripts/lib/utils.sh"
    print_success "Dotfiles ready at $DOTFILES_DIR"
fi

# ---------------------------------------------------------------------------
# Step 3 – Install packages (pacman, Arch only)
# ---------------------------------------------------------------------------
print_step "Installing packages"

if ! command -v pacman &>/dev/null; then
    print_error "pacman not found — this script requires Arch Linux."
fi

sudo pacman -S --needed --noconfirm \
    `# Core WM + desktop` \
    sway waybar wofi alacritty \
    `# Shell + editor` \
    zsh neovim git \
    `# Fonts` \
    ttf-jetbrains-mono-nerd \
    `# CLI utilities` \
    starship fzf bat nnn btop cmus \
    grim slurp wl-clipboard wget curl unzip ripgrep man-db \
    `# Audio` \
    pipewire pipewire-pulse wireplumber pamixer pulsemixer \
    `# Browser + notifications` \
    chromium dunst \
    `# Bluetooth` \
    bluez bluez-utils \
    `# Zsh plugins` \
    zsh-autosuggestions zsh-syntax-highlighting

print_success "Packages installed"

# ---------------------------------------------------------------------------
# Step 4 – Backup existing configs
# ---------------------------------------------------------------------------
print_step "Backing up existing configs"

BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

_backup() {
    local src="$1"
    if [[ -e "$src" && ! -L "$src" ]]; then
        cp -r "$src" "$BACKUP_DIR/"
        print_success "Backed up $(basename "$src") → $BACKUP_DIR/"
    fi
}

_backup "$HOME/.config/sway"
_backup "$HOME/.config/waybar"
_backup "$HOME/.config/wofi"
_backup "$HOME/.config/alacritty"
_backup "$HOME/.config/nvim"
_backup "$HOME/.config/starship.toml"
_backup "$HOME/.zshrc"

# Remove backup dir if nothing was put in it
if [[ -z "$(ls -A "$BACKUP_DIR")" ]]; then
    rmdir "$BACKUP_DIR"
    print_success "No existing configs to back up"
else
    print_success "Backups saved to $BACKUP_DIR"
fi

# ---------------------------------------------------------------------------
# Step 5 – Create symlinks
# ---------------------------------------------------------------------------
print_step "Creating symlinks"

mkdir -p "$HOME/.config"

_link() {
    local src="$1" dst="$2"
    ln -sf "$src" "$dst"
    print_success "Linked $dst → $src"
}

_link "$DOTFILES_DIR/.config/sway"          "$HOME/.config/sway"
_link "$DOTFILES_DIR/.config/waybar"        "$HOME/.config/waybar"
_link "$DOTFILES_DIR/.config/wofi"          "$HOME/.config/wofi"
_link "$DOTFILES_DIR/.config/alacritty"     "$HOME/.config/alacritty"
_link "$DOTFILES_DIR/.config/nvim"          "$HOME/.config/nvim"
_link "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
_link "$DOTFILES_DIR/.zshrc"               "$HOME/.zshrc"

# ---------------------------------------------------------------------------
# Step 6 – Set Zsh as default shell
# ---------------------------------------------------------------------------
print_step "Setting default shell"

ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    print_success "Zsh is already the default shell"
else
    chsh -s "$ZSH_PATH"
    print_success "Default shell changed to $ZSH_PATH (takes effect on next login)"
fi

# ---------------------------------------------------------------------------
# Step 7 – Enable Bluetooth (optional)
# ---------------------------------------------------------------------------
print_step "Bluetooth setup"

if confirm "Enable Bluetooth service?"; then
    sudo systemctl enable --now bluetooth.service
    print_success "Bluetooth enabled and started"
else
    print_success "Skipped Bluetooth setup"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf "\n${GREEN}${BOLD}Installation complete!${NC}\n\n"
printf "Next steps:\n"
printf "  • Log out and log back in (or reboot).\n"
printf "  • Sway will start on tty1 automatically.\n"
printf "  • On first Neovim launch, plugins install via lazy.nvim.\n\n"
