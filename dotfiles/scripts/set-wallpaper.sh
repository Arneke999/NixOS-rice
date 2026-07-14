#!/usr/bin/env bash
# Set wallpaper (awww) -> regenerate palette (matugen) -> reload. Arg: wallpaper path.
set -euo pipefail

REPO="${NIX_CONFIG_REPO:-$HOME/nix-config}"
WALL="${1:-$REPO/wallpapers/lain.jpg}"

[ -f "$WALL" ] || { echo "no such wallpaper: $WALL" >&2; exit 1; }

if ! awww query >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  until awww query >/dev/null 2>&1; do sleep 0.1; done
fi

awww img "$WALL" --resize crop
matugen image "$WALL" --prefer saturation --mode dark -c "$REPO/dotfiles/matugen/config.toml"

# Keep a stable path for hyprlock's background so the lockscreen always matches
# the live desktop wallpaper (hyprlock reads ~/.cache/wallpaper).
mkdir -p "$HOME/.cache"
ln -sf "$WALL" "$HOME/.cache/wallpaper"

eww reload >/dev/null 2>&1 || true
swaync-client --reload-css >/dev/null 2>&1 || true
# kitty reloads config on SIGUSR1. Match both the plain name (Arch) and the
# NixOS wrapper name (.kitty-wrapped). kitty also auto-watches its config, so
# this is mostly belt-and-suspenders.
pkill -USR1 -x '\.?kitty(-wrapped)?' >/dev/null 2>&1 || true
