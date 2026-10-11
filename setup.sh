#!/bin/bash
set -euo pipefail

# Repo root = directory containing this script (works even if not at ~/dotfiles)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing deps"
sudo pacman -S --needed --noconfirm git base-devel tlp

echo "Setting up symlink"
sudo ln -sf "$REPO_DIR/etc/tlp.d/00-custom.conf" /etc/tlp.d/00-custom.conf

echo "Enabling and starting TLP"
sudo systemctl enable --now tlp.service

echo "Done."
