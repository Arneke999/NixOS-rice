#!/usr/bin/env bash
# Force a fresh Wi-Fi scan, then refresh the popup list (bound to the rescan button).
d="$(dirname "$0")"
nmcli dev wifi rescan >/dev/null 2>&1 || true   # rate-limited by NM; that's fine
sleep 2                                          # let results populate
eww update wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true
