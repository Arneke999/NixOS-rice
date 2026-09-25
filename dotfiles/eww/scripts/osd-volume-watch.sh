#!/usr/bin/env bash
# Pop the volume OSD on ANY change to the default output's volume or mute: keyboard keys,
# bar scroll, AirPods/headset buttons (absolute volume over AVRCP), or an app/mixer.
# Event-driven via `pactl subscribe` against PipeWire's pulse server, so it's idle until
# something actually changes. Autostarted via hyprland exec-once.
set -uo pipefail
d="$HOME/nix-config/dotfiles/eww/scripts"
command -v pactl >/dev/null 2>&1 || exit 0          # needs the pulseaudio client tools

# Single instance: a new start (next login's exec-once) replaces the old one.
PIDF="$HOME/.cache/hypr/osd-volume-watch.pid"; mkdir -p "$(dirname "$PIDF")"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
  kill -- -"$(cat "$PIDF")" 2>/dev/null || kill "$(cat "$PIDF")" 2>/dev/null || true
fi
echo $$ > "$PIDF"

vol() { wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null; }   # e.g. "Volume: 0.45 [MUTED]"
last="$(vol)"
while :; do
  # 'change' on sink = volume/mute; on server = default output switched. Only pop when
  # the value really changed (sink events also fire for unrelated property updates).
  pactl subscribe 2>/dev/null | grep --line-buffered -E "'change' on (sink|server) #" |
  while read -r _; do
    now="$(vol)"; [ "$now" = "$last" ] && continue
    last="$now"; "$d/osd.sh" vol
  done
  sleep 2                                            # pulse server restarted: resubscribe
done
