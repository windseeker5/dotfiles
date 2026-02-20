#!/usr/bin/env bash
# flash.sh — Flash Arch Linux ARM (aarch64) to an SD card for Raspberry Pi 4
# Run on the HOST machine as root: sudo bash scripts/rpi4/flash.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/utils.sh"

TARBALL_NAME="ArchLinuxARM-rpi-aarch64-latest.tar.gz"
TARBALL_URL="http://os.archlinuxarm.org/os/${TARBALL_NAME}"
BOOT_MNT="/tmp/rpi4-boot"
ROOT_MNT="/tmp/rpi4-root"

# ── Step 1: Require root ─────────────────────────────────────────────────────
print_step "Checking privileges"
require_root
print_success "Running as root"

# ── Step 2: Check host dependencies ─────────────────────────────────────────
print_step "Checking host dependencies"
MISSING=()
for cmd in parted mkfs.fat mkfs.ext4 bsdtar wget; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    printf "${RED}Missing commands:${NC} %s\n" "${MISSING[*]}"
    printf "${YELLOW}Install on Arch:${NC} sudo pacman -S parted dosfstools e2fsprogs libarchive wget\n"
    print_error "Install missing dependencies and re-run."
fi
print_success "All dependencies present"

# ── Step 3: Locate tarball ───────────────────────────────────────────────────
print_step "Locating Arch Linux ARM tarball"
TARBALL=""

# Check common locations
for candidate in \
    "${HOME}/Downloads/${TARBALL_NAME}" \
    "$(pwd)/cache/${TARBALL_NAME}" \
    "/tmp/${TARBALL_NAME}"; do
    if [[ -f "$candidate" ]]; then
        TARBALL="$candidate"
        print_success "Found tarball: $TARBALL"
        break
    fi
done

if [[ -z "$TARBALL" ]]; then
    printf "${YELLOW}Tarball not found in ~/Downloads or ./cache/${NC}\n"
    if confirm "Download tarball now from archlinuxarm.org? (~700 MB)"; then
        CACHE_DIR="$(pwd)/cache"
        mkdir -p "$CACHE_DIR"
        TARBALL="${CACHE_DIR}/${TARBALL_NAME}"
        printf "${BLUE}Downloading to %s ...${NC}\n" "$TARBALL"
        wget -c --show-progress "$TARBALL_URL" -O "$TARBALL"
        print_success "Download complete"
    else
        print_error "Tarball required. Place it at ~/Downloads/${TARBALL_NAME} and re-run."
    fi
fi

# ── Step 4: List block devices ───────────────────────────────────────────────
print_step "Available block devices"
printf "${BOLD}%-12s %-10s %s${NC}\n" "NAME" "SIZE" "MODEL"
lsblk -d -o NAME,SIZE,MODEL | tail -n +2

# ── Step 5: Select SD card ───────────────────────────────────────────────────
print_step "Select target SD card"
printf "${YELLOW}Enter the device path (e.g. /dev/sdb, /dev/mmcblk0):${NC} "
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
umount "${DEVICE}p"?* 2>/dev/null || true
print_success "Unmounted"

# ── Step 8: Partition ────────────────────────────────────────────────────────
print_step "Partitioning $DEVICE"
parted -s "$DEVICE" mklabel msdos
parted -s "$DEVICE" mkpart primary fat32 1MiB 201MiB
parted -s "$DEVICE" mkpart primary ext4 201MiB 100%
parted -s "$DEVICE" set 1 boot on
print_success "Partitioned"

# Resolve partition names (handles both /dev/sdbN and /dev/mmcblk0pN)
if [[ "$DEVICE" == *mmcblk* ]]; then
    PART1="${DEVICE}p1"
    PART2="${DEVICE}p2"
else
    PART1="${DEVICE}1"
    PART2="${DEVICE}2"
fi

# Allow kernel to re-read partition table
sleep 1
partprobe "$DEVICE" 2>/dev/null || true
sleep 1

# ── Step 9: Format ───────────────────────────────────────────────────────────
print_step "Formatting partitions"
mkfs.fat -F32 "$PART1"
mkfs.ext4 -F "$PART2"
print_success "Formatted"

# ── Step 10: Mount ───────────────────────────────────────────────────────────
print_step "Mounting partitions"
mkdir -p "$BOOT_MNT" "$ROOT_MNT"
mount "$PART2" "$ROOT_MNT"
mkdir -p "${ROOT_MNT}/boot"
mount "$PART1" "$BOOT_MNT"
print_success "Mounted"

# ── Step 11: Extract tarball ─────────────────────────────────────────────────
print_step "Extracting tarball to root partition (this takes a few minutes)"
bsdtar -xpf "$TARBALL" -C "$ROOT_MNT"
print_success "Extraction complete"

# ── Step 12: Move boot files ─────────────────────────────────────────────────
print_step "Moving boot files"
mv "${ROOT_MNT}/boot/"* "$BOOT_MNT/"
print_success "Boot files moved"

# ── Step 13: Fix fstab for aarch64 ──────────────────────────────────────────
print_step "Fixing fstab (mmcblk0 → mmcblk1 for RPi4 aarch64)"
sed -i 's/mmcblk0/mmcblk1/g' "${ROOT_MNT}/etc/fstab"
print_success "fstab updated"

# ── Step 14: Sync ────────────────────────────────────────────────────────────
print_step "Syncing writes to disk (please wait)"
sync
print_success "Sync complete"

# ── Step 15: Unmount ─────────────────────────────────────────────────────────
print_step "Unmounting partitions"
umount "$BOOT_MNT"
umount "$ROOT_MNT"
print_success "Unmounted"

# ── Done ─────────────────────────────────────────────────────────────────────
printf "\n${GREEN}${BOLD}SD card flashed successfully!${NC}\n\n"
printf "${BOLD}Next steps:${NC}\n"
printf "  1. Insert the SD card into the Raspberry Pi 4\n"
printf "  2. Connect Ethernet and power on\n"
printf "  3. Find the Pi's IP (check router or use: arp -a)\n"
printf "  4. SSH in: ssh alarm@<IP>  (password: alarm)\n"
printf "  5. Switch to root: su -  (password: root)\n"
printf "  6. Run: bash scripts/bootstrap/minimal.sh\n\n"
