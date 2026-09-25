#!/usr/bin/env bash
# Low-battery warnings + a last-resort suspend, so the laptop never just dies mid-class
# (taking an unsaved R session with it). Autostarted via hyprland exec-once.
#
#   ≤ 20 %  → normal notification            "Battery low — N % (≈ time left)"
#   ≤ 10 %  → critical, stays on screen      "Battery critical — plug in"
#   ≤  5 %  → critical 60 s countdown, then `systemctl suspend` if still unplugged.
#             hypridle locks the screen before sleep. This machine has no swap, so
#             hibernate isn't possible; a suspended laptop sips power and buys hours.
#             If you wake it and stay unplugged at ≤ 5 %, it re-arms after 5 minutes —
#             enough time to save your work, but it won't let the battery run flat.
#
# Each warning fires once per discharge; plugging in re-arms them all. Polls every
# 30 s (a sysfs read — negligible).
#
# Test hooks (for checking thresholds without draining the battery):
#   BN_CAP=8 BN_STATUS=Discharging  fake the reading
#   BN_DRY=1                        don't really suspend; 1 s countdown instead of 60 s
#   BN_ONCE=1                       evaluate one pass and exit (no pidfile)
set -uo pipefail
d="$(dirname "$0")"
BAT="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)"
[ -n "$BAT" ] || exit 0                          # desktop / no battery: nothing to do

if [ -z "${BN_ONCE:-}" ]; then
  # Single instance: a new start (next login's exec-once) replaces the old one.
  PIDF="$HOME/.cache/hypr/battery-notify.pid"; mkdir -p "$(dirname "$PIDF")"
  if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
    kill "$(cat "$PIDF")" 2>/dev/null || true
  fi
  echo $$ > "$PIDF"
fi

note() { command -v notify-send >/dev/null 2>&1 && notify-send -a "Battery" "$@"; }
cap()    { echo "${BN_CAP:-$(cat "$BAT/capacity" 2>/dev/null || echo 100)}"; }
status() { echo "${BN_STATUS:-$(cat "$BAT/status" 2>/dev/null || echo Unknown)}"; }
left()   { "$HOME/nix-config/dotfiles/eww/scripts/battery.sh" 2>/dev/null \
             | sed -n 's/.*"time":"\([^"]*\)".*/\1/p'; }

warned=100        # lowest threshold already announced during this discharge
last_suspend=0    # when the 5-min grace period (after waking from our suspend) started
just_suspended=0  # set when we suspend; the next pass is the first one after waking

check() {
  local c s now t
  c="$(cap)"; s="$(status)"; now="$(date +%s)"
  if [ "$s" != "Discharging" ]; then
    warned=100; last_suspend=0; just_suspended=0   # on AC / charging / full → re-arm all
    return
  fi
  # First pass after a suspend WE triggered (still unplugged) = we just woke up. Start
  # the 5-minute grace period NOW: wall-clock time spent asleep must not count, or
  # waking the laptop at 4 % would re-suspend it within 30 s instead of giving you time.
  if [ "$just_suspended" = 1 ]; then just_suspended=0; last_suspend="$now"; return; fi
  if [ "$c" -le 5 ] && { [ "$warned" -gt 5 ] || [ $((now - last_suspend)) -ge 300 ]; }; then
    warned=5; last_suspend="$now"
    note -u critical -i battery-empty "Battery at ${c}% — suspending in 60 s" \
         "Plug in now to cancel. Save your work."
    if [ -n "${BN_DRY:-}" ]; then sleep 1; else sleep 60; fi
    if [ "$(status)" = "Discharging" ]; then
      if [ -n "${BN_DRY:-}" ]; then echo "DRY: would run systemctl suspend"
      else systemctl suspend; fi
      just_suspended=1
    fi
  elif [ "$c" -le 10 ] && [ "$warned" -gt 10 ]; then
    warned=10
    note -u critical -i battery-caution "Battery critical — ${c}%" \
         "Plug in soon. The laptop suspends itself at 5%."
  elif [ "$c" -le 20 ] && [ "$warned" -gt 20 ]; then
    warned=20; t="$(left)"
    note -u normal -i battery-low "Battery low — ${c}%" "${t:+About $t.}"
  fi
}

if [ -n "${BN_ONCE:-}" ]; then check; exit 0; fi
while :; do check; sleep 30; done
