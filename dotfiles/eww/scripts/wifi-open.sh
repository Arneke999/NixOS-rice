#!/usr/bin/env bash
# Refresh the (cached) network list, then toggle the Wi-Fi popup — mirrors bt-open.sh.
d="$(dirname "$0")"
eww update wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true
"$d/pop.sh" pop-wifi
