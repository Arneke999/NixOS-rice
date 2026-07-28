#!/usr/bin/env bash
# Flash an eww workspace dot when a window on a workspace you're NOT looking at opens
# or demands attention. Feeds eww's `ws_blink` var: the workspace id to flash, then
# "" to clear. A stamp file means only the most-recent flash clears itself, so
# windows arriving back-to-back don't cut each other's blink short.
#
# Two triggers off the Hyprland socket2 stream:
#   openwindow — a genuinely new window opens elsewhere.
#   urgent     — an existing window raises the urgency hint (this is the
#                "codium reuses its window on another workspace" case, where NO new
#                window is created so openwindow never fires).
set -uo pipefail

sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
stamp="$(mktemp)"; trap 'rm -f "$stamp"' EXIT

focused_ws() { hyprctl -j monitors | jq -r '.[] | select(.focused) | .activeWorkspace.id'; }
# Workspace id of a window from its address (events give it without the 0x prefix).
ws_of() { hyprctl -j clients | jq -r --arg a "0x$1" '.[] | select(.address==$a) | .workspace.id' 2>/dev/null; }

flash() {                                            # $1 = workspace id to flash
  local ws="$1"
  case "$ws" in ''|null|special:*) return;; esac
  [ "$ws" != "$(focused_ws)" ] || return             # you're already looking there
  local now; now="$(date +%s%N)"; printf '%s\n' "$now" > "$stamp"
  printf '%s\n' "$ws"                                 # start the flash
  ( sleep 1.4; [ "$(cat "$stamp" 2>/dev/null)" = "$now" ] && printf '\n' ) &
}

echo ""   # nothing blinking at start
socat -U - "UNIX-CONNECT:$sock" | while IFS= read -r line; do
  case "$line" in
    openwindow'>>'*)
      rest="${line#openwindow>>}"; rest="${rest#*,}"  # ADDR,WSNAME,CLASS,TITLE
      flash "${rest%%,*}"
      ;;
    urgent'>>'*)
      flash "$(ws_of "${line#urgent>>}")"
      ;;
  esac
done
