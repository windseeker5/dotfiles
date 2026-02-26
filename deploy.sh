#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# TUI Deployment Tool for Arch Linux
# Usage: bash deploy.sh
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cleanup temp file on exit
TEMP_FILE="/tmp/deploy-choices-$$.tmp"
trap 'rm -f "$TEMP_FILE"' EXIT ERR INT TERM

# ---------------------------------------------------------------------------
# Source library functions
# ---------------------------------------------------------------------------
source "$SCRIPT_DIR/scripts/lib/colors.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
printf "${BLUE}${BOLD}Dotfiles Deployment Tool${NC}\n"
printf "Checking system requirements...\n\n"

# Must NOT be root
if [[ $EUID -eq 0 ]]; then
    print_error "Do not run this script as root. Run it as your regular user."
fi

# Verify pacman exists (Arch only)
if ! command -v pacman &>/dev/null; then
    print_error "pacman not found — this script requires Arch Linux."
fi

# Check/install dialog
if ! command -v dialog &>/dev/null; then
    printf "${YELLOW}${BOLD}[!]${NC} Installing required dependency: dialog\n"
    sudo pacman -S --needed --noconfirm dialog
    print_success "dialog installed"
fi

# Check/install fzf (needed for pkg-install/pkg-remove)
if ! command -v fzf &>/dev/null; then
    printf "${YELLOW}${BOLD}[!]${NC} Installing required dependency: fzf\n"
    sudo pacman -S --needed --noconfirm fzf
    print_success "fzf installed"
fi

print_success "All system requirements met"
printf "\n"

# ---------------------------------------------------------------------------
# Display dialog checklist
# ---------------------------------------------------------------------------
dialog \
    --backtitle "Dotfiles Deployment Tool - Arch Linux/Raspberry Pi" \
    --title "Select Deployment Options" \
    --checklist "Use SPACE to select/deselect, ENTER to confirm, ESC to cancel:" \
    20 75 5 \
    1 "Install Docker (minimal setup)" off \
    2 "Install lazydocker" off \
    3 "Deploy dotfiles (.zshrc + .config/*)" off \
    4 "Interactive package installer" off \
    5 "Interactive package remover" off \
    2>"$TEMP_FILE"

# Check if user canceled
if [[ $? -ne 0 ]]; then
    clear
    printf "${YELLOW}Deployment canceled by user.${NC}\n"
    exit 0
fi

# Clear screen after dialog
clear

# ---------------------------------------------------------------------------
# Process selections
# ---------------------------------------------------------------------------
CHOICES=$(cat "$TEMP_FILE" | tr -d '"')

if [[ -z "$CHOICES" ]]; then
    printf "${YELLOW}No options selected. Exiting.${NC}\n"
    exit 0
fi

printf "${GREEN}${BOLD}Processing selections...${NC}\n\n"

for choice in $CHOICES; do
    case $choice in
        1)
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
            printf "${BLUE}${BOLD}Option 1: Docker Installation${NC}\n"
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n\n"
            bash "$SCRIPT_DIR/scripts/deploy/docker.sh"
            ;;
        2)
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
            printf "${BLUE}${BOLD}Option 2: lazydocker Installation${NC}\n"
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n\n"
            bash "$SCRIPT_DIR/scripts/deploy/lazydocker.sh"
            ;;
        3)
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
            printf "${BLUE}${BOLD}Option 3: Dotfiles Deployment${NC}\n"
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n\n"
            bash "$SCRIPT_DIR/scripts/deploy/dotfiles.sh"
            ;;
        4)
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
            printf "${BLUE}${BOLD}Option 4: Interactive Package Installer${NC}\n"
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n\n"
            bash "$SCRIPT_DIR/scripts/pkg-install.sh"
            ;;
        5)
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
            printf "${BLUE}${BOLD}Option 5: Interactive Package Remover${NC}\n"
            printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}\n\n"
            bash "$SCRIPT_DIR/scripts/pkg-remove.sh"
            ;;
    esac
    printf "\n"
done

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
printf "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
printf "${GREEN}${BOLD}All selected operations completed!${NC}\n"
printf "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
