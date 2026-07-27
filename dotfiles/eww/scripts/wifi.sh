#!/usr/bin/env bash
# Wi-Fi state as JSON for the popup: {"enabled":bool,"ssid":"..","signal":N}.
en=false
[ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ] && en=true
ssid=""; sig=0
if [ "$en" = true ]; then
  line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print; exit}')
  ssid=$(cut -d: -f2 <<<"$line")
  sig=$(cut -d: -f3 <<<"$line")
fi
ssid=${ssid//\"/}; ssid=${ssid//\\/}
printf '{"enabled":%s,"ssid":"%s","signal":%s}\n' "$en" "$ssid" "${sig:-0}"
