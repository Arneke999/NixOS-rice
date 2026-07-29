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
    hyprctl dispatch togglefloating
    ;;
  false)
    # Tiled → float it, give it a comfortable size, and centre it on the monitor.
    hyprctl --batch "dispatch togglefloating ; dispatch resizeactive exact 60% 62% ; dispatch centerwindow"
    ;;
  *)
    exit 0   # null / no focused window
    ;;
esac
