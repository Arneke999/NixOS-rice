#!/usr/bin/env bash
# Super+Shift+V — toggle "free-float mode" for the CURRENT workspace.
#
# When on: every NEW window that opens on this workspace floats automatically (the
# floating is done by float-ws-listen.sh, which watches for the marker file this
# writes), and the windows already here are floated now too. Toggling off tiles the
# workspace back. State = one marker file per workspace id under ~/.cache/hypr/float-ws/.
set -euo pipefail
dir="$HOME/.cache/hypr/float-ws"; mkdir -p "$dir"
ws="$(hyprctl -j activeworkspace | jq -r '.id')"
[ -n "$ws" ] && [ "$ws" != "null" ] || exit 0
marker="$dir/$ws"

# togglefloating every window on this workspace currently in floating-state $1
# (true → tile them, false → float them).
flip() {
  local want="$1" a
  for a in $(hyprctl -j clients | jq -r --argjson w "$ws" --argjson f "$want" \
              '.[] | select(.workspace.id==$w and .floating==$f) | .address'); do
    hyprctl dispatch togglefloating "address:$a" >/dev/null
  done
}

if [ -e "$marker" ]; then
  rm -f "$marker"
  flip true    # tile the floating ones back
  notify-send -t 1500 "Workspace $ws" "tiled · new windows tile" 2>/dev/null || true
else
  touch "$marker"
  flip false   # float the tiled ones now
  notify-send -t 1500 "Workspace $ws" "free-float · new windows float" 2>/dev/null || true
fi
