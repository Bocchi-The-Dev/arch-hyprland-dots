#!/bin/bash
chosen=$(printf "󰒲  Sleep\n  Power Off\n󰜉  Restart\n  Hibernate" | \
    wofi --dmenu \
         --prompt "Power" \
         --lines 4 \
         --width 200 \
         --height 180 \
         --no-actions \
         --hide-scroll)

case "$chosen" in
    *Sleep)       systemctl suspend ;;
    *"Power Off") shutdown now ;;
    *Restart)     reboot ;;
    *Hibernate)   systemctl hibernate ;;
esac
