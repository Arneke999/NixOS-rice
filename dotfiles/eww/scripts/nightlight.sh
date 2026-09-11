#!/usr/bin/env bash
# Night-light toggle via Hyprland's screen shader (decoration:screen_shader).
#   nightlight.sh          → print state ("true"/"false")
#   nightlight.sh toggle   → flip, push new state to eww, print it
#
# Uses a compositor render-pipeline shader instead of gamma control, so it works even
# where the GPU/output has no gamma-adjustment support — e.g. this virtio-gpu VM,
# where gammastep/wlsunset/hyprsunset are all silent no-ops. Runtime-only (hyprctl
# keyword), so it resets to off on a Hyprland restart — fine for a toggle.
shader="$HOME/nix-config/dotfiles/hypr/nightlight.frag"

state() {
  local cur
  cur="$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | jq -r '.str' 2>/dev/null)"
  [ "$cur" = "$shader" ] && echo true || echo false
}

case "${1:-status}" in
  toggle)
    command -v hyprctl >/dev/null 2>&1 || { echo false; exit 0; }
    if [ "$(state)" = true ]; then
      hyprctl keyword decoration:screen_shader "[[EMPTY]]" >/dev/null 2>&1 || true
    else
      hyprctl keyword decoration:screen_shader "$shader" >/dev/null 2>&1 || true
    fi
    s="$(state)"; eww update nightlight="$s" >/dev/null 2>&1 || true; echo "$s" ;;
  *) state ;;
esac
