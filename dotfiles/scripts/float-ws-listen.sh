#!/usr/bin/env bash
# Float new windows that open on a workspace flagged "free-float" by
# float-ws-toggle.sh (Super+Shift+V). Listens to Hyprland's socket2 event stream and,
# on each openwindow, floats the window iff its workspace has a marker file.
#
# The openwindow event carries the workspace NAME as its 2nd field; for the numbered
# workspaces this rice uses, that name IS the id string the toggle keys its marker by,
# so we match directly off the event with no clients lookup (no race, no polling).
#   openwindow>>WINDOWADDRESS,WORKSPACENAME,WINDOWCLASS,WINDOWTITLE
set -uo pipefail

sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
dir="$HOME/.cache/hypr/float-ws"

# Free-float is a runtime mode, not a saved per-workspace setting: clear any stale
# flags on startup so every login begins with all workspaces tiled.
mkdir -p "$dir"; rm -f "$dir"/* 2>/dev/null || true

socat -U - "UNIX-CONNECT:$sock" | while IFS= read -r line; do
  case "$line" in
    openwindow'>>'*)
      rest="${line#openwindow>>}"                 # ADDR,WSNAME,CLASS,TITLE
      addr="${rest%%,*}"
      rest="${rest#*,}"; wsname="${rest%%,*}"
      [ -n "$wsname" ] && [ -e "$dir/$wsname" ] || continue

      # Snapshot windows BEFORE floating this one. n = how many are already floating
      # on this workspace → the cascade index (0 for the first, 1 for the next, …),
      # so each new float steps 30px down-right from the centred base instead of all
      # stacking on the same spot. monid = which monitor the new window is on.
      clients="$(hyprctl -j clients)"
      n="$(jq --arg w "$wsname" '[ .[] | select((.workspace.id|tostring)==$w and .floating==true) ] | length' <<<"$clients")"
      monid="$(jq -r --arg a "0x$addr" '.[] | select(.address==$a) | .monitor' <<<"$clients")"

      hyprctl dispatch togglefloating "address:0x$addr" >/dev/null 2>&1

      # Size + centred-then-cascaded top-left, from THIS window's monitor. Using the
      # monitor's reserved area (the bar) makes the base match centerwindow exactly.
      read -r mx my mw mh rl rt rr rb < <(hyprctl -j monitors | jq -r --argjson m "${monid:-0}" \
        '.[] | select(.id==$m) | "\(.x) \(.y) \(.width) \(.height) \(.reserved[0]) \(.reserved[1]) \(.reserved[2]) \(.reserved[3])"')
      [ -n "${mw:-}" ] || continue

      w=$(( mw * 60 / 100 )); h=$(( mh * 62 / 100 ))
      ux=$(( mx + rl )); uy=$(( my + rt )); uw=$(( mw - rl - rr )); uh=$(( mh - rt - rb ))
      off=$(( (n % 6) * 30 ))                       # wrap after 6 so it stays on-screen
      x=$(( ux + (uw - w) / 2 + off )); y=$(( uy + (uh - h) / 2 + off ))
      hyprctl --batch "dispatch resizewindowpixel exact $w $h,address:0x$addr ; dispatch movewindowpixel exact $x $y,address:0x$addr" >/dev/null 2>&1
      ;;
  esac
done
