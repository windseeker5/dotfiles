#!/usr/bin/env bash
# flash.sh — Flash Ubuntu Server 22.04 LTS to a USB drive for iMac 2008 installation
# Ubuntu 22.04 has proven 32-bit EFI support for old Apple hardware.
# Run on the HOST machine as root: sudo bash scripts/imac2008/flash.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

ISO_NAME="ubuntu-22.04.5-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/${ISO_NAME}"

# ── Step 1: Require root ─────────────────────────────────────────────────────
print_step "Checking privileges"
require_root
print_success "Running as root"

# ── Step 2: Check host dependencies ─────────────────────────────────────────
print_step "Checking host dependencies"
MISSING=()
for cmd in dd wget lsblk; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    printf "${RED}Missing commands:${NC} %s\n" "${MISSING[*]}"
    printf "${YELLOW}Install on Arch:${NC} sudo pacman -S coreutils wget util-linux\n"
    print_error "Install missing dependencies and re-run."
fi
print_success "All dependencies present"

# ── Step 3: Locate ISO ───────────────────────────────────────────────────────
print_step "Locating Ubuntu Server ISO"
ISO=""

REAL_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"

for candidate in \
    "${REAL_HOME}/Downloads/${ISO_NAME}" \
    "${HOME}/Downloads/${ISO_NAME}" \
    "$(pwd)/cache/${ISO_NAME}" \
    "/tmp/${ISO_NAME}"; do
    if [[ -f "$candidate" ]]; then
        ISO="$candidate"
        print_success "Found ISO: $ISO"
        break
    fi
done

if [[ -z "$ISO" ]]; then
    printf "${YELLOW}ISO not found in ~/Downloads or ./cache/${NC}\n"
    if confirm "Download Ubuntu Server 22.04 LTS now? (~2 GB)"; then
        CACHE_DIR="$(pwd)/cache"
        mkdir -p "$CACHE_DIR"
        ISO="${CACHE_DIR}/${ISO_NAME}"
        printf "${BLUE}Downloading to %s ...${NC}\n" "$ISO"
        wget -c --show-progress "$ISO_URL" -O "$ISO"
        print_success "Download complete"
    else
        print_error "ISO required. Place it at ~/Downloads/${ISO_NAME} and re-run."
    fi
fi

# ── Step 4: List block devices ───────────────────────────────────────────────
print_step "Available block devices"
printf "${BOLD}%-12s %-10s %s${NC}\n" "NAME" "SIZE" "MODEL"
lsblk -d -o NAME,SIZE,MODEL | tail -n +2

# ── Step 5: Select USB drive ─────────────────────────────────────────────────
print_step "Select target USB drive"
printf "${YELLOW}Enter the device path (e.g. /dev/sdb, /dev/sdc):${NC} "
read -r DEVICE

if [[ ! -b "$DEVICE" ]]; then
    print_error "'$DEVICE' is not a valid block device."
fi

# ── Step 6: Safety confirmation ──────────────────────────────────────────────
print_step "Safety confirmation"
DEVICE_SIZE=$(lsblk -d -o SIZE --noheadings "$DEVICE" | tr -d ' ')
printf "${RED}${BOLD}WARNING: ALL DATA ON %s (%s) WILL BE DESTROYED!${NC}\n" "$DEVICE" "$DEVICE_SIZE"
printf "${YELLOW}Type 'yes' to confirm: ${NC}"
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    printf "Aborted.\n"
    exit 0
fi

# ── Step 7: Unmount existing mounts ─────────────────────────────────────────
print_step "Unmounting existing partitions on $DEVICE"
umount "${DEVICE}"?* 2>/dev/null || true
print_success "Unmounted"

# ── Step 8: Flash ISO ────────────────────────────────────────────────────────
print_step "Flashing ISO to $DEVICE (this takes a few minutes)"
dd if="$ISO" of="$DEVICE" bs=4M status=progress oflag=sync
print_success "Flash complete"

# ── Step 9: Sync ─────────────────────────────────────────────────────────────
print_step "Syncing writes to disk (please wait)"
sync
print_success "Sync complete"

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}USB drive flashed successfully!${NC}\n\n"
printf "${BOLD}Next steps:${NC}\n"
printf "  1. Plug the USB drive into the iMac 2008\n"
printf "  2. Power on and immediately hold ${BOLD}Option (⌥)${NC} to open the boot picker\n"
printf "  3. Select the USB drive\n"
printf "  4. Follow the Ubuntu Server installer (it handles the bootloader automatically)\n"
printf "  5. After install, deploy your dotfiles:\n"
printf "     git clone <your-dotfiles-repo> && cd dotfiles\n"
printf "     bash scripts/bootstrap/desktop.sh\n\n"
