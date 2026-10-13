-- Clamshell / lid-switch handling.
--
-- Hyprland emits the Lid Switch as an event, so we never poll. Two live binds
-- cover open<->closed transitions; the one-shot exec below covers the case
-- where the config is (re)loaded while the lid is already shut (e.g. login in
-- clamshell mode, or an `hyprctl reload` from another tool).
--
-- The actual decision lives in scripts/lid.sh:
--   lid closed + external monitor  -> disable eDP-1
--   otherwise                      -> enable  eDP-1

local lid = "~/.config/hypr/scripts/lid.sh"

hl.bind("switch:on:Lid Switch",  function() hl.exec_cmd(lid) end, { locked = true })
hl.bind("switch:off:Lid Switch", function() hl.exec_cmd(lid) end, { locked = true })

-- Reconcile once at (re)load, and whenever a monitor is hotplugged.
hl.exec_cmd(lid)
hl.on("monitor.added", function() hl.exec_cmd(lid) end)
