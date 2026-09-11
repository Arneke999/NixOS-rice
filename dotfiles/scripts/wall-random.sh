#!/usr/bin/env bash
# Random wallpaper (Super+Shift+W). Picks a random image from the repo wallpapers
# dir and applies it via set-wallpaper.sh (so it gets the grow reveal + hyprlock
# sync). Avoids re-picking the one already showing, so a press always visibly
# changes the wallpaper (unless there's only one image).
set -euo pipefail

REPO="${NIX_CONFIG_REPO:-$HOME/nix-config}"
DIR="$REPO/wallpapers"

note() { command -v notify-send >/dev/null 2>&1 && notify-send "wallpaper" "$1" || echo "$1" >&2; }
[ -d "$DIR" ] || { note "no wallpapers dir: $DIR"; exit 1; }

# What's showing now (resolve the symlink), so we can exclude it from the draw.
current=""
[ -e "$HOME/.cache/wallpaper" ] && current="$(readlink -f "$HOME/.cache/wallpaper")"

# All image files in the dir (same set the picker offers).
mapfile -d '' -t files < <(find "$DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)

[ "${#files[@]}" -gt 0 ] || { note "no images in $DIR"; exit 1; }

# Drop the current wallpaper from the candidates — but only if that leaves at
# least one, so a single-image dir still works.
pool=()
for f in "${files[@]}"; do
  [ "$(readlink -f "$f")" = "$current" ] && continue
  pool+=("$f")
done
[ "${#pool[@]}" -gt 0 ] || pool=("${files[@]}")

sel="$(printf '%s\0' "${pool[@]}" | shuf -z -n1 | tr -d '\0')"
exec "$REPO/dotfiles/scripts/set-wallpaper.sh" "$sel"
