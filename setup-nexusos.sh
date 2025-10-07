#!/bin/bash
# setup-nexusos.sh
# Creates complete NexusOS folder structure with configs, packages, and workflow

set -e

# Base folder
BASE="NexusOS"
mkdir -p "$BASE"

echo "Creating folder structure..."
mkdir -p "$BASE/.github/workflows"
mkdir -p "$BASE/assets"
mkdir -p "$BASE/config/includes.chroot/etc/skel/Pictures"
mkdir -p "$BASE/config/includes.chroot/usr/share/plymouth/themes/nexus-splash"
mkdir -p "$BASE/config/includes.chroot/etc/xdg/autostart"
mkdir -p "$BASE/config/package-lists"
mkdir -p "$BASE/config/bootloaders/isolinux"

echo "Creating build-iso.yml..."
cat > "$BASE/.github/workflows/build-iso.yml" <<'EOF'
name: Build NexusOS ISO

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y live-build cdebootstrap syslinux isolinux squashfs-tools xorriso wget

      - name: Set permissions
        run: sudo chmod -R 777 config/includes.chroot

      - name: Build ISO
        run: |
          sudo lb clean
          sudo lb config \
            --distribution bullseye \
            --debian-installer live \
            --binary-images iso-hybrid \
            --bootappend-live "boot=live components"
          sudo lb build

      - name: Upload ISO
        uses: actions/upload-artifact@v3
        with:
          name: NexusOS.iso
          path: live-image-amd64.hybrid.iso
EOF

echo "Creating gaming package list..."
cat > "$BASE/config/package-lists/gaming.list.chroot" <<'EOF'
# Gaming packages
steam
lutris
wine
winetricks
mesa-utils
vulkan-tools
emulators
playonlinux
EOF

echo "Creating wallpaper.desktop..."
cat > "$BASE/config/includes.chroot/etc/xdg/autostart/wallpaper.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Set Wallpaper
Exec=cp /etc/skel/Pictures/wallpaper.jpg ~/Pictures/wallpaper.jpg
X-GNOME-Autostart-enabled=true
EOF

echo "Creating isolinux.cfg..."
cat > "$BASE/config/bootloaders/isolinux/isolinux.cfg" <<'EOF'
UI menu.c32
MENU TITLE NexusOS Boot Menu
TIMEOUT 50
DEFAULT live

LABEL live
  MENU LABEL Start NexusOS Live
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live quiet splash
EOF

echo "Creating plymouth splash script..."
cat > "$BASE/config/includes.chroot/usr/share/plymouth/themes/nexus-splash/nexus-splash.script" <<'EOF'
wallpaper_image = Image("nexus-splash.png")
wallpaper_image.draw()
EOF

echo "Adding placeholder images..."
touch "$BASE/assets/wallpaper.jpg"
touch "$BASE/assets/splash.png"
cp "$BASE/assets/wallpaper.jpg" "$BASE/config/includes.chroot/etc/skel/Pictures/wallpaper.jpg"
cp "$BASE/assets/splash.png" "$BASE/config/includes.chroot/usr/share/plymouth/themes/nexus-splash/nexus-splash.png"
cp "$BASE/assets/splash.png" "$BASE/config/bootloaders/isolinux/splash.png"

echo "Creating README.md..."
cat > "$BASE/README.md" <<'EOF'
# NexusOS

Custom gaming OS built on Debian Buster.
Includes:
- Custom boot menu and splash screen
- Default wallpaper
- Steam, Wine, Lutris, emulators for Windows games

Workflow:
- GitHub Actions builds ISO automatically from this repo.
EOF

echo "Setup complete! NexusOS folder is ready to zip and push to GitHub."
