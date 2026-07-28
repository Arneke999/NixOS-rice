#!/usr/bin/env bash
# Screenshot helper (Print / Super+Shift+S). Region, full-screen, or active-window
# capture; copies the PNG to the clipboard AND saves it to ~/Pictures/Screenshots,
# then fires a notification whose icon is the shot itself.
#
# Written as a script on purpose: the old inline binds wrote to "$shotdir/..." where
# $shotdir was ~/Pictures/Screenshots — and a *quoted* ~ does NOT expand in the
# shell, so grim|tee silently dropped the file on disk (only wl-copy survived).
# Using $HOME here sidesteps that entirely.
#
# Usage: screenshot.sh [region|full|window]   (default: region)
set -euo pipefail

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"

case "$mode" in
  region)
    geom="$(slurp)" || exit 0            # Escape / right-click cancels cleanly
    grim -g "$geom" "$file"
    ;;
  window)
    geom="$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
    grim -g "$geom" "$file"
    ;;
  full|*)
    grim "$file"
    ;;
esac

wl-copy --type image/png < "$file"   # tag it as an image so editors can paste it
command -v notify-send >/dev/null 2>&1 &&
  notify-send -i "$file" "Screenshot saved" "${file##*/}"
