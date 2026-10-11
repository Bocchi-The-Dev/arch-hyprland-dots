#!/bin/bash
set -euo pipefail

# Repo root = directory containing this script (works even if not at ~/dotfiles)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing deps"
sudo pacman -S --needed --noconfirm git base-devel tlp nwg-displays hyprland kitty blueman brightnessctl pipewire pipewire-pulse wireplumber pavucontrol nwg-look ttf-jetbrains-mono-nerd
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

echo "Copying dots"
cp -r $REPO_DIR/.config ~/.config
cp $REPO_DIR/.bashrc ~/.bashrc

echo "Setting up symlink"
sudo cp "$REPO_DIR/etc/tlp.d/00-custom.conf" /etc/tlp.d/00-custom.conf

echo "Enabling and starting TLP"
sudo systemctl enable --now tlp.service

echo "Done."
