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

eww reload >/dev/null 2>&1 || true
makoctl reload >/dev/null 2>&1 || true
