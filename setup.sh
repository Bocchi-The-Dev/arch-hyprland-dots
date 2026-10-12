#!/bin/bash
# arch-hyprland-dots - Arch Linux + Hyprland configuration
# Copyright (C) 2026 @Bocchi-The-Dev
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
set -euo pipefail

# Repo root = directory containing this script (works even if not at ~/dotfiles)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating System"
sudo pacman -Syu --needed --noconfirm 

echo "Installing deps"
sudo pacman -S --needed --noconfirm git base-devel tlp nwg-displays hyprland kitty blueman brightnessctl pipewire pipewire-pulse wireplumber pavucontrol nwg-look ttf-jetbrains-mono-nerd wofi polkit-kde-agent hyprpaper dunst thunar xdg-desktop-portal-hyprland waybar wl-copy grim slurp swappy mpv yt-dlp keyd
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
yay -S -needed -noconfirm grimblast-git

echo "Copying dots"
cp -r $REPO_DIR/.config ~/.config
cp $REPO_DIR/.bashrc ~/.bashrc
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/Documents
mkdir -p ~/Videos
mkdir -p ~/Downloads
mkdir -p ~/Music
cp -r $REPO_DIR/wallpapers/ ~/Pictures/


echo "Copying TLP Config."
sudo cp "$REPO_DIR/etc/tlp.d/00-custom.conf" /etc/tlp.d/00-custom.conf

echo "Enabling and starting TLP"
sudo systemctl enable --now tlp.service

echo "Done. Rebooting your system in 15 seconds"
sleep 15
reboot 
