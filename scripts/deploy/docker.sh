#!/usr/bin/env bash
set -euo pipefail

# Docker installation module for Arch Linux
# Installs minimal Docker setup: Docker Engine + systemd service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source library functions
source "$SCRIPT_DIR/scripts/lib/colors.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

print_step "Docker installation"

# Install Docker package if not present
if command -v docker &>/dev/null; then
    print_success "Docker is already installed ($(docker --version))"
else
    print_step "Installing docker package"
    sudo pacman -S --needed --noconfirm docker
    print_success "Docker package installed"
fi

# Enable and start Docker service
print_step "Enabling docker.service"
sudo systemctl enable --now docker.service
print_success "Docker service enabled and started"

# Add current user to docker group (idempotent)
if id -nG "$USER" | grep -qw docker; then
    print_success "User $USER is already in docker group"
else
    print_step "Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
    print_success "User added to docker group"
fi

# Verify installation (use sg to activate docker group without requiring re-login)
print_step "Verifying Docker installation"
if sg docker -c "docker run --rm hello-world" &>/dev/null; then
    print_success "Docker verification successful"
else
    print_error "Docker verification failed"
fi

printf "\n${GREEN}${BOLD}Docker installation complete!${NC}\n\n"
printf "Important: Log out and log back in for docker group changes to take effect.\n"
printf "Or run: ${BLUE}newgrp docker${NC} for current session only.\n\n"
