<div align="center">
  <img src="./dwm-logo-bordered.png" alt="dwm-logo-bordered" width="195" height="90"/>

# dwm-titus-ubuntu
### Ubuntu-focused fork of Chris Titus Tech's dwm configuration
</div>

---

This repository is an Ubuntu-compatible fork of:

[ChrisTitusTech/dwm-titus](https://github.com/ChrisTitusTech/dwm-titus)

The original project targets Arch Linux and uses `pacman`-based installation and dependency management. This fork adapts the setup, dependency handling, and installation workflow for Ubuntu and Ubuntu-based distributions while staying closely synced with upstream changes.

> The installer script handles dependency installation, setup, compilation, font configuration, and session integration automatically on supported Ubuntu systems.

---

## Supported Environment

- Ubuntu 24.04 LTS
- Ubuntu-based distributions
- Xorg session
- LightDM / startx

---

## Installation

### Quick Install (Recommended)

```bash
git clone git@github.com:hamzaharoon1314/dwm-titus-ubuntu.git

cd dwm-titus-ubuntu

chmod +x install-ubuntu.sh

./install-ubuntu.sh
```

---

### Manual Install

#### Install Dependencies

```bash
sudo apt update

sudo apt install -y \
build-essential \
gcc \
g++ \
make \
git \
pkg-config \
libx11-dev \
libxft-dev \
libxinerama-dev \
libimlib2-dev \
libxcb1-dev \
libxcb-util0-dev \
libfreetype6-dev \
libfontconfig1-dev \
xorg \
xinit \
x11-xserver-utils \
rofi \
picom \
dunst \
feh \
flameshot \
dex \
policykit-1 \
alsa-utils \
fonts-noto-color-emoji \
fcitx5 \
lightdm \
lightdm-gtk-greeter
```

---

### Build and Install

```bash
cp config.def.h config.h

make

sudo make install
```

---

## Starting dwm

### Option A — Display Manager

Select `dwm-titus` from the session menu in LightDM.

---

### Option B — startx

Create:

```bash
echo "exec dwm" > ~/.xinitrc
```

Start session:

```bash
startx
```

---

## Ubuntu Support Layer

Ubuntu-specific support is maintained separately from upstream Arch changes.

### Branch Structure

| Branch | Purpose |
|---|---|
| `main` | Ubuntu-ready branch |
| `upstream-sync` | Clean mirror of upstream repository |

---

## Syncing With Upstream

Update upstream mirror:

```bash
cd ~/Documents/my-dwm/dwm-titus-ubuntu

git fetch upstream

git merge upstream/main

git push origin upstream-sync
```

Rebase Ubuntu branch:

```bash
cd ~/Documents/my-dwm/dwm-titus-dev

git rebase upstream-sync

git push --force-with-lease
```

---

## Upstream Project

Full documentation, features, keybindings, patches, and screenshots are available in the original repository:

[ChrisTitusTech/dwm-titus](https://github.com/ChrisTitusTech/dwm-titus)