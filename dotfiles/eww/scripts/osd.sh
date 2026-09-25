#!/usr/bin/env bash
# On-screen display for volume / brightness. Args: vol | bri
# Shows the `osd` eww window and hides it ~1.4 s after the LAST change: each call writes
# a fresh token, and the delayed close only fires if the token is still ours — so holding
# a key keeps the OSD up instead of it flickering. Skipped while the matching popup is
# open (you're already looking at that slider).
kind="${1:-vol}"; d="$(dirname "$0")"
case "$kind" in vol) pop=pop-audio ;; bri) pop=pop-brightness ;; *) exit 0 ;; esac
active="$(eww active-windows 2>/dev/null)"
grep -qw "$pop" <<<"$active" && exit 0
# The volume poll is 1 s; refresh now so the OSD never shows a stale value (matters for
# changes that didn't come through vol-ctl.sh, e.g. AirPods or another app).
[ "$kind" = vol ] && eww update volume="$("$d/volume.sh")" >/dev/null 2>&1
eww update osd_kind="$kind" >/dev/null 2>&1
grep -qE '^osd:' <<<"$active" || eww open osd >/dev/null 2>&1
tok="${XDG_RUNTIME_DIR:-/tmp}/eww-osd.token"; me="$(date +%s%N)"; echo "$me" > "$tok"
setsid -f bash -c 'sleep 1.4; [ "$(cat "$1" 2>/dev/null)" = "$2" ] && eww close osd' \
  _ "$tok" "$me" >/dev/null 2>&1
