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

# The user running this (not root), for group membership the script needs.
TARGET_USER="${SUDO_USER:-$USER}"

# Everything installed here is COPIED, never symlinked back into $REPO_DIR,
# so the clone can be deleted after the script finishes.
echo "Updating System"
sudo pacman -Syu --needed --noconfirm 

echo "Installing deps"
sudo pacman -S --needed --noconfirm \
	base base-devel git sudo less bash-completion \
	linux linux-firmware intel-ucode mkinitcpio efibootmgr btrfs-progs dosfstools \
	intel-media-driver libva-intel-driver vulkan-intel libvpl vpl-gpu-rt \
	hyprland uwsm lightdm lightdm-gtk-greeter seatd hyprpaper hyprpolkitagent \
	waybar dunst kitty wofi thunar nwg-look brightnessctl accountsservice \
	xdg-desktop-portal-hyprland xdg-utils qt5ct qt5-wayland qt6-wayland \
	keyd grim slurp swappy wl-clipboard mpv yt-dlp xed peazip \
	pipewire pipewire-pulse wireplumber rtkit pavucontrol \
	ttf-jetbrains-mono-nerd \
	networkmanager network-manager-applet iwd wireless-regdb avahi nftables \
	tlp zram-generator fwupd reflector \
	firefox github-cli htop fastfetch nano vim rsync unzip unrar pv wget \
	smartmontools android-tools android-udev noto-fonts-cjk \
	ksshaskpass x11-ssh-askpass libsrtp xorg-xhost
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
yay -S --needed --noconfirm grimblast-git ayugram-desktop

echo "Adding $TARGET_USER to seat/input/wheel"
# seatd and libinput need these; wheel is needed for sudo.
sudo usermod -aG seat,input,wheel "$TARGET_USER"

echo "Copying dots"
# -T so re-runs merge into ~/.config instead of creating ~/.config/.config
cp -rT $REPO_DIR/.config ~/.config
cp $REPO_DIR/.bashrc ~/.bashrc
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/Documents
mkdir -p ~/Videos
mkdir -p ~/Downloads
mkdir -p ~/Music
cp -r $REPO_DIR/wallpapers/ ~/Pictures/


echo "Copying system config"
# Mirrors the repo's etc/ tree into /etc (e.g. etc/tlp.d/x.conf ->
# /etc/tlp.d/x.conf). Copies only, so nothing points back at the clone.
while IFS= read -r -d '' src; do
	rel="${src#$REPO_DIR/etc/}"
	dst="/etc/$rel"
	if [ "$(readlink -f "$src")" = "$(readlink -f "$dst" 2>/dev/null || true)" ]; then
		continue
	fi
	sudo install -Dm644 "$src" "$dst"
done < <(find "$REPO_DIR/etc" -type f -print0)
# fwupd ships its config 0640 root:root; the generic loop installs 0644.
sudo chmod 640 /etc/fwupd/fwupd.conf

echo "Generating kernel cmdline"
# /etc/kernel/cmdline is machine-specific (root PARTUUID), so it is generated
# rather than stored in the repo. The two non-default flags are the point:
# zswap off (zram is used instead) and pm_debug_messages (crash diagnostics).
ROOT_PARTUUID="$(findmnt -no PARTUUID /)"
ROOT_SUBVOL="$(findmnt -no FSROOT /)"; ROOT_SUBVOL="${ROOT_SUBVOL#/}"
ROOT_FSTYPE="$(findmnt -no FSTYPE /)"
printf 'root=PARTUUID=%s zswap.enabled=0 rootflags=subvol=%s rw rootfstype=%s pm_debug_messages\n' \
	"$ROOT_PARTUUID" "$ROOT_SUBVOL" "$ROOT_FSTYPE" | sudo tee /etc/kernel/cmdline >/dev/null

sudo sysctl --system >/dev/null

echo "Masking services that must not run"
# TLP replaces power-profiles-daemon; iwd replaces wpa_supplicant.
sudo systemctl mask power-profiles-daemon.service wpa_supplicant.service
# This firmware TPM exposes no NvPCR NV indices, so these otherwise fail on
# every boot. Nothing here uses TPM-sealed policies, so masking is safe.
sudo systemctl mask systemd-tpm2-setup-early.service systemd-pcrproduct.service 'systemd-pcrlogin@.service'

echo "Enabling and starting TLP"
sudo systemctl enable --now tlp.service

echo "Enabling the firewall"
# /etc/nftables.conf is the ruleset from etc/: deny inbound, allow replies,
# DHCP, mDNS and ICMP.
sudo systemctl enable --now nftables.service

echo "Enabling systemd-resolved"
# NetworkManager is configured (etc/NetworkManager/conf.d/20-dns-resolved.conf)
# to hand DNS to resolved, which needs /etc/resolv.conf pointing at the stub.
sudo systemctl enable --now systemd-resolved.service
sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "Enabling mDNS (Avahi)"
sudo systemctl enable --now avahi-daemon.service

echo "Enabling firmware and mirror maintenance"
# fwupd-refresh only downloads LVFS metadata; fwupd itself is D-Bus activated.
sudo systemctl enable --now fwupd-refresh.timer
# Weekly mirrorlist refresh using etc/xdg/reflector/reflector.conf (GB, IPv4,
# HTTPS). Run it once now so the first pacman sync uses local mirrors.
sudo systemctl enable --now reflector.timer
sudo systemctl start reflector.service || echo "warning: reflector failed; keeping the existing mirrorlist"

echo "Enabling keyd, seatd and the display manager"
sudo systemctl enable --now keyd.service
sudo systemctl enable --now seatd.service
sudo systemctl enable lightdm.service

echo "Disabling Bluetooth"
# Not used on this machine. Re-enable with: systemctl enable --now bluetooth
sudo systemctl disable --now bluetooth.service 2>/dev/null || true

echo "Disabling NetworkManager-wait-online"
# Avoids a boot delay when no network is available yet.
sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

echo "Restarting NetworkManager"
sudo systemctl restart NetworkManager.service

# NOTE: two settings are per-network and cannot be shipped generically (they
# also must not carry the WiFi PSK):
#   nmcli con modify "<ssid>" 802-11-wireless.band bg      # weak 5GHz avoidance
#   nmcli con modify "<ssid>" ipv4.dns 1.1.1.1
# MAC randomisation and WiFi powersave are global defaults, set in
# etc/NetworkManager/conf.d/10-wifi-privacy.conf and etc/iwd/main.conf.

echo "Checking the /boot (ESP) filesystem"
# dosfstools provides fsck.fat, which lets systemd check the FAT ESP at boot.
# Without it systemd never fsck's the ESP and a dirty bit can persist.
BOOT_DEV="$(findmnt -no SOURCE /boot || true)"
if [ -n "$BOOT_DEV" ]; then
	sudo umount /boot || true
	sudo fsck.fat -a "$BOOT_DEV" || true
	sudo mount /boot
fi

echo "Rebuilding the unified kernel image"
# Picks up the generated /etc/kernel/cmdline and etc/mkinitcpio.d/linux.preset.
sudo mkinitcpio -P

sudo install -m 755 bustd /usr/local/bin/bustd
sudo tee /etc/systemd/system/bustd.service <<'EOF'
[Unit]
Description=bustd OOM killer

[Service]
ExecStart=/usr/local/bin/bustd -n
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now bustd

echo "Done. Rebooting your system in 15 seconds"
sleep 15
reboot 
