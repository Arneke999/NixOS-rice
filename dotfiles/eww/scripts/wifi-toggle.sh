#!/usr/bin/env bash
# Toggle the Wi-Fi radio with INSTANT visual feedback.
#
# The button used to only flip after `nmcli radio` + a full re-read (and, when
# enabling, a 2s foreground scan) finished — so it felt laggy. Now we update the UI
# optimistically the moment the click lands, issue the radio change, then reconcile
# with the real state. When enabling, the scan that fills the network list runs in
# the BACKGROUND so the click returns immediately (list + spinner settle a moment
# later). wifi_scanning is only ever set true right before a scan we also reset.
set -uo pipefail
d="$(dirname "$0")"

if [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ]; then
  # → OFF: flip the UI now, then actually disable and reconcile.
  eww update wifi='{"enabled":false,"ssid":"","signal":0}' wifi_nets='[]' wifi_scanning=false >/dev/null 2>&1 || true
  nmcli radio wifi off >/dev/null 2>&1 || true
  eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" >/dev/null 2>&1 || true
else
  # → ON: show "on" + spinner now, enable, then scan+fill the list in the background.
  eww update wifi='{"enabled":true,"ssid":"","signal":0}' wifi_scanning=true >/dev/null 2>&1 || true
  nmcli radio wifi on >/dev/null 2>&1 || true
  eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" >/dev/null 2>&1 || true
  setsid -f bash -c '
    d="$1"
    trap "eww update wifi_scanning=false >/dev/null 2>&1 || true" EXIT
    nmcli dev wifi rescan >/dev/null 2>&1 || true
    sleep 2
    eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" \
               wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true
  ' _ "$d" >/dev/null 2>&1 || true
fi
