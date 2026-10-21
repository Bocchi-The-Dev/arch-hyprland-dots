Basic Arch + Hyprland config for the ASUS Vivo-book E210MAB
The goal for these is to look at least half-decent while not taking up too much resources 
on such a low-end device

## Notes on setup.sh
- It will perform a full system update.
- It will install some dependencies.
- It will NOT work on other distros except arch or arch based.
- The power coenfig it ceopies is for the ASUS VIVO-BOOK E210MAB laptop.
- It WILL reboot your system automatically after 15 seconds!.

## Notes on the dots themselves
- They are VERY basic as to not take up to much resources,
- It's mainly optimised for 1080P and 720P.
- It's VERY close to stock hyprland. using Custom wallpapers.
- Very lightly configured waybar.
- Super + Q For Kitty.
- Super + C To close apps.
- Super + Click and Drag with mouse to move Windows with the mouse.
- Super + Arrow Keys to Switch which Tiled window is focused.
- Super + V Fullscreen focused app

## Networking

The network stack is deliberately boring: one manager, one supplicant, one resolver.

| Layer | What | Where it is set |
|---|---|---|
| Manager | NetworkManager | system |
| WiFi backend | iwd (`wpa_supplicant` stays masked) | `etc/NetworkManager/conf.d/wifi_backend.conf` |
| DHCP | NetworkManager internal (iwd does not do addressing) | `etc/iwd/main.conf` |
| Resolver | systemd-resolved, upstream 1.1.1.1 | `etc/systemd/resolved.conf.d/50-dns.conf` |
| Firewall | nftables, deny inbound; allows replies, DHCP, mDNS, ICMP | `etc/nftables.conf` |
| mDNS | Avahi | enabled by `setup.sh` |
| Power | TLP + no WiFi powersave | `etc/tlp.d/50-wifi-perf.conf` |
| TCP | BBR + fq | `etc/sysctl.d/99-network-tune.conf` |

Extra notes:

- `setup.sh` copies everything from `etc/` into `/etc`, so the clone can be deleted afterwards.
- MAC randomisation is a stable per-network random MAC. It is set in `etc/iwd/main.conf`
  (`AddressRandomization=network`) because NetworkManager's iwd backend ignores its own
  `cloned-mac-address` setting.
- WiFi powersave is disabled in three places on purpose: NetworkManager's default
  (`wifi.powersave=2`), iwd's deep power state (`disable_lps_deep=1`) and TLP. With any of
  them on, the RTL8821CE on this laptop parks the radio and the link collapses to MCS0.
- Two settings are per-network and are **not** in the repo because they are machine/SSID
  specific (and one would need the WiFi password): pinning a weak-signal network to 2.4 GHz
  (`802-11-wireless.band bg`) and its DNS server (`ipv4.dns 1.1.1.1`).
- Bluetooth is installed-less/disabled by choice; re-enable with `systemctl enable --now bluetooth`.

## Credits
Kitty theme: [Catppuccin Macchiato](https://github.com/catppuccin/kitty) (MIT)
Wallpaper from [D3Ext/aesthetic-wallpapers](https://github.com/D3Ext/aesthetic-wallpapers)

## Screenshots
<img width="1366" height="768" alt="20261012_192207" src="https://github.com/user-attachments/assets/ce73cb53-275c-4296-9646-6d836e4792ef" />
<img width="1366" height="768" alt="20261012_192218" src="https://github.com/user-attachments/assets/dac65a26-27d0-417a-b3f3-77c8814c5a2d" />
<img width="1366" height="768" alt="20261012_192227" src="https://github.com/user-attachments/assets/34c7d4c5-0cba-4e39-86a8-520983920dee" />

