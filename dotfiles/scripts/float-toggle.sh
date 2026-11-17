#!/usr/bin/env bash
# Super+V — toggle the focused window between tiled and floating.
#
# Plain `togglefloating` floats a window but leaves it pinned at its old tile
# bounds, so it doesn't read as "popped out". This makes floating feel like KDE:
# when a TILED window is floated it also jumps to a comfortable centred size; when
# an already-FLOATING window is toggled it just snaps back into the tiling.
set -euo pipefail

# NB: read the raw value, don't use jq's `//` — `false // x` yields x, so a tiled
# window (floating=false) would look "absent" and the toggle would never fire.
state="$(hyprctl -j activewindow 2>/dev/null | jq -r '.floating')"

case "$state" in
  true)
    # Already floating → return it to the tiling layout.
    hyprctl dispatch 'hl.dsp.window.float({ action = "off" })' >/dev/null
    ;;
  false)
    # Tiled → float it, give it a comfortable size, and centre it on the monitor.
    # (Hyprland ≥0.57 Lua: resize takes pixels, not "%", so size it from the
    # window's monitor in logical px — what the old `resizeactive exact 60% 62%` did.)
    hyprctl eval '
      local w = hl.get_active_window()
      if not w or not w.monitor then return end
      local m = w.monitor
      hl.dispatch(hl.dsp.window.float({ action = "on" }))
      hl.dispatch(hl.dsp.window.resize({ x = math.floor(m.width / m.scale * 0.60), y = math.floor(m.height / m.scale * 0.62) }))
      hl.dispatch(hl.dsp.window.center())
    ' >/dev/null
    ;;
  *)
    exit 0   # null / no focused window
    ;;
esac
