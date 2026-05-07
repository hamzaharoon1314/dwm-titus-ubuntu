#!/bin/bash
# ─────────────────────────────────────────────────────────
# dwm-utils.sh — Shared utility library for dwm-titus
# Source this file from other scripts:
#   source "$(dirname "$0")/dwm-utils.sh"
# ─────────────────────────────────────────────────────────

# ── Package Manager ──────────────────────────────────────
# Prefer AUR helpers for access to AUR packages

if command -v apt-get &>/dev/null; then
    DISTRO_NAME="Ubuntu/Debian"

    _apt_updated=0
    install_packages() {
        if [ "$_apt_updated" -eq 0 ]; then
            sudo apt-get update -qq
            _apt_updated=1
        fi
        sudo apt-get install -y "$@"
    }

    update_packages() { sudo apt-get update -qq; }
    query_package()   { dpkg -s "$1" &>/dev/null; }

elif command -v pacman &>/dev/null; then
    DISTRO_NAME="Arch Linux"

    if command -v paru &>/dev/null; then
        PKG_CMD="paru -S --needed --noconfirm"
    elif command -v yay &>/dev/null; then
        PKG_CMD="yay -S --needed --noconfirm"
    else
        PKG_CMD="sudo pacman -S --needed --noconfirm"
    fi

    # shellcheck disable=SC2086
    install_packages() { $PKG_CMD "$@"; }
    update_packages()  { sudo pacman -Sy; }
    query_package()    { pacman -Qi "$1" &>/dev/null; }

else
    printf '\033[0;31m[ERROR]\033[0m Unsupported distro — apt-get or pacman required.\n' >&2
    exit 1
fi

# ── Shared helpers ────────────────────────────────────────

try_package() {
    install_packages "$1" 2>/dev/null \
        || printf '\033[1;33m[WARN]\033[0m Package '\''%s'\'' not found — skipping.\n' "$1"
}

# ── Hardware Detection ────────────────────────────────────

# Detect GPU type: nvidia, amd, intel, or unknown
detect_gpu() {
    if command -v lspci &>/dev/null; then
        local vga
        vga=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' || true)
        if echo "$vga" | grep -qi nvidia; then
            echo "nvidia"
        elif echo "$vga" | grep -qi 'amd\|radeon'; then
            echo "amd"
        elif echo "$vga" | grep -qi intel; then
            echo "intel"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Detect battery device name (e.g., BAT0, BAT1)
detect_battery() {
    #ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT[0-9]' | head -1

    for bat in /sys/class/power_supply/BAT*; do
        [ -e "$bat" ] || continue
        basename "$bat"
        return
    done

}

# Detect AC adapter name (e.g., ACAD, AC0, ADP1)
detect_adapter() {
    # ls /sys/class/power_supply/ 2>/dev/null | grep -Ev '^BAT' | head -1

    for dev in /sys/class/power_supply/*; do
        [ -e "$dev" ] || continue

        case "$(basename "$dev")" in
            BAT*) ;;
            *)
                basename "$dev"
                return
                ;;
        esac
    done
}

# Detect if running on a laptop (has battery)
is_laptop() {
    [ -n "$(detect_battery)" ]
}

# Detect first available terminal emulator
# Returns 1 if none found
detect_terminal() {
    for t in ghostty kitty alacritty st xterm; do
        command -v "$t" &>/dev/null && { echo "$t"; return 0; }
    done
    return 1
}