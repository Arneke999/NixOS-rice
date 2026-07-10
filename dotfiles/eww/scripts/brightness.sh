#!/usr/bin/env bash
# Backlight brightness as JSON; present=false when no backlight (desktop/VM).
if ! command -v brightnessctl >/dev/null || [ -z "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
  echo '{"present":false,"value":0}'
  exit 0
fi
cur=$(brightnessctl get 2>/dev/null)
max=$(brightnessctl max 2>/dev/null)
val=0
[ -n "$max" ] && [ "$max" -gt 0 ] 2>/dev/null && val=$(( cur * 100 / max ))
printf '{"present":true,"value":%s}\n' "$val"
