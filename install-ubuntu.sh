#!/bin/bash
set -e
set -o pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$REPO_DIR/scripts/dwm-utils-ubuntu.sh"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' NC='\033[0m'
info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
ok()   { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
err()  { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

if ! sudo -v 2>/dev/null; then
    err "This script requires sudo privileges. Please run as a sudoer."
    exit 1
fi

BG_DIR="$HOME/Pictures/backgrounds"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║      dwm-titus Installer (Ubuntu)         ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Package manager: $PKG_CMD"
info "Updating apt cache..."
sudo apt-get update -qq


# ── Build dependencies ───────────────────────────────────
info "Installing build dependencies..."

install_packages build-essential curl libx11-dev libxft-dev software-properties-common libxinerama-dev \
    libimlib2-dev libxcb1-dev libxcb-util-dev libfreetype-dev libfontconfig1-dev

install_packages xorg xinit x11-xserver-utils x11-utils
ok "Build dependencies installed."

# ── Runtime dependencies ──────8───────────────────────────
info "Installing runtime dependencies..."

install_packages rofi picom dunst feh flameshot dex alsa-utils git unzip xclip \
    thunar gvfs tumbler thunar-archive-plugin xdg-user-dirs \
    xdg-desktop-portal-gtk pipewire pavucontrol gnome-keyring network-manager \
    network-manager-gnome libnotify-bin rsync

install_packages mate-polkit 2>/dev/null \
    || install_packages policykit-1-gnome 2>/dev/null \
    || { warn "No polkit agent found — install mate-polkit or policykit-1-gnome manually."; true; }

ok "Runtime dependencies installed."

# ── Qt / GTK theming ─────────────────────────────────────
info "Installing Qt/GTK dark-mode dependencies..."
install_packages dconf-cli
install_packages qt6ct 2>/dev/null || install_packages qt5ct 2>/dev/null \
    || warn "Neither qt6ct nor qt5ct found in repos — Qt apps may not respect dark mode."

# nwg-look: not in Ubuntu repos, build from source
if command -v nwg-look &>/dev/null; then
    ok "nwg-look already installed — skipping."
else
    info "Building nwg-look from source..."
    install_packages libgtk-3-dev

    # nwg-look requires Go 1.24+; apt on Ubuntu 24.04 only ships 1.22
    _GO_MIN=24
    _go_cur="$(go version 2>/dev/null | grep -oP 'go1\.\K[0-9]+')"
    if [ -z "$_go_cur" ] || [ "$_go_cur" -lt "$_GO_MIN" ]; then
        _GO_VER="1.24.3"
        _GO_TAR="go${_GO_VER}.linux-amd64.tar.gz"
        _go_tmp="$(mktemp -d)"
        info "Downloading Go ${_GO_VER}..."
        if curl -fsSL "https://go.dev/dl/${_GO_TAR}" -o "$_go_tmp/$_GO_TAR"; then
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "$_go_tmp/$_GO_TAR"
            export PATH="/usr/local/go/bin:$PATH"
            ok "Go ${_GO_VER} installed."
        else
            warn "Go download failed — falling back to apt golang."
            install_packages golang
        fi
        rm -rf "$_go_tmp"
    fi

    _nwg_tmp="$(mktemp -d)"
    if git clone --depth=1 https://github.com/nwg-piotr/nwg-look.git "$_nwg_tmp" 2>/dev/null; then
        if make -C "$_nwg_tmp" build && sudo make -C "$_nwg_tmp" install; then
            ok "nwg-look built and installed."
        else
            warn "nwg-look build failed — install manually: https://github.com/nwg-piotr/nwg-look"
        fi
    else
        warn "nwg-look clone failed — install manually: https://github.com/nwg-piotr/nwg-look"
    fi
    rm -rf "$_nwg_tmp"
fi

ok "Qt/GTK theming dependencies installed."




# ── Fonts ────────────────────────────────────────────────
info "Installing fonts..."
install_packages fonts-noto-color-emoji

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# MesloLGS Nerd Font — not in apt, download from Nerd Fonts GitHub
if fc-list 2>/dev/null | grep -qi "MesloLGS" \
        || ls "$FONT_DIR"/MesloLGS*.ttf &>/dev/null; then
    ok "MesloLGS Nerd Font already installed — skipping."
else
    info "Fetching latest Nerd Fonts release..."
    _MESLO_VER="$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
        | grep '"tag_name"' \
        | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"

    if [[ -z "$_MESLO_VER" ]]; then
        warn "Could not determine latest Nerd Fonts version — falling back to v3.2.1"
        _MESLO_VER="v3.2.1"
    else
        info "Latest Nerd Fonts release: ${_MESLO_VER}"
    fi

    _meslo_tmp="$(mktemp -d)"
    info "Downloading MesloLGS Nerd Font ${_MESLO_VER}..."
    if curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/download/${_MESLO_VER}/Meslo.zip" \
            -o "$_meslo_tmp/Meslo.zip"; then
        info "Extracting fonts..."
        unzip -oq "$_meslo_tmp/Meslo.zip" "*.ttf" -d "$FONT_DIR" 2>/dev/null || true
        ok "Extracted."
        info "Rebuilding font cache..."
        fc-cache -fv >/dev/null 2>&1
        ok "Font cache updated."
        ok "MesloLGS Nerd Font ${_MESLO_VER} installed."
    else
        warn "MesloLGS download failed — install manually from:"
        warn "  https://github.com/ryanoasis/nerd-fonts/releases/download/${_MESLO_VER}/Meslo.zip"
    fi
    rm -rf "$_meslo_tmp"
fi

# Polybar bundled fonts
if [ -d "$REPO_DIR/config/polybar/fonts" ]; then
    cp -r "$REPO_DIR/config/polybar/fonts/"* "$FONT_DIR/"
    fc-cache -fv >/dev/null 2>&1
fi
ok "Fonts installed."

# ── Terminal emulator ────────────────────────────────────
terminal=""
for t in ghostty kitty alacritty; do command -v "$t" &>/dev/null && { terminal="$t"; break; }; done

if [ -n "$terminal" ]; then
    ok "Terminal already installed: $terminal"
else
    info "No supported terminal found — installing..."
    install_packages kitty 2>/dev/null \
        || install_packages alacritty 2>/dev/null \
        || install_packages ghostty 2>/dev/null \
        || warn "No terminal could be installed — install kitty, alacritty, or ghostty manually from https://ghostty.org"
fi


# ── Polybar + XDG dirs + wallpapers ──────────────────────
install_packages polybar
command -v xdg-user-dirs-update &>/dev/null && xdg-user-dirs-update

mkdir -p "$HOME/Pictures"
if [ ! -d "$BG_DIR" ]; then
    info "Downloading Nord wallpapers..."
    git clone https://github.com/ChrisTitusTech/nord-background.git "$BG_DIR" 2>/dev/null \
        && ok "Wallpapers downloaded to $BG_DIR" \
        || warn "Failed to download wallpapers. Add your own to $BG_DIR."
else
    ok "Wallpapers already present."
fi



# ── Display manager ──────────────────────────────────────
currentdm=""
for dm in lightdm sddm gdm gdm3; do command -v "$dm" &>/dev/null && { currentdm="$dm"; break; }; done

if [ -n "$currentdm" ]; then
    ok "Display manager already installed: $currentdm"
else
    info "No display manager found — installing LightDM..."
    install_packages lightdm

    # lightdm-slick-greeter needs a PPA on Ubuntu; fall back to gtk-greeter if it fails
    if command -v add-apt-repository &>/dev/null; then
        info "Adding PPA for lightdm-slick-greeter..."
        if sudo add-apt-repository -y ppa:kelebek333/mint-tools 2>/dev/null \
                && sudo apt-get update -qq \
                && install_packages lightdm-slick-greeter 2>/dev/null; then
            ok "lightdm-slick-greeter installed."
        else
            warn "lightdm-slick-greeter PPA failed — falling back to lightdm-gtk-greeter."
            install_packages lightdm-gtk-greeter 2>/dev/null || true
        fi
    else
        warn "add-apt-repository not available — installing lightdm-gtk-greeter as fallback."
        install_packages lightdm-gtk-greeter 2>/dev/null || true
    fi

    sudo systemctl enable lightdm
    ok "LightDM installed and enabled."
fi

# ── LightDM greeter config ───────────────────────────────
if command -v lightdm &>/dev/null; then
    info "Deploying LightDM GTK greeter config..."
    sudo make -C "$REPO_DIR/lightdm" install
    ok "LightDM config deployed."
fi

# ── Build & Install ──────────────────────────────────────
cd "$REPO_DIR"
sudo make clean install

# ── Done ─────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║          Installation Complete!           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Detected: $DISTRO_NAME"
echo "  • Edit config.h to customize, then: make && sudo make install"
echo "  • Log out and select 'dwm', or start with: startx"
echo ""
echo "  SUPER+/   keybind viewer     SUPER+X  terminal"
echo "  SUPER+F1  control center     SUPER+R  app launcher (rofi)"
echo "  SUPER+Q   close window"
echo ""
echo "  Full reference: docs/src/keybinds.md or SUPER+/ in dwm"
echo ""
