#!/usr/bin/env bash
# Wallpaper picker (Super+W). A fuzzel list of the repo wallpapers, each row showing
# a small thumbnail, applied (with an awww transition) via set-wallpaper.sh — which
# also re-themes everything via matugen. Uses a dedicated fuzzel config (picker.ini)
# with icons ON; the Alt+Space launcher's fuzzel.ini keeps icons off.
#
# NOTE: bash strings can't hold NUL bytes, so the dmenu feed (which needs
# "TEXT\0icon\x1fICON\n" per row) is printed straight into fuzzel from a subshell
# loop rather than built up in a variable.
set -euo pipefail

REPO="${NIX_CONFIG_REPO:-$HOME/nix-config}"
DIR="$REPO/wallpapers"
CFG="$REPO/dotfiles/fuzzel/picker.ini"
THUMBS="${XDG_CACHE_HOME:-$HOME/.cache}/wall-thumbs"

note() { command -v notify-send >/dev/null 2>&1 && notify-send "wallpaper" "$1" || echo "$1" >&2; }
[ -d "$DIR" ] || { note "no wallpapers dir: $DIR"; exit 1; }
mkdir -p "$THUMBS"

# Thumbnailer: ImageMagick 7 (magick) or 6 (convert); degrade to the full image as
# the icon if neither is present.
if   command -v magick  >/dev/null 2>&1; then MAGICK=(magick)
elif command -v convert >/dev/null 2>&1; then MAGICK=(convert)
else MAGICK=(); fi

# name -> full path, sorted, image files only.
declare -A MAP
names=()
while IFS= read -r -d '' f; do
  name="$(basename "$f")"
  MAP["$name"]="$f"
  names+=("$name")
done < <(find "$DIR" -maxdepth 1 -type f \
           \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
           -print0 | sort -z)

[ "${#names[@]}" -gt 0 ] || { note "no images in $DIR"; exit 1; }

args=(--dmenu --prompt '󰸉  ')
[ -f "$CFG" ] && args+=(--config "$CFG")

# Generate/refresh thumbnails, emit the dmenu feed with per-row icons, pick one.
choice="$(
  for name in "${names[@]}"; do
    src="${MAP[$name]}"; icon="$src"
    if [ "${#MAGICK[@]}" -gt 0 ]; then
      thumb="$THUMBS/${name}.png"
      if [ ! -f "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        "${MAGICK[@]}" "$src" -thumbnail '200x120^' -gravity center -extent 200x120 "$thumb" 2>/dev/null || thumb="$src"
      fi
      icon="$thumb"
    fi
    printf '%s\0icon\x1f%s\n' "$name" "$icon"
  done | fuzzel "${args[@]}"
)" || exit 0
[ -n "${choice:-}" ] || exit 0

sel="${MAP[$choice]:-}"
[ -n "$sel" ] || { note "unknown: $choice"; exit 1; }
exec "$REPO/dotfiles/scripts/set-wallpaper.sh" "$sel"
