#!/usr/bin/env bash
# Bluetooth state as JSON; present=false when no adapter / no bluez.
if ! command -v bluetoothctl >/dev/null; then
  echo '{"present":false,"powered":false,"connected":false}'
  exit 0
fi
show=$(timeout 2 bluetoothctl show 2>/dev/null)
if [ -z "$show" ]; then
  echo '{"present":false,"powered":false,"connected":false}'
  exit 0
fi
powered=$(awk '/Powered:/{print ($2=="yes")?"true":"false"; exit}' <<<"$show")
connected=$(timeout 2 bluetoothctl devices Connected 2>/dev/null | grep -q Device && echo true || echo false)
printf '{"present":true,"powered":%s,"connected":%s}\n' "${powered:-false}" "$connected"
