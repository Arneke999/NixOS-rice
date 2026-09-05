#!/usr/bin/env bash
# Force a fresh Wi-Fi scan, then refresh the popup list (bound to the rescan button).
# Flips wifi_scanning around the scan so the button shows a "scanning…" spinner.
#
# Runs DETACHED (setsid) with a trap that clears the spinner on any exit — otherwise
# eww tearing down the onclick child mid-scan (popup closed, button re-clicked) left
# wifi_scanning stuck `true` and the button looked permanently stuck.
d="$(dirname "$0")"
setsid -f bash -c '
  d="$1"
  trap "eww update wifi_scanning=false >/dev/null 2>&1 || true" EXIT
  eww update wifi_scanning=true >/dev/null 2>&1 || true
  nmcli dev wifi rescan >/dev/null 2>&1 || true   # rate-limited by NM; that'\''s fine
  sleep 2                                          # let results populate
  eww update wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true
' _ "$d" >/dev/null 2>&1 || true
