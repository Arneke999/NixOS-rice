#!/usr/bin/env bash
# eww `mpris` deflisten: emits one JSON line describing the active MPRIS player on
# every play/pause or track change. Downloads + caches album art locally (GTK can't
# load http art URLs directly). Requires playerctl (added to home.nix); until that's
# installed it emits a stable "no player" state so the widget just stays hidden.
set -uo pipefail
d="$(dirname "$0")"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/eww"; mkdir -p "$cache"
artfile="$cache/art"; lasturl=""

none='{"present":false,"status":"","title":"","artist":"","album":"","art":"","len":0,"lenstr":"0:00"}'

# Pre-rebuild (no playerctl yet): stay quiet, don't respawn-loop.
command -v playerctl >/dev/null 2>&1 || { echo "$none"; exec sleep infinity; }

fetch_art() { # $1=artUrl -> prints a local path eww can load ("" if none)
  local url="$1"
  case "$url" in
    file://*) printf '%s' "${url#file://}" ;;
    http://*|https://*)
      if [ "$url" != "$lasturl" ]; then
        curl -s --max-time 8 "$url" -o "$artfile" 2>/dev/null && lasturl="$url"
      fi
      [ -f "$artfile" ] && printf '%s' "$artfile" || printf '' ;;
    *) printf '' ;;
  esac
}

emit() {
  # Show the player the controls act on (see media-target.sh), not just the first one.
  local t P=(); t="$("$d/media-target.sh")"; [ -n "$t" ] && P=(-p "$t")
  playerctl "${P[@]}" status >/dev/null 2>&1 || { echo "$none"; return; }
  local status title artist album arturl art len
  status=$(playerctl "${P[@]}" status 2>/dev/null)
  title=$(playerctl "${P[@]}" metadata xesam:title 2>/dev/null)
  artist=$(playerctl "${P[@]}" metadata xesam:artist 2>/dev/null)
  album=$(playerctl "${P[@]}" metadata xesam:album 2>/dev/null)
  arturl=$(playerctl "${P[@]}" metadata mpris:artUrl 2>/dev/null)
  len=$(playerctl "${P[@]}" metadata mpris:length 2>/dev/null); len=$(( ${len:-0} / 1000000 ))  # µs → s
  local lenstr; lenstr="$(printf '%d:%02d' "$((len/60))" "$((len%60))")"
  art=$(fetch_art "$arturl")
  jq -cn --arg s "$status" --arg t "$title" --arg a "$artist" --arg al "$album" \
         --arg art "$art" --argjson len "${len:-0}" --arg lenstr "$lenstr" \
    '{present:true,status:$s,title:$t,artist:$a,album:$al,art:$art,len:$len,lenstr:$lenstr}'
}

emit
# Follow status + metadata changes (NOT position — that would churn every second;
# the seek position is polled separately in mpris-pos.sh).
playerctl -a -F -f '{{playerName}}{{status}}={{title}}' metadata 2>/dev/null | while IFS= read -r _; do
  emit
done
echo "$none"   # follow ended (last player quit) → settle; eww respawns us
