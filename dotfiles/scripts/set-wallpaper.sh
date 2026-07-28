#!/usr/bin/env bash
# Set the wallpaper (awww) and remember it. Arg: wallpaper path (optional).
# The rice's colours are a fixed Catppuccin palette now, so this no longer re-themes
# anything — it just swaps the image and keeps ~/.cache/wallpaper pointed at it.
set -euo pipefail

REPO="${NIX_CONFIG_REPO:-$HOME/nix-config}"

# Wallpaper to apply: explicit arg wins; otherwise restore the last-chosen one
# (~/.cache/wallpaper, written below on every change) so a reboot keeps your pick;
# fall back to the default only on a fresh machine that has never set one.
if [ -n "${1:-}" ]; then
  WALL="$1"
elif [ -e "$HOME/.cache/wallpaper" ]; then
  WALL="$(readlink -f "$HOME/.cache/wallpaper")"
else
  WALL="$REPO/wallpapers/lain.jpg"
fi

[ -f "$WALL" ] || { echo "no such wallpaper: $WALL" >&2; exit 1; }

if ! awww query >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  until awww query >/dev/null 2>&1; do sleep 0.1; done
fi

# Swap with a soft growing-circle reveal (the "animation"). --resize crop keeps
# the image filling the screen; the transition only plays when the image changes,
# so the login set-up is effectively instant. Tune type/duration to taste
# (types: fade | grow | center | wipe | wave | left/right/top/bottom | any).
awww img "$WALL" --resize crop \
  --transition-type center \
  --transition-duration 1.1 \
  --transition-fps 60 \
  --transition-bezier 0.22,1,0.36,1

# Keep a stable path for hyprlock's background so the lockscreen always matches
# the live desktop wallpaper (hyprlock reads ~/.cache/wallpaper).
mkdir -p "$HOME/.cache"
ln -sf "$WALL" "$HOME/.cache/wallpaper"
