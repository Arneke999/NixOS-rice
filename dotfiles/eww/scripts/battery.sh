#!/usr/bin/env bash
# Battery state as JSON; present=false when no BAT device (desktop/VM).
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
if [ -z "$bat" ]; then
  echo '{"present":false,"capacity":0,"status":"none"}'
  exit 0
fi
cap=$(<"$bat/capacity"); cap=${cap:-0}
st=$(<"$bat/status");  st=${st:-Unknown}
printf '{"present":true,"capacity":%s,"status":"%s"}\n' "$cap" "$st"
