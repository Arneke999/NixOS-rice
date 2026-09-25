#!/usr/bin/env bash
# Re-size an open eww popup to its current content. eww (GTK layer-shell) sizes a
# window once, at open, and doesn't grow/shrink it when the content changes — so a
# list that gains rows after a scan got clipped. Close+reopen re-measures it. Only
# acts if the window is actually open; the click-away backdrop stays up throughout.
# The daemon can briefly refuse commands (EAGAIN) right after a big var update, so
# settle a moment first and retry the reopen — a vanished popup is worse than a
# mis-sized one.
w="${1:?window}"
sleep 0.15
eww active-windows 2>/dev/null | grep -qw "$w" || exit 0
eww close "$w" >/dev/null 2>&1
for _ in 1 2 3 4 5; do
  eww open "$w" >/dev/null 2>&1
  sleep 0.1
  eww active-windows 2>/dev/null | grep -qw "$w" && exit 0
  sleep 0.2
done
