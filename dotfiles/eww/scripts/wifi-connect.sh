#!/usr/bin/env bash
# Connect to a Wi-Fi network chosen in the popup. Args: SSID [secure(true/false)].
#   saved profile  → bring it up; if that fails on a secured net (e.g. a stale/wrong
#                    saved password) forget the profile and fall through to re-prompt,
#                    instead of failing forever.
#   open network   → connect directly.
#   secured, none  → close the popup, prompt for the password in a themed fuzzel
#                    (--password), then connect. On failure the half-created profile
#                    is deleted so the next attempt re-prompts cleanly.
#
# ── WHY THIS DETACHES (the bug that survived 4 "fixes") ──────────────────────
# eww runs this as the onclick CHILD of the network button. The password flow
# closes the popup (pop.sh close) and later rebuilds the network list (refresh) —
# BOTH destroy the widget/window that owns this child, and eww then kills the
# onclick child's process group. So the script died the instant it closed the
# popup: fuzzel was orphaned and the nmcli connect after it never ran. Every past
# fix edited code that only runs AFTER that death, so nothing changed.
# Fix: re-exec ourselves DETACHED (setsid, new session/process group) so eww's
# child-kill can't reach us. Same pattern already used by wifi-rescan/wifi-toggle.
set -uo pipefail

ssid="${1:-}"; secure="${2:-false}"
[ -z "$ssid" ] && exit 0

# Re-exec detached on first entry. `setsid` puts us in a fresh session so we
# survive the popup closing and the list rebuilding; the onclick returns at once.
if [ "${WIFI_CONNECT_DETACHED:-}" != 1 ]; then
  setsid -f env WIFI_CONNECT_DETACHED=1 "$0" "$ssid" "$secure" >/dev/null 2>&1 || true
  exit 0
fi

d="$(dirname "$0")"
CFG="$HOME/nix-config/dotfiles/fuzzel/picker.ini"

note()    { command -v notify-send >/dev/null 2>&1 && notify-send -a "Wi-Fi" "$@"; }
refresh() { eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true; }
clean()   { sed -e 's/^Error: //' -e 's/[[:space:]]*$//' -e 's/\.$//' <<<"$1"; }  # tidy nmcli text for a toast
forget()  { nmcli connection delete "$ssid" >/dev/null 2>&1 || true; }            # drop a bad profile so retry re-prompts

# Prompt for a password in a themed fuzzel; echoes the password ("" if cancelled).
# --password masks input; dmenu mode allows the typed (custom) entry through on Enter.
prompt_pw() {
  "$d/pop.sh" close
  local args=(--dmenu --password --prompt "󰌾 $ssid  ")
  [ -f "$CFG" ] && args+=(--config "$CFG")
  fuzzel "${args[@]}" </dev/null
}

# 1) Saved profile → just bring it up.
if nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$ssid"; then
  if nmcli --wait 25 connection up id "$ssid" >/dev/null 2>&1; then
    refresh; exit 0                        # success toast comes from conn-notify.sh
  fi
  if [ "$secure" = true ]; then
    forget                                 # stale/wrong saved password → re-prompt below
  else
    note "Couldn't connect to $ssid"; refresh; exit 0
  fi
fi

# 2) No usable profile.
if [ "$secure" = true ]; then
  pw="$(prompt_pw)" || exit 0             # cancelled
  [ -z "$pw" ] && exit 0
  if err="$(nmcli --wait 25 dev wifi connect "$ssid" password "$pw" 2>&1 >/dev/null)"; then
    :                                      # success toast comes from conn-notify.sh
  else
    forget                                 # remove the failed profile so a retry re-prompts
    note "Couldn't connect to $ssid" "$(clean "$err")"
  fi
else
  if err="$(nmcli --wait 25 dev wifi connect "$ssid" 2>&1 >/dev/null)"; then
    :
  else
    note "Couldn't connect to $ssid" "$(clean "$err")"
  fi
fi
refresh
