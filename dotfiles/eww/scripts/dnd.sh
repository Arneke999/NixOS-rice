#!/usr/bin/env bash
# Do-Not-Disturb toggle (swaync). "On" silences notifications.
#   dnd.sh          → print state ("true"/"false")
#   dnd.sh toggle   → flip via swaync, push new state to eww, print it
command -v swaync-client >/dev/null 2>&1 || { echo false; exit 0; }
case "${1:-status}" in
  toggle) s="$(swaync-client -d 2>/dev/null)"; eww update dnd="$s" >/dev/null 2>&1 || true; echo "${s:-false}" ;;
  *)      swaync-client -D 2>/dev/null || echo false ;;
esac
