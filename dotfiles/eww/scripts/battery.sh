#!/usr/bin/env bash
# Battery state as JSON; present=false when no BAT device (desktop/VM).
# Detects AC/mains so a plugged-in-but-"Not charging" laptop reads as "plugged in"
# instead of the confusing raw "Not charging". "icon" is a level-appropriate Nerd
# Font glyph (10 steps + charging bolt + low-alert) so the bar reflects real charge.
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
if [ -z "$bat" ]; then
  echo '{"present":false,"capacity":0,"status":"none","charging":false,"plugged":false,"icon":"󰂑"}'
  exit 0
fi
cap=$(<"$bat/capacity"); cap=${cap:-0}
st=$(<"$bat/status");    st=${st:-Unknown}

# AC / mains online? Battery's own supply has no "online" node; only AC adapters do.
ac=0
for f in /sys/class/power_supply/*/online; do
  [ -r "$f" ] || continue
  if [ "$(<"$f")" = "1" ]; then ac=1; break; fi
done

charging=false; plugged=false
[ "$st" = "Charging" ] && charging=true
{ [ "$ac" = "1" ] || [ "$st" = "Charging" ] || [ "$st" = "Full" ]; } && plugged=true

# Friendlier status text for the tooltip.
case "$st" in
  Charging)               status="charging" ;;
  Full)                   status="charged" ;;
  Discharging)            status="on battery" ;;
  "Not charging"|Unknown) [ "$ac" = "1" ] && status="plugged in" || status="$st" ;;
  *)                      status="$st" ;;
esac

# 0,10,…,100% discharging glyphs.
levels=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
idx=$(( (cap + 5) / 10 )); (( idx < 0 )) && idx=0; (( idx > 10 )) && idx=10
if [ "$charging" = true ] || [ "$plugged" = true ]; then
  icon="󰂄"                 # on AC (charging or full/not-charging): show the bolt
elif [ "$cap" -le 15 ]; then
  icon="󰂃"                 # low-battery alert
else
  icon="${levels[$idx]}"
fi

printf '{"present":true,"capacity":%s,"status":"%s","charging":%s,"plugged":%s,"icon":"%s"}\n' \
  "$cap" "$status" "$charging" "$plugged" "$icon"
