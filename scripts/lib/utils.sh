#!/usr/bin/env bash
# Common helper functions — source this after colors.sh

_STEP_NUM=0

print_step() {
    _STEP_NUM=$(( _STEP_NUM + 1 ))
    printf "${BLUE}${BOLD}[Step %d]${NC} %s\n" "$_STEP_NUM" "$1"
}

print_success() {
    printf "${GREEN}${BOLD}[✓]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}${BOLD}[✗]${NC} %s\n" "$1" >&2
    exit 1
}

# confirm "Are you sure?" → returns 0 (yes) or 1 (no)
confirm() {
    local prompt="${1:-Continue?}"
    printf "${YELLOW}${BOLD}[?]${NC} %s [y/N] " "$prompt"
    read -r reply
    case "$reply" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)."
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        print_error "Required command not found: '$cmd'. Install it and re-run."
    fi
}
