#!/usr/bin/env bash
set -euo pipefail

# Dotfiles deployment module
# Backs up existing configs and creates symlinks to dotfiles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source library functions
source "$SCRIPT_DIR/scripts/lib/colors.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

print_step "Dotfiles deployment"

# Verify we're in the dotfiles directory
if [[ ! -f "$SCRIPT_DIR/.zshrc" || ! -d "$SCRIPT_DIR/.config/sway" ]]; then
    print_error "Cannot locate dotfiles. Expected .zshrc and .config/sway in $SCRIPT_DIR"
fi

# ---------------------------------------------------------------------------
# Backup existing configs
# ---------------------------------------------------------------------------
print_step "Backing up existing configs"

BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

_backup() {
    local src="$1"
    # Only backup if exists AND is not already a symlink
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
# Create symlinks
# ---------------------------------------------------------------------------
print_step "Creating symlinks"

mkdir -p "$HOME/.config"

_link() {
    local src="$1" dst="$2"
    ln -sf "$src" "$dst"
    print_success "Linked $dst → $src"
}

_link "$SCRIPT_DIR/.config/sway"          "$HOME/.config/sway"
_link "$SCRIPT_DIR/.config/waybar"        "$HOME/.config/waybar"
_link "$SCRIPT_DIR/.config/wofi"          "$HOME/.config/wofi"
_link "$SCRIPT_DIR/.config/alacritty"     "$HOME/.config/alacritty"
_link "$SCRIPT_DIR/.config/nvim"          "$HOME/.config/nvim"
_link "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
_link "$SCRIPT_DIR/.zshrc"                "$HOME/.zshrc"

printf "\n${GREEN}${BOLD}Dotfiles deployment complete!${NC}\n\n"
printf "Next steps:\n"
printf "  • Reload Zsh: ${BLUE}source ~/.zshrc${NC}\n"
printf "  • Reload Sway: Mod+Shift+c (if in Sway session)\n"
printf "  • Restart Waybar: ${BLUE}pkill waybar && waybar &${NC}\n"
printf "  • Neovim: ${BLUE}:Lazy sync${NC} on next launch\n\n"
