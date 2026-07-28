#!/usr/bin/env bash
# Connect to a Wi-Fi network chosen in the popup. Args: SSID [secure(true/false)].
#   saved profile exists → bring it up · open network → connect directly ·
#   secured & no profile  → close the popup, prompt for the password in a themed
#                           fuzzel (--password), then connect.
# Refreshes the wifi widgets and notifies the result.
set -uo pipefail
ssid="${1:-}"; secure="${2:-false}"
[ -z "$ssid" ] && exit 0
d="$(dirname "$0")"
CFG="$HOME/nix-config/dotfiles/fuzzel/picker.ini"

note()    { command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "$1"; }
refresh() { eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true; }

# Already have a saved connection for this SSID? Just activate it.
if nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$ssid"; then
  nmcli connection up id "$ssid" >/dev/null 2>&1 && note "Connected to $ssid" || note "Couldn't connect to $ssid"
  refresh; exit 0
fi

if [ "$secure" = true ]; then
  "$d/pop.sh" close                                    # move the dropdown out of the way
  args=(--dmenu --password --prompt "󰌾 $ssid  ")
  [ -f "$CFG" ] && args+=(--config "$CFG")
  pw="$(printf '' | fuzzel "${args[@]}")" || exit 0    # cancelled
  [ -z "$pw" ] && exit 0
  if nmcli dev wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
    note "Connected to $ssid"
  else
    note "Wrong password or couldn't connect: $ssid"
  fi
else
  nmcli dev wifi connect "$ssid" >/dev/null 2>&1 && note "Connected to $ssid" || note "Couldn't connect to $ssid"
fi
refresh
