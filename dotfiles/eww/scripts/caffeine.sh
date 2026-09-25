#!/usr/bin/env bash
# Caffeine (keep-awake) toggle for the bar.
#   caffeine.sh          → print state: "true" = caffeinated
#   caffeine.sh toggle   → flip it, push the new state to eww
#
# Holds a systemd *idle* inhibitor instead of killing hypridle. hypridle honours it
# (tested: it logs "systemd idle inhibit active" and its idle timer stops firing), and
# because hypridle keeps RUNNING, its before_sleep_cmd still locks the screen when the
# lid closes. The old version killed hypridle outright — so closing the lid while
# caffeinated suspended, and resumed, UNLOCKED. An idle inhibitor doesn't block
# suspend itself, so lid-close still sleeps (and locks) as normal.
who=eww-caffeine
holder() { systemd-inhibit --list --no-legend --no-pager 2>/dev/null | awk -v w="$who" '$1==w{print $4; exit}'; }
state()  { [ -n "$(holder)" ] && echo true || echo false; }

case "${1:-status}" in
  toggle)
    pid="$(holder)"
    if [ -n "$pid" ]; then
      eww update caffeine=false >/dev/null 2>&1 || true          # optimistic: flip icon now
      kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null     # whole group (inhibitor + its sleep)
    else
      eww update caffeine=true >/dev/null 2>&1 || true
      setsid -f systemd-inhibit --what=idle --who="$who" --why="Caffeine (eww bar)" \
        sleep infinity >/dev/null 2>&1
    fi
    # Older caffeine versions killed hypridle; make sure it's back (it owns lock-on-suspend).
    pgrep -x hypridle >/dev/null 2>&1 || setsid -f hypridle >/dev/null 2>&1
    ;;
  *) state ;;
esac
