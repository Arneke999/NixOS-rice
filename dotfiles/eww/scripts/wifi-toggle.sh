#!/usr/bin/env bash
# Toggle the Wi-Fi radio, then refresh the eww widgets that depend on it.
if [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ]; then
  nmcli radio wifi off
else
  nmcli radio wifi on
fi
d="$(dirname "$0")"
eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" >/dev/null 2>&1 || true
