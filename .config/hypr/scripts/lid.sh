#!/usr/bin/env bash
# One-shot clamshell reconciler for Hyprland.
#   * Turns the laptop panel OFF when the lid is closed AND an external
#     monitor is attached (saves battery, no rendering to a shut panel).
#   * Turns it back ON otherwise.
# Invoked only on lid-switch events and once at config load -> no polling.
set -u

LAPTOP="${LAPTOP_OUTPUT:-eDP-1}"
eval_lua() { hyprctl eval "$1" >/dev/null 2>&1; }

# ---- lid state (read once) ----
lid_open=false
for f in /proc/acpi/button/lid/*/state; do
    [ -e "$f" ] || continue
    grep -q open "$f" && lid_open=true
done

# ---- how many *external* (non-laptop) outputs are currently active? ----
ext_count=$(hyprctl -j monitors 2>/dev/null \
    | jq --arg lp "$LAPTOP" '[.[] | select(.name != $lp)] | length')
[ -z "${ext_count:-}" ] && ext_count=0

if [ "$lid_open" = false ] && [ "$ext_count" -ge 1 ]; then
    # Clamshell: external display carries the session, panel off.
    eval_lua "hl.monitor({ output = \"$LAPTOP\", disabled = true })"
else
    # Lid open, or no external display: make sure the panel is usable.
    eval_lua "hl.monitor({ output = \"$LAPTOP\", disabled = false })"
fi

# Safety net: never get stuck with zero monitors (external unplugged while shut).
if [ "$(hyprctl -j monitors 2>/dev/null | jq 'length')" -eq 0 ]; then
    hyprctl reload >/dev/null 2>&1
fi
