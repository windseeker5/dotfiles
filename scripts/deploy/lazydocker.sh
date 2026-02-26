#!/usr/bin/env bash
set -euo pipefail

# lazydocker installation module for Arch Linux
# Requires Docker to be installed first

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source library functions
source "$SCRIPT_DIR/scripts/lib/colors.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

print_step "lazydocker installation"

# Check if lazydocker is already installed
if command -v lazydocker &>/dev/null; then
    print_success "lazydocker is already installed ($(lazydocker --version 2>&1 | head -1))"
    exit 0
fi

# Verify Docker is installed
if ! command -v docker &>/dev/null; then
    printf "\n${RED}${BOLD}[✗] Docker is not installed!${NC}\n\n"
    printf "lazydocker requires Docker to be installed first.\n"
    printf "Please select option 1 (Install Docker) from the main menu first.\n\n"
    exit 1
fi

# Install lazydocker package
print_step "Installing lazydocker package"
sudo pacman -S --needed --noconfirm lazydocker
print_success "lazydocker package installed"

printf "\n${GREEN}${BOLD}lazydocker installation complete!${NC}\n\n"
printf "Run: ${BLUE}lazydocker${NC} to launch the Docker management TUI.\n\n"
