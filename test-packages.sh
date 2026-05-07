#!/bin/bash

packages=(
build-essential
libx11-dev
libxft-dev
libxinerama-dev
libimlib2-dev
libxcb1-dev
libxcb-util0-dev
libfreetype6-dev
libfontconfig1-dev
rofi
picom
dunst
feh
flameshot
)

for pkg in "${packages[@]}"; do
    apt-cache show "$pkg" >/dev/null 2>&1 \
        && echo "[OK] $pkg" \
        || echo "[MISSING] $pkg"
done
