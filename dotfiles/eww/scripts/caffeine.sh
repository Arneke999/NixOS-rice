#!/usr/bin/env bash
# Caffeine (idle inhibitor) toggle for the bar. "On" = keep the screen awake by
# stopping hypridle (whose only action is dpms-off after 6 min); "off" = normal idle.
#   caffeine.sh          → print state: "true" = caffeinated (hypridle stopped)
#   caffeine.sh toggle   → flip it, push the new state to eww, print it
state() { pgrep -x hypridle >/dev/null 2>&1 && echo false || echo true; }

case "${1:-status}" in
  toggle)
    # Optimistic: flip the icon to the INTENDED state immediately, then do the work.
    # (Re-checking after a short sleep was the lag: relaunched hypridle takes >0.2s to
    # reappear in pgrep, so turning caffeine OFF wrongly read as still-on until the 3s
    # poll. The poll still reconciles if the action somehow fails.)
    if pgrep -x hypridle >/dev/null 2>&1; then
      eww update caffeine=true  >/dev/null 2>&1 || true   # → caffeinated
      pkill -x hypridle 2>/dev/null || true
    else
      eww update caffeine=false >/dev/null 2>&1 || true   # → normal idle
      setsid -f hypridle >/dev/null 2>&1 || true
    fi ;;
  *) state ;;
esac
