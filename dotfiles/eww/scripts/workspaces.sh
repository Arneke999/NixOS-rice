#!/usr/bin/env bash
# Stream the focused monitor's workspaces as a JSON array for eww (deflisten).
# Ported from `niri msg` to Hyprland IPC: hyprctl for state, the socket2 event
# stream (via socat) to know when to re-emit. Emits the same shape the widget
# expects: objects with .idx, .output, .is_focused, .is_active.
emit() {
  local mons focused_mon focused_ws
  mons=$(hyprctl -j monitors)
  focused_mon=$(jq -r '.[] | select(.focused) | .name' <<<"$mons")
  focused_ws=$(jq -r '.[] | select(.focused) | .activeWorkspace.id' <<<"$mons")
  hyprctl -j workspaces | jq -c \
    --arg mon "$focused_mon" --argjson fws "${focused_ws:-0}" '
    [ .[] | select(.monitor == $mon) ]
    | sort_by(.id)
    | map({
        idx: .id,
        output: .monitor,
        is_focused: (.id == $fws),
        is_active: (.windows > 0 or .id == $fws)
      })
  '
}
emit
# Re-emit on every compositor event (workspace/window/monitor changes all matter
# for the dots); the socket2 stream mirrors niri's event-stream.
sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
socat -U - "UNIX-CONNECT:$sock" | while read -r _; do emit; done
