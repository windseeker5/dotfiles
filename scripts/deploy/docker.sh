#!/usr/bin/env bash
set -euo pipefail

# Docker installation module for Arch Linux
# Installs minimal Docker setup: Docker Engine + systemd service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source library functions
source "$SCRIPT_DIR/scripts/lib/colors.sh"
source "$SCRIPT_DIR/scripts/lib/utils.sh"

print_step "Docker installation"

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    print_success "Docker is already installed ($(docker --version))"
    exit 0
fi

# Install Docker package
print_step "Installing docker package"
sudo pacman -S --needed --noconfirm docker
print_success "Docker package installed"

# Enable Docker service
print_step "Enabling docker.service"
sudo systemctl enable docker.service
print_success "Docker service enabled"

# Start Docker service
print_step "Starting docker.service"
sudo systemctl start docker.service
print_success "Docker service started"

# Add current user to docker group
print_step "Adding $USER to docker group"
sudo usermod -aG docker "$USER"
print_success "User added to docker group"

# Verify installation
print_step "Verifying Docker installation"
if sudo docker run --rm hello-world &>/dev/null; then
    print_success "Docker verification successful"
else
    print_error "Docker verification failed"
fi

printf "\n${GREEN}${BOLD}Docker installation complete!${NC}\n\n"
printf "Important: Log out and log back in for docker group changes to take effect.\n"
printf "Or run: ${BLUE}newgrp docker${NC} for current session only.\n\n"
